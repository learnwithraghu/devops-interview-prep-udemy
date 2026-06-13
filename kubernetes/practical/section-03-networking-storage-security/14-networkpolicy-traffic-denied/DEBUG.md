# Debugging Guide: NetworkPolicy Traffic Denial

## Quick Start Checklist

- [ ] Cluster running on EC2: `kubectl get nodes`
- [ ] Image built: `docker images | grep k8s-debug-app`
- [ ] Manifest deployed: `kubectl apply -f deployment.yaml`
- [ ] Ready to debug: App Pod Running but unreachable from other Pods

---

## Step 1: Observe the Broken State

### Deploy the broken version:
```bash
cd section-03-networking-storage-security/14-networkpolicy-traffic-denied
kubectl apply -f deployment.yaml
```

### Verify the app Pod and Service are healthy:
```bash
kubectl get pods
kubectl get endpoints netpol-demo
```

**Expected output:**
```
NAME                            READY   STATUS    RESTARTS   AGE
netpol-demo-xxxxx               1/1     Running   0          15s

NAME          ENDPOINTS          AGE
netpol-demo   10.244.0.5:8080    15s
```

The Pod is Running and the Service has Endpoints. The application itself is fine.

### Test connectivity from another Pod:
```bash
kubectl run debug --rm -it --image=busybox --restart=Never -- wget -O- -T 3 http://netpol-demo:8080
```

**Expected output:**
```
wget: download timed out
```

Traffic from the debug Pod in the `default` namespace cannot reach the application.

---

## Step 2: Inspect the NetworkPolicy

### List NetworkPolicies:
```bash
kubectl get networkpolicy
```

**Expected output:**
```
NAME          POD-SELECTOR     AGE
netpol-demo   app=netpol-demo  30s
```

A NetworkPolicy exists and selects the application Pods.

### Describe the NetworkPolicy:
```bash
kubectl describe networkpolicy netpol-demo
```

**Expected output (key sections):**
```
Pod Selector:  app=netpol-demo
Policy Types:  Ingress

Ingress:
  From:
    NamespaceSelector: kubernetes.io/metadata.name=kube-system
  To Port: 8080/TCP
```

The policy only allows ingress traffic from Pods in the `kube-system` namespace. The debug Pod runs in the `default` namespace, so its traffic is blocked.

---

## Step 3: Confirm the Debug Pod Namespace

### Check which namespace the debug Pod is in:
```bash
kubectl get pods -l run=debug
```

Or if the debug Pod already exited, note that `kubectl run debug` creates Pods in the `default` namespace unless `-n` is specified.

The debug Pod is in `default`. The NetworkPolicy only permits traffic from `kube-system`.

---

## Root Cause Analysis

By now you've seen:
- App Pod is `Running`, Service has Endpoints
- `wget` from a debug Pod in `default` times out
- NetworkPolicy `netpol-demo` selects the app Pods
- Ingress rule only allows traffic from namespace `kube-system`

**What happens:**
1. The NetworkPolicy selects Pods with label `app=netpol-demo`
2. It defines an ingress allow rule for traffic from `kube-system` namespace only
3. Kubernetes enforces default-deny for all other ingress traffic to those Pods
4. The debug Pod in `default` namespace is blocked
5. Connections time out

---

## The Fix: Allow Traffic from the Default Namespace

### Edit deployment.yaml:
```bash
vim deployment.yaml
```

1. Search for the NetworkPolicy section: `/NetworkPolicy`
2. Navigate to the namespaceSelector line:
   ```yaml
             kubernetes.io/metadata.name: kube-system    # <-- EDIT THIS LINE: change to default
   ```
3. Press `i` to enter insert mode
4. Change `kube-system` to `default`
5. Press `Esc` then save: `:wq`

Verify the NetworkPolicy section now looks like this:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: netpol-demo
spec:
  podSelector:
    matchLabels:
      app: netpol-demo
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: default
      ports:
        - protocol: TCP
          port: 8080
```

---

## Step 4: Apply and Verify

### Apply the fixed manifest:
```bash
kubectl apply -f deployment.yaml
```

### Test connectivity again:
```bash
kubectl run debug --rm -it --image=busybox --restart=Never -- wget -O- http://netpol-demo:8080
```

**Expected output:**
```
Connecting to netpol-demo:8080 (10.96.x.x:8080)
...
HTTP/1.1 200 OK
```

Success! Traffic from the `default` namespace now reaches the application.

---

## Instructor Talking Points

### 1. NetworkPolicy Creates Default-Deny
"Once a NetworkPolicy selects a Pod and defines ingress or egress rules, all traffic not explicitly allowed is denied. If your Pod was reachable before you applied a NetworkPolicy and unreachable after, the policy is your first suspect."

### 2. describe networkpolicy Shows the Rules
"`kubectl describe networkpolicy` translates the YAML into readable rules — which namespaces, pods, or IP blocks are allowed. Compare the `From` section against where your client Pod actually runs."

### 3. Test with a Debug Pod in the Same Namespace
"The fastest way to verify a NetworkPolicy fix is to run a debug Pod in the namespace you expect to be allowed and test with wget or curl. This eliminates external networking variables and tests the policy directly."

### 4. namespaceSelector vs podSelector
"`namespaceSelector` matches all Pods in a namespace. `podSelector` matches specific Pods by label. You can combine both in an `from` entry to allow traffic from specific Pods in specific namespaces. Getting either selector wrong blocks traffic silently."

### 5. kind Supports NetworkPolicy
"The kind CNI (kindnet) enforces NetworkPolicy rules. This scenario works on the EC2 kind cluster from `setup.sh`. Not all local Kubernetes setups enforce NetworkPolicy — kind and Calico/Cilium-based clusters do."

---

## Cleanup

To remove all resources:
```bash
kubectl delete -f deployment.yaml
```

Or move on to the next scenario.
