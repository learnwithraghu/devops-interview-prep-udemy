# Debugging Guide: Service Discovery - Port & Label Mismatch

## Quick Start Checklist

- [ ] Cluster running: `kubectl get nodes`
- [ ] Image built: `docker images | grep k8s-debug-app`
- [ ] Deployment deployed: `kubectl get pods`
- [ ] Service deployed: `kubectl get svc`
- [ ] Ready to debug: Endpoints show `<none>` despite Pod running

---

## Step 1: Observe the Broken State

### Deploy the broken version:
```bash
kubectl apply -f deployment.yaml
```

### Check the Pod and Service:
```bash
kubectl get pods
kubectl get svc
```

**Expected output:**
```
NAME                       READY   STATUS    RESTARTS   AGE
svc-demo-xxxxx            1/1     Running   0          15s

NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
svc-demo     ClusterIP   10.96.123.45    <none>        80/TCP    15s
```

The Pod is Running, but we suspect the Service can't reach it.

---

## Step 2: Check the Service Endpoints

### List endpoints for the service:
```bash
kubectl get endpoints svc-demo
```

**Expected output:**
```
NAME       ENDPOINTS   AGE
svc-demo   <none>      30s
```

This is the first red flag: the Service has **zero endpoints**. A healthy Service with a matching Pod should show an IP address and port.

---

## Step 3: Inspect the Service Selector

### Describe the Service:
```bash
kubectl describe svc svc-demo
```

**Look for the Selector section:**
```
Selector:          app=web-app
```

**And the Ports section:**
```
Port:              80/TCP
TargetPort:        80/TCP
Endpoints:         <none>
```

Now we know the Service is looking for Pods with label `app=web-app` on port 80.

---

## Step 4: Inspect the Pod Labels

### Get the Pod labels:
```bash
kubectl get pods -l app=svc-demo --show-labels
```

**Expected output:**
```
NAME                       READY   STATUS    RESTARTS   AGE   LABELS
svc-demo-xxxxx            1/1     Running   0          1m    app=svc-demo,pod-template-hash=abcd1234
```

The Pod's label is `app=svc-demo`, but the Service selector is `app=web-app`. That's the **label mismatch**.

### Confirm the Pod is not selected by the Service's current selector:
```bash
kubectl get pods -l app=web-app
```

**Expected output:**
```
No resources found in default namespace.
```

---

## Root Cause Analysis (Part 1)

The Service selector `app=web-app` does not match any Pod labels. The actual Pod label is `app=svc-demo`. This is why Endpoints is `<none>`.

---

## Step 5: First Fix — Correct the Service Selector

### Edit the manifest:
```bash
vim deployment.yaml
```

1. Search for the Service selector: `/selector:` — press `n` until you reach the **Service** section (after `---`)
2. Find the line:
   ```yaml
     selector:
       app: web-app      # <-- EDIT THIS LINE: change to svc-demo
   ```
3. Press `i` to enter insert mode
4. Change `web-app` to `svc-demo`
5. Press `Esc` then save: `:wq`

### Apply the fix:
```bash
kubectl apply -f deployment.yaml
```

### Verify Endpoints again:
```bash
kubectl get endpoints svc-demo
```

**Expected output:**
```
NAME       ENDPOINTS           AGE
svc-demo   10.244.0.99:80     5s
```

Now the Service has an endpoint! But the curl test will still fail.

---

## Step 6: Test Connectivity from Inside the Cluster

### Run a temporary debug Pod and curl the Service:
```bash
kubectl run debug --rm -it --image=busybox -- wget -qO- http://svc-demo
```

**Expected output:**
```
wget: can't connect to remote host (10.96.123.45): Connection refused
```

The Service resolves to its ClusterIP, but the connection is refused. Why?

---

## Step 7: Inspect the Container Port

### Describe the Pod:
```bash
kubectl describe pod svc-demo-xxxxx
```

**Look for the Containers section:**
```
Containers:
  app:
    Port:          8080/TCP
```

The container is listening on **port 8080**, but the Service `targetPort` is **80**.

### Also verify by checking the Service description again:
```bash
kubectl describe svc svc-demo
```

