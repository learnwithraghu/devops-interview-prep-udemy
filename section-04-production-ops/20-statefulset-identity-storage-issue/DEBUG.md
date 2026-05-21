# Debugging Guide: StatefulSet Identity & Storage Issue

## Quick Start Checklist

- [ ] Cluster running on EC2: `kubectl get nodes`
- [ ] Image built: `docker images | grep k8s-debug-app`
- [ ] Manifest deployed: `kubectl apply -f deployment.yaml`
- [ ] Ready to debug: StatefulSet Pod Running but headless Service has no Endpoints

---

## Step 1: Observe the Broken State

### Deploy the broken version:
```bash
cd section-04-production-ops/20-statefulset-identity-storage-issue
kubectl apply -f deployment.yaml
```

### Check the StatefulSet and Pod:
```bash
kubectl get statefulset
kubectl get pods
```

**Expected output:**
```
NAME      READY   AGE
ss-demo   1/1     30s

NAME         READY   STATUS    RESTARTS   AGE
ss-demo-0    1/1     Running   0          30s
```

The StatefulSet Pod is Running.

### Check the headless Service Endpoints:
```bash
kubectl get endpoints ss-demo-headless
```

**Expected output:**
```
NAME               ENDPOINTS   AGE
ss-demo-headless   <none>      30s
```

The headless Service has no Endpoints — stable network identity is broken.

---

## Step 2: Describe the StatefulSet

### Inspect serviceName and labels:
```bash
kubectl describe statefulset ss-demo
```

**Expected output (key sections):**
```
Pods Status:        1 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:  app=ss-demo
Service Name:  ss-demo-headless
```

The StatefulSet's `serviceName` correctly references `ss-demo-headless`. Pod labels are `app=ss-demo`.

---

## Step 3: Inspect the Headless Service

### Describe the Service:
```bash
kubectl describe svc ss-demo-headless
```

**Expected output:**
```
Selector:                 app=ss-demo-wrong
Endpoints:                <none>
```

The Service selector is `app=ss-demo-wrong`, but the StatefulSet Pods are labeled `app=ss-demo`. The labels do not match.

### Confirm Pod labels:
```bash
kubectl get pod ss-demo-0 --show-labels
```

**Expected output:**
```
NAME       READY   STATUS    LABELS
ss-demo-0  1/1     Running   app=ss-demo
```

### Confirm no Pods match the Service selector:
```bash
kubectl get pods -l app=ss-demo-wrong
```

**Expected output:**
```
No resources found in default namespace.
```

---

## Root Cause Analysis

- StatefulSet Pods have label `app=ss-demo`
- Headless Service selector expects `app=ss-demo-wrong`
- No Pods match the Service selector → Endpoints are empty
- Stable DNS identity (`ss-demo-0.ss-demo-headless.default.svc.cluster.local`) will not resolve correctly

The `serviceName` in the StatefulSet is correct — the bug is in the Service selector.

---

## The Fix: Correct the Service Selector

### Edit deployment.yaml:
```bash
vim deployment.yaml
```

1. Search for the Service section: `/ss-demo-headless`
2. Navigate to the selector line:
   ```yaml
     selector:
       app: ss-demo-wrong       # <-- EDIT THIS LINE: change to ss-demo
   ```
3. Press `i` to enter insert mode
4. Change `ss-demo-wrong` to `ss-demo`
5. Press `Esc` then save: `:wq`

Verify the Service section now looks like this:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: ss-demo-headless
  labels:
    app: ss-demo
spec:
  clusterIP: None
  selector:
    app: ss-demo
  ports:
    - port: 8080
      targetPort: 8080
```

---

## Step 4: Apply and Verify

### Apply the fixed manifest:
```bash
kubectl apply -f deployment.yaml
```

### Verify Endpoints are populated:
```bash
kubectl get endpoints ss-demo-headless
```

**Expected output:**
```
NAME               ENDPOINTS          AGE
ss-demo-headless   10.244.0.5:8080    5m
```

### Verify stable DNS identity (from a debug Pod):
```bash
kubectl run debug --rm -it --image=busybox --restart=Never -- nslookup ss-demo-0.ss-demo-headless.default.svc.cluster.local
```

**Expected output:**
```
Name:      ss-demo-0.ss-demo-headless.default.svc.cluster.local
Address 1: 10.244.0.5 ss-demo-0.ss-demo-headless.default.svc.cluster.local
```

Success! The headless Service now provides stable network identity for the StatefulSet Pod.

---

## Instructor Talking Points

### 1. serviceName vs Service Selector
"The StatefulSet `serviceName` must match the headless Service **name**. But the Service also needs a **selector** that matches the Pod labels. Getting the name right is not enough — the selector must match too."

### 2. Headless Services and StatefulSets Go Together
"StatefulSets rely on headless Services (`clusterIP: None`) for stable DNS: `<pod-name>.<service-name>.<namespace>.svc.cluster.local`. If Endpoints are empty, this DNS won't resolve."

### 3. Same Debugging Pattern as Regular Services
"This is the same selector mismatch pattern from Service discovery scenarios, applied to StatefulSet identity. Always compare Service selector with Pod labels when Endpoints are empty."

---

## Cleanup

```bash
kubectl delete -f deployment.yaml
```

Note: deleting the StatefulSet does not delete PVCs by default. Clean up PVCs if needed:
```bash
kubectl delete pvc data-ss-demo-0
```
