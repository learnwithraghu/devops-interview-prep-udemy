# Debugging Guide: Ingress Misconfiguration

## Quick Start Checklist

- [ ] Cluster running on EC2: `kubectl get nodes`
- [ ] Ingress controller running: `kubectl get pods -n ingress-nginx`
- [ ] Image built: `docker images | grep k8s-debug-app`
- [ ] Manifest deployed: `kubectl apply -f deployment.yaml`
- [ ] Ready to debug: Ingress returns 404 or 502

---

## Step 1: Observe the Broken State

### Deploy the broken version:
```bash
cd section-03-networking-storage-security/11-ingress-path-host-tls-misconfig
kubectl apply -f deployment.yaml
```

### Verify the application Pod is healthy:
```bash
kubectl get pods
```

**Expected output:**
```
NAME                            READY   STATUS    RESTARTS   AGE
ingress-demo-xxxxx              1/1     Running   0          15s
```

The Pod is Running. The problem is not at the Pod level.

### Test access through the Ingress (from the EC2 instance):
```bash
curl -k -H "Host: app.demo.local" https://localhost/
```

The `-H "Host: app.demo.local"` header tells the Ingress controller which host rule to match. No `/etc/hosts` entry is needed — you are simulating the Host header that DNS would normally provide.

**Expected output:**
```
404 Not Found
```

Or you may see a `502 Bad Gateway`. Either way, the Ingress is not routing traffic correctly.

---

## Step 2: Inspect the Ingress

### List Ingress resources:
```bash
kubectl get ingress
```

**Expected output:**
```
NAME           CLASS     HOSTS             ADDRESS   PORTS     AGE
ingress-demo   nginx     app.demo.local              80, 443   30s
```

The Ingress exists and lists the correct host. The `ADDRESS` column may be empty briefly on some clusters — that is normal while the controller assigns an address.

### Describe the Ingress:
```bash
kubectl describe ingress ingress-demo
```

**Expected output (key sections):**

Under `Rules:`:
```
  Host         Path  Backends
  ----         ----  --------
  app.demo.local
               /api   ingress-demo:80 (<error: endpoints not found>)
```

Under `TLS:`:
```
  app.demo.local   demo-tls terminates
```

This gives us three clues:
- The path is `/api`, not `/`
- The backend port is `80`
- The TLS secret is named `demo-tls`

The `<error: endpoints not found>` on port 80 is a strong hint that the backend port is wrong.

---

## Step 3: Verify the Backend Service Has Endpoints

Before changing the Ingress, confirm the application itself is reachable.

### Check Service Endpoints:
```bash
kubectl get endpoints ingress-demo
```

**Expected output:**
```
NAME           ENDPOINTS          AGE
ingress-demo   10.244.0.5:8080    30s
```

The Service **does** have endpoints — on port **8080**. The application is healthy and reachable inside the cluster.

### Describe the Service:
```bash
kubectl describe svc ingress-demo
```

**Expected output (Ports section):**
```
Port:              8080/TCP
TargetPort:        8080/TCP
Endpoints:         10.244.0.5:8080
```

The Service listens on port 8080, but the Ingress backend references port 80. That is the **port mismatch**.

### Confirm internal access works:
```bash
kubectl run debug --rm -it --image=busybox --restart=Never -- wget -O- http://ingress-demo:8080
```

**Expected output:**
```
Connecting to ingress-demo:8080 (10.96.x.x:8080)
...
HTTP/1.1 200 OK
```

The app works fine via the Service directly. The problem is isolated to the Ingress configuration.

---

## Step 4: Verify the TLS Secret

### List Secrets:
```bash
kubectl get secrets
```

**Expected output:**
```
NAME               TYPE                DATA   AGE
ingress-demo-tls   kubernetes.io/tls   2      30s
```

The TLS Secret exists, but it is named `ingress-demo-tls`.

### Describe the Ingress TLS reference again:
```bash
kubectl describe ingress ingress-demo
```

Look at the TLS section:
```
  app.demo.local   demo-tls terminates
```

The Ingress references `demo-tls`, but the actual Secret is named `ingress-demo-tls`. That is the **TLS secret name mismatch**.

### Verify the Secret contents:
```bash
kubectl get secret ingress-demo-tls -o yaml
```

**Expected output (metadata section):**
```yaml
metadata:
  name: ingress-demo-tls
type: kubernetes.io/tls
data:
  tls.crt: ...
  tls.key: ...
```

The Secret is valid and contains both `tls.crt` and `tls.key`. The Ingress just points to the wrong name.

---

## Step 5: Read Ingress Controller Logs

### Find the Ingress controller Pod (Nginx Ingress on EC2/kind):
```bash
kubectl get pods -n ingress-nginx
```

**Expected output:**
```
NAME                                        READY   STATUS    RESTARTS   AGE
ingress-nginx-controller-xxxxx              1/1     Running   0          5m
```

### Read controller logs:
```bash
kubectl logs -n ingress-nginx ingress-nginx-controller-xxxxx
```

Copy the controller pod name from the previous step.