**Ports section:**
```
Port:              80/TCP
TargetPort:        80/TCP
```

The Service forwards port 80 to the Pod's port 80. But the app is on 8080.

---

## Root Cause Analysis (Part 2)

There are **two separate bugs** in this manifest:
1. **Label mismatch:** Service selector `app=web-app` does not match Pod label `app=svc-demo`
2. **Port mismatch:** Service `targetPort: 80` does not match container `containerPort: 8080`

Even after fixing the labels, the port mismatch breaks traffic flow.

---

## Step 8: Second Fix — Correct the TargetPort

### Edit the manifest:
```bash
vim deployment.yaml
```

1. Search for targetPort: `/targetPort`
2. Find the line:
   ```yaml
       targetPort: 80    # <-- EDIT THIS LINE: change to 8080
   ```
3. Press `i` to enter insert mode
4. Change `80` to `8080`
5. Press `Esc` then save: `:wq`

### Apply the fix:
```bash
kubectl apply -f deployment.yaml
```

---

## Step 9: Verify the Full Fix

### Check Endpoints:
```bash
kubectl get endpoints svc-demo
```

**Expected output:**
```
NAME       ENDPOINTS              AGE
svc-demo   10.244.0.99:8080      10s
```

Notice the endpoint port is now **8080**.

### Test connectivity again:
```bash
kubectl run debug --rm -it --image=busybox -- wget -qO- http://svc-demo
```

**Expected output:**
```
Response code: 200
```

Success! The Service now routes traffic correctly to the Pod.

---

## Alternative: Fix Both Issues at Once

If you spotted both issues during initial inspection, you can fix them in a single edit:

```bash
vim deployment.yaml
```

1. Fix the Service selector: change `app: web-app` → `app: svc-demo`
2. Fix the Service targetPort: change `targetPort: 80` → `targetPort: 8080`
3. Save: `:wq`

```bash
kubectl apply -f deployment.yaml
```

Then verify with `get endpoints` and the wget test.

---

## Instructor Talking Points

### 1. How Service Discovery Works in Kubernetes
"A Kubernetes Service creates an EndpointSlice object that watches for Pods matching the Service's `selector`. The kube-proxy on each node then programs iptables or IPVS rules to forward traffic to those Pod IPs. If the selector doesn't match any Pods, the EndpointSlice is empty and there's nowhere to send traffic."

### 2. Labels Are the Glue
"Labels are the primary mechanism for loose coupling in Kubernetes. A Service doesn't know or care about Deployment names — it only cares about labels. This is powerful but fragile: a simple typo in a label name or value breaks the entire traffic path. Always verify `kubectl get pods --show-labels` against `kubectl describe svc` selectors."

### 3. Port vs. TargetPort
"`port` is what clients use to reach the Service. `targetPort` is what the Service uses to reach the container. They are decoupled by design — you can expose port 443 externally while the container listens on 8443. But if they don't align with the actual container port, traffic is silently dropped."

### 4. The Debug Pod Pattern
"When a Service isn't responding, always test from inside the cluster using a temporary Pod. This eliminates external networking variables (NodePort, Ingress, load balancers) and isolates the problem to either Service-to-Pod routing or the application itself. `kubectl run debug --rm -it --image=busybox -- wget ...` is my go-to one-liner for this."

### 5. Real-World Impact
"In production, label and port mismatches usually happen when:
- A manifest is copy-pasted from another service and labels aren't updated
- A chart template uses a variable for the label but it's not passed correctly
- A developer changes the app's listening port but forgets to update the Service
- CI/CD applies an old Service manifest over a new Deployment

The symptom is always the same: the app appears healthy, but it's unreachable."

### 6. Multi-Step Deductive Reasoning
"This is an advanced scenario because the fix requires following a chain:
1. Empty Endpoints → label mismatch (fix it)
2. Still can't connect → port mismatch (fix it)
3. Verify with a real HTTP request

In a real interview, fixing only the labels and declaring victory is a partial answer. The best candidates methodically verify end-to-end connectivity before concluding."

---

## Cleanup

To remove the deployment and service:
```bash
kubectl delete -f deployment.yaml
```

Or let them run and move to the next scenario.
