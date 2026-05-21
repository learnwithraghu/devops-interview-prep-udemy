# Debugging Guide: ResourceQuota & LimitRange Denial

## Quick Start Checklist

- [ ] Cluster running on EC2: `kubectl get nodes`
- [ ] Image built: `docker images | grep k8s-debug-app`
- [ ] Manifest deployed: `kubectl apply -f deployment.yaml`
- [ ] Ready to debug: One Pod Pending in quota-demo namespace

---

## Step 1: Observe the Broken State

### Deploy the broken version:
```bash
cd section-04-production-ops/17-resourcequota-limitrange-denial
kubectl apply -f deployment.yaml
```

### Check Pod status in the namespace:
```bash
kubectl get pods -n quota-demo
```

**Expected output:**
```
NAME                          READY   STATUS    RESTARTS   AGE
quota-demo-xxxxx              1/1     Running   0          30s
quota-demo-yyyyy              0/1     Pending   0          30s
```

One Pod is Running, the second is Pending.

---

## Step 2: Describe the Pending Pod

### Read scheduling events:
```bash
kubectl describe pod quota-demo-yyyyy -n quota-demo
```

Copy the pod name from the previous step.

**Expected output (Events section):**
```
Warning  FailedScheduling  ...  0/1 nodes are available: 1 Insufficient cpu.
```

Or:
```
Warning  FailedScheduling  ...  exceeded quota: quota-demo, requested: requests.cpu=500m, used: requests.cpu=500m, limited: requests.cpu=500m
```

The scheduler cannot place the second Pod because the namespace CPU quota is exhausted.

---

## Step 3: Inspect the ResourceQuota and LimitRange

### Describe the quota:
```bash
kubectl describe resourcequota quota-demo -n quota-demo
```

**Expected output:**
```
Name:            quota-demo
Namespace:       quota-demo
Resource         Used  Hard
--------         ----  ----
limits.cpu       500m  500m
limits.memory    256Mi 512Mi
pods             1     2
requests.cpu     500m  500m
requests.memory  256Mi 512Mi
```

The math:
- Quota allows `500m` CPU total
- Each Pod requests `500m` CPU
- One Pod is already using `500m` → no room for a second

### Describe the LimitRange (for context):
```bash
kubectl describe limitrange quota-demo-limits -n quota-demo
```

**Expected output:**
```
Type        Resource  Min  Max  Default Request  Default Limit  Max Limit/Request Ratio
----        --------  ---  ---  ---------------  -------------  -----------------------
Container   cpu       -    -    250m             500m           -
Container   memory    -    -    128Mi            256Mi          -
```

The LimitRange sets defaults for containers without explicit requests. Our Deployment explicitly sets `500m` CPU, which is within the LimitRange defaults. The LimitRange is not the blocker — the ResourceQuota is.

---

## Root Cause Analysis

- Deployment requests `2` replicas with `500m` CPU each = `1000m` total needed
- ResourceQuota allows only `500m` CPU in the namespace
- First Pod schedules, second Pod is denied

---

## The Fix: Reduce Replicas or Resource Requests

### Option A — Reduce replicas (simplest):
```bash
vim deployment.yaml
```

1. Search for replicas: `/replicas:`
2. Change:
   ```yaml
     replicas: 2              # <-- EDIT THIS LINE: change to 1
   ```
3. Save and exit

### Option B — Lower CPU requests:
Change `cpu: 500m` to `cpu: 250m` in both requests and limits so two Pods fit within the quota.

---

## Step 4: Apply and Verify

### Apply the fix:
```bash
kubectl apply -f deployment.yaml
```

### Verify Pods:
```bash
kubectl get pods -n quota-demo
```

**Expected output (after reducing to 1 replica):**
```
NAME                          READY   STATUS    RESTARTS   AGE
quota-demo-xxxxx              1/1     Running   0          2m
```

### Verify quota usage:
```bash
kubectl describe resourcequota quota-demo -n quota-demo
```

**Expected output:**
```
requests.cpu     500m  500m
pods             1     2
```

Within limits. No Pending Pods.

---

## Instructor Talking Points

### 1. describe pod Shows Quota Failures
"FailedScheduling events explicitly mention quota exhaustion when that's the cause. Look for 'exceeded quota' or 'Insufficient cpu' in Events."

### 2. Do the Math
"Sum the resource requests of all running Pods in the namespace and compare against the quota Hard limits. Don't forget to multiply by replica count when evaluating a Deployment."

### 3. Quotas Apply at Scheduling Time
"ResourceQuota is enforced by the scheduler, not the kubelet. Pods that exceed quota never get scheduled — they stay Pending indefinitely."

---

## Cleanup

```bash
kubectl delete -f deployment.yaml
```

This also deletes the namespace and all resources within it.