**Expected output (look for lines referencing ingress-demo):**
```
... Secret "demo-tls" not found ...
... Service "default/ingress-demo" does not have any active Endpoint for port 80 ...
```

The controller logs confirm:
- Port 80 does not exist on the backend Service
- The TLS Secret `demo-tls` cannot be found

---

## Root Cause Analysis

By now you've correlated four resources:

| Resource | Status | Issue |
|----------|--------|-------|
| Pod | Running | None |
| Service Endpoints | `10.244.0.5:8080` | None — backend is healthy |
| TLS Secret | `ingress-demo-tls` exists | Ingress references wrong name `demo-tls` |
| Ingress | Deployed | Wrong path `/api`, wrong port `80`, wrong secret `demo-tls` |

**What happens:**
1. A request arrives with the `Host: app.demo.local` header
2. Nginx Ingress matches the host `app.demo.local` correctly
3. The path `/` does not match the Ingress rule `/api` → 404
4. Even if the path matched, the backend port `80` has no Endpoints → 502
5. TLS termination fails because Secret `demo-tls` does not exist

All three Ingress issues must be fixed.

---

## The Fix: Correct the Ingress Manifest

### Edit deployment.yaml:
```bash
vim deployment.yaml
```

1. Search for the Ingress section: `/kind: Ingress`
2. Navigate to the TLS secretName line:
   ```yaml
       secretName: demo-tls          # <-- EDIT THIS LINE: change to ingress-demo-tls
   ```
3. Navigate to the path line:
   ```yaml
           - path: /api               # <-- EDIT THIS LINE: change to /
   ```
4. Navigate to the backend port line:
   ```yaml
                   number: 80        # <-- EDIT THIS LINE: change to 8080
   ```
5. Press `i` to enter insert mode and make all three changes
6. Press `Esc` then save: `:wq`

Verify the Ingress section now looks like this:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-demo
  labels:
    app: ingress-demo
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - app.demo.local
      secretName: ingress-demo-tls
  rules:
    - host: app.demo.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ingress-demo
                port:
                  number: 8080
```

---

## Step 6: Apply and Verify

### Apply the fixed manifest:
```bash
kubectl apply -f deployment.yaml
```

### Confirm the Ingress backend is healthy:
```bash
kubectl describe ingress ingress-demo
```

**Expected output (Rules section):**
```
  Host         Path  Backends
  ----         ----  --------
  app.demo.local
               /   ingress-demo:8080 (10.244.0.5:8080)
```

No more `<error: endpoints not found>`.

### Test HTTPS access (from the EC2 instance):
```bash
curl -k -H "Host: app.demo.local" https://localhost/
```

**Expected output:**
```
HTTP response body from the debug app (200 OK)
```

### Confirm the HTTP status code:
```bash
curl -k -H "Host: app.demo.local" -o /dev/null -s -w "%{http_code}\n" https://localhost/
```

**Expected output:**
```
200
```

Success! Traffic flows from the Ingress through the Service to the Pod.

---

## Instructor Talking Points

### 1. Ingress Is a Separate Layer
"The Pod and Service can be perfectly healthy while the Ingress is completely broken. Always verify Endpoints on the backend Service first. If Endpoints exist, the problem is in the Ingress rules, not the application. This saves you from debugging the wrong layer."

### 2. Three Common Ingress Mistakes
"In interviews and on-call, I see three Ingress bugs repeatedly:
- **Wrong path** — the rule says `/api` but users hit `/`
- **Wrong backend port** — the Service port is 8080 but the Ingress references 80
- **Wrong TLS secret name** — the Secret exists but under a different name

Each one produces a different symptom: 404 for path, 502 for port, and TLS warnings or certificate errors for secret mismatch."

### 3. describe ingress Shows Backend Health
"`kubectl describe ingress` is your best friend. The Backends column shows whether the Ingress can reach the Service Endpoints. If you see `<error: endpoints not found>`, compare the port number in the Ingress with `kubectl get endpoints`. They must match the Service port, not the containerPort directly."

### 4. TLS Secret Must Match Exactly
"The `secretName` in the Ingress `tls` block must exactly match an existing Secret of type `kubernetes.io/tls` in the same namespace. Kubernetes does not fuzzy-match or auto-discover certificates. If the name is wrong, TLS termination silently fails or the controller logs a 'secret not found' error."

### 5. Ingress Controller Logs Fill the Gaps
"When `describe ingress` doesn't explain the failure, the controller logs will. Nginx Ingress logs routing decisions, backend resolution failures, and certificate loading errors. On the EC2 kind cluster, the controller runs in the `ingress-nginx` namespace."

### 6. Path Types Matter
"This scenario uses `pathType: Prefix`. With Prefix, `/api` matches `/api` and `/api/v1` but not `/`. The other types are `Exact` (must match exactly) and `ImplementationSpecific` (depends on the controller). Always confirm the path type when debugging 404s."

---

## Cleanup

To remove all resources:
```bash
kubectl delete -f deployment.yaml
```

Or move on to the next scenario.
