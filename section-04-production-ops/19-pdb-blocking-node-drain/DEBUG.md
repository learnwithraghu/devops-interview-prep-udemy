# Debugging Guide: PDB Blocking Node Drain

## Quick Start Checklist

- [ ] Two-node kind cluster running: `kubectl get nodes`
- [ ] Image loaded: `kind load docker-image local/k8s-debug-app:v1 --name course-admin`
- [ ] Manifest deployed: `kubectl apply -f deployment.yaml`
- [ ] Pods spread across nodes: `kubectl get pods -o wide`
- [ ] Ready to debug: drain fails with PDB violation

---

## Step 1: Set Up the Two-Node Cluster

If you are using the default single-node cluster from `setup.sh`, recreate it with two nodes:

```bash
cd course-admin
make build DOCKER_HUB_USER=local
kind delete cluster --name course-admin
kind create cluster --name course-admin --config ../section-04-production-ops/19-pdb-blocking-node-drain/kind-config.yaml
kind load docker-image local/k8s-debug-app:v1 --name course-admin
```

### Verify two nodes:
```bash
kubectl get nodes
```

**Expected output:**
```
NAME                        STATUS   ROLES           AGE
course-admin-control-plane  Ready    control-plane   2m
course-admin-worker         Ready    <none>          2m
```

---

## Step 2: Deploy and Observe

### Deploy the broken version:
```bash
cd section-04-production-ops/19-pdb-blocking-node-drain
kubectl apply -f deployment.yaml
```

### Verify Pods are running:
```bash
kubectl get pods -o wide
```

**Expected output:**
```
NAME                        READY   STATUS    NODE
pdb-demo-xxxxx              1/1     Running   course-admin-worker
pdb-demo-yyyyy              1/1     Running   course-admin-control-plane
```

Note which node each Pod is on — you'll drain the worker node.

---

## Step 3: Attempt to Drain the Worker Node

### Cordon and drain:
```bash
kubectl drain course-admin-worker --ignore-daemonsets --delete-emptydir-data
```

**Expected output:**
```
...
error when evicting pods/"pdb-demo-xxxxx" -n "default" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
...
evicting pod pdb-demo-xxxxx error: Cannot evict pod as it would violate the pod's disruption budget.
```

The drain is blocked by the PodDisruptionBudget.

---

## Step 4: Inspect the PDB

### List PDBs:
```bash
kubectl get pdb
```

**Expected output:**
```
NAME       MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
pdb-demo   2               N/A               0                     5m
```

`ALLOWED DISRUPTIONS` is `0` — no Pods can be safely evicted.

### Describe the PDB:
```bash
kubectl describe pdb pdb-demo
```

**Expected output:**
```
Min available:     2
Selector:          app=pdb-demo
Status:
    Allowed disruptions:  0
    Current:              2
    Desired:              2
    Total:                2
```

The PDB requires at least 2 Pods available. There are exactly 2 total. Evicting even one would leave only 1 — violating `minAvailable: 2`.

### Check Deployment replica count:
```bash
kubectl get deployment pdb-demo
```

**Expected output:**
```
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
pdb-demo   2/2     2            2           5m
```

2 replicas with `minAvailable: 2` means zero disruption is allowed.

---

## Root Cause Analysis

- Deployment has `2` replicas
- PDB requires `minAvailable: 2`
- Draining any node that runs a Pod would drop below the minimum
- Kubernetes blocks the eviction to protect availability

---

## The Fix: Allow Disruption During Maintenance

### Option A — Scale up the Deployment (safest for production):
```bash
kubectl scale deployment pdb-demo --replicas=3
kubectl get pdb
```

**Expected output:**
```
NAME       MIN AVAILABLE   ALLOWED DISRUPTIONS
pdb-demo   2               1
```

Now one Pod can be evicted while keeping 2 available.

### Option B — Lower minAvailable (edit manifest):
```bash
vim deployment.yaml
```

Change:
```yaml
  minAvailable: 2          # <-- EDIT THIS LINE: change to 1
```

Apply:
```bash
kubectl apply -f deployment.yaml
```

---

## Step 5: Retry the Drain

### Drain the worker node:
```bash
kubectl drain course-admin-worker --ignore-daemonsets --delete-emptydir-data
```

**Expected output:**
```
node/course-admin-worker cordoned
evicting pod default/pdb-demo-xxxxx
pod/pdb-demo-xxxxx evicted
node/course-admin-worker drained
```

### Verify remaining Pods:
```bash
kubectl get pods -o wide
```

**Expected output:**
```
NAME                        READY   STATUS    NODE
pdb-demo-yyyyy              1/1     Running   course-admin-control-plane
pdb-demo-zzzzz              1/1     Running   course-admin-control-plane
```

Two Pods still running — the PDB is satisfied.

### Uncordon the node when maintenance is complete:
```bash
kubectl uncordon course-admin-worker
```

---

## Instructor Talking Points

### 1. PDBs Protect Availability During Disruption
"PodDisruptionBudgets prevent too many Pods from being evicted during voluntary disruptions — drains, upgrades, cluster autoscaler scale-downs. They do NOT protect against involuntary disruptions like node crashes."

### 2. minAvailable vs maxUnavailable
"`minAvailable: 2` means at least 2 Pods must stay running. With exactly 2 replicas, zero evictions are allowed. You must either scale up or temporarily lower the PDB before draining."

### 3. Safe Maintenance Workflow
"Production workflow: (1) scale up replicas, (2) verify ALLOWED DISRUPTIONS > 0, (3) drain the node, (4) perform maintenance, (5) uncordon, (6) scale back down."

### 4. Why Two Nodes Are Required
"A single-node cluster cannot demonstrate drain — evicting the only node's Pods just reschedules them on the same node. You need at least two nodes to show a real maintenance scenario."

---

## Cleanup

```bash
kubectl delete -f deployment.yaml
```

To restore the default single-node cluster for other scenarios:
```bash
kind delete cluster --name course-admin
cd course-admin && sudo bash setup.sh
```
