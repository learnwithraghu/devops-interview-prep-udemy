# Debugging Guide: HPA Not Scaling

## Quick Start Checklist

- [ ] Cluster running on EC2: `kubectl get nodes`
- [ ] Image built: `docker images | grep k8s-debug-app`
- [ ] Manifest deployed: `kubectl apply -f deployment.yaml`
- [ ] Ready to debug: HPA shows `<unknown>` for metrics

---

## Step 1: Observe the Broken State

### Deploy the broken version:
```bash
cd section-04-production-ops/18-hpa-metrics-server-missing
kubectl apply -f deployment.yaml
```

### Check the HPA:
```bash
kubectl get hpa
```

**Expected output:**
```
NAME       REFERENCE             TARGETS         MINPODS   MAXPODS   REPLICAS
hpa-demo   Deployment/hpa-demo   cpu: <unknown>/50%   1         5         1
```

The `TARGETS` column shows `<unknown>` — the HPA cannot read CPU metrics.

### Describe the HPA for details:
```bash
kubectl describe hpa hpa-demo
```

**Expected output (Conditions section):**
```
Conditions:
  Type           Status  Reason                   Message
  AbleToScale    True    ...
  ScalingActive  False   FailedGetResourceMetric  the HPA was unable to compute the replica count: failed to get cpu utilization: unable to get metrics for resource cpu: unable to fetch metrics from resource metrics API: the server could not find the requested resource
```

The metrics API is unavailable — metrics-server is not installed.

---

## Step 2: Verify metrics-server Is Missing

### Check for metrics-server in kube-system:
```bash
kubectl get pods -n kube-system
```

**Expected output:** No `metrics-server` Pod listed.

### Confirm kubectl top also fails:
```bash
kubectl top nodes
```

**Expected output:**
```
error: Metrics API not available
```

---

## Step 3: Confirm Deployment Has Resource Requests

The HPA requires resource requests to calculate utilization:

```bash
kubectl describe deployment hpa-demo
```

**Expected output (Containers resources section):**
```
    Requests:
      cpu:     100m
      memory:  128Mi
```

The Deployment is correctly configured. The only missing piece is metrics-server.

---

## The Fix: Install metrics-server

### Apply the metrics-server manifest:
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### kind requires insecure kubelet TLS — patch the deployment:
```bash
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
  {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}
]'
```

### Wait for metrics-server to be ready:
```bash
kubectl rollout status deployment/metrics-server -n kube-system
```

---

## Step 4: Verify Metrics Are Available

### Confirm kubectl top works:
```bash
kubectl top nodes
```

**Expected output:**
```
NAME                    CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
course-admin-control-plane   100m         5%     800Mi           10%
```

### Check the HPA now reads metrics:
```bash
kubectl get hpa
```

**Expected output:**
```
NAME       REFERENCE             TARGETS       MINPODS   MAXPODS   REPLICAS
hpa-demo   Deployment/hpa-demo   cpu: 2%/50%   1         5         1
```

The HPA now shows actual CPU utilization instead of `<unknown>`.

---

## Instructor Talking Points

### 1. unknown Means Metrics Pipeline Is Broken
"When HPA shows `<unknown>`, the metrics pipeline is broken — not the HPA config itself. Check metrics-server first, then verify the target Deployment has resource requests."

### 2. kind Needs the Insecure TLS Flag
"kind uses self-signed kubelet certificates. metrics-server rejects them by default. The `--kubelet-insecure-tls` flag is required for kind and most local clusters. In production with proper certificates, you don't need this."

### 3. Resource Requests Are Required for CPU HPA
"HPA calculates utilization as `actual usage / requests`. If requests are not set, the HPA cannot compute a percentage and will not scale. Always verify requests exist before blaming metrics-server."

---

## Cleanup

```bash
kubectl delete -f deployment.yaml
kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```
