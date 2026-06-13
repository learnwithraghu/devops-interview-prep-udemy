# Debugging Guide: Pod Stuck Pending - Node Affinity

## Quick Start Checklist

- [ ] Cluster running: `kubectl get nodes`
- [ ] Image built: `docker images | grep k8s-debug-app`
- [ ] Deployment deployed: `kubectl get pods`
- [ ] Ready to debug: Pod shows `Pending`

---

## Step 1: Observe the Broken State

### Deploy the broken version:
```bash
kubectl apply -f deployment.yaml
```

### Watch the pod status:
```bash
kubectl get pods -w
```

**Expected output:**
```
NAME                   READY   STATUS    RESTARTS   AGE
affinity-demo-xxxxx  0/1     Pending   0          10s
affinity-demo-xxxxx  0/1     Pending   0          30s
affinity-demo-xxxxx  0/1     Pending   0          60s
```

Notice the pod never leaves `Pending`. Exit watch with `Ctrl+C`.

---

## Step 2: Get the Pod Name

### List all pods and copy the name:
```bash
kubectl get pods
```

**Expected output:**
```
NAME                   READY   STATUS    RESTARTS   AGE
affinity-demo-xxxxx  0/1     Pending   0          2m
```

Copy the pod name (e.g., `affinity-demo-xxxxx`).

---

## Step 3: Describe the Pod (Find the Scheduler Events)

### Run describe with the pod name:
```bash
kubectl describe pod affinity-demo-xxxxx
```

### Look at the **Events** section at the bottom:

**Expected output:**
```
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  10s   default-scheduler  0/1 nodes are available: 1 node(s) didn't match Pod's node affinity/selector.
```

### Key indicator:
- **`FailedScheduling`** — The scheduler could not place this pod on any node
- **`didn't match Pod's node affinity/selector`** — The pod has a hard constraint that no node satisfies

---

## Step 4: Check the Node Labels

### List all nodes and their labels:
```bash
kubectl get nodes --show-labels
```

**Expected output:**
```
NAME                 STATUS   ROLES           AGE   VERSION   LABELS
kind-control-plane   Ready    control-plane   10m   v1.29.0   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=kind-control-plane,kubernetes.io/os=linux,node-role.kubernetes.io/control-plane=,node.kubernetes.io/exclude-from-external-load-balancers=
```

### Search for the label the pod is looking for:
```bash
kubectl get nodes --show-labels | grep disktype
```

**Expected output:**
```
# (no output — the label does not exist on any node)
```

This confirms no node has the label the pod requires.

---

## Root Cause Analysis

By now you've seen:
- Pod stuck in `Pending` indefinitely
- `describe` shows `FailedScheduling` with `didn't match Pod's node affinity/selector`
- No node has the `disktype=ssd` label

The issue is in `deployment.yaml`:

```yaml
spec:
  template:
    spec:
      nodeSelector:
        disktype: ssd    # ❌ PROBLEM: No node in the cluster has this label
```

**What happens:**
1. Pod is created
2. Scheduler tries to find a node matching `disktype=ssd`
3. No node has this label
4. Pod remains in `Pending` forever

---

## The Fix: Step-by-Step (Live Editing)

You have **two valid fixes**. Choose one:

### Fix Option A: Add the Missing Label to the Node (Ops Fix)

This is the fix if the pod legitimately needs to run on SSD-backed nodes.

```bash
kubectl label nodes kind-control-plane disktype=ssd
```

**Expected output:**
```
node/kind-control-plane labeled
```

Verify:
```bash
kubectl get nodes --show-labels | grep disktype
```

The pod should schedule automatically within seconds.

### Fix Option B: Remove the nodeSelector from the Pod (Dev Fix)

This is the fix if the `nodeSelector` was copy-pasted from another environment and is not actually needed here.

**Before:**
```yaml
spec:
  template:
    spec:
      nodeSelector:
        disktype: ssd      # ❌ PROBLEM: No node has this label
      containers:
```

**After:**
```yaml
spec:
  template:
    spec:
      # ✅ FIXED: Removed nodeSelector so pod can schedule on any available node
      containers:
```

Pick any of these three methods:

#### Option 1: Vim (Interactive)

```bash
vim deployment.yaml
```

1. Search for the problem: Press `/` then type `nodeSelector` and press Enter
2. Navigate to the block:
   ```yaml
     nodeSelector:      # <-- DELETE THIS LINE
       disktype: ssd     # <-- AND DELETE THIS LINE
   ```
3. Delete both lines:
   - Place cursor on `nodeSelector:` line
   - Press `dd` to delete the line
   - Press `dd` again to delete the `disktype: ssd` line
4. Press `Esc` to ensure you're in normal mode
5. Save: `:wq`

#### Option 2: Nano (Simplest)

```bash
nano deployment.yaml
```

Use arrow keys to navigate to the `nodeSelector:` block, delete both lines with `Backspace`/`Delete`, then `Ctrl+O` to save, `Ctrl+X` to exit.

---

## Editor Tips for Large Files

If your manifest gets big (100+ lines), use these tricks:

### Search in Vim
```bash
vim deployment.yaml
```

Once inside, search for text:
```
/nodeSelector
```

Press `n` to find next, `N` to find previous.

### Jump to Line Number
```bash
vim +35 deployment.yaml
```

Opens vim and jumps directly to line 35.

### Use grep to find line numbers first
```bash
grep -n "nodeSelector\|disktype" deployment.yaml
```

Shows you exactly which lines contain these strings. Very helpful when editing!

### Compare before/after changes
```bash
cp deployment.yaml deployment.yaml.bak
vim deployment.yaml
diff -u deployment.yaml.bak deployment.yaml
```

---

## Step 5: Apply the Fix (If Using Option B)

### Apply the corrected manifest:
```bash
kubectl apply -f deployment.yaml
```

**Expected output:**
```
deployment.apps/affinity-demo configured
```

---

## Step 6: Verify the Fix

### Watch the pod get scheduled and become healthy:
```bash
kubectl get pods -w
```

**Expected output:**
```
NAME                   READY   STATUS            RESTARTS   AGE
affinity-demo-xxxxx  0/1     Pending           0          3m
affinity-demo-xxxxx  0/1     ContainerCreating 0          0s
affinity-demo-xxxxx  1/1     Running           0          5s
```

Once it shows `1/1 Running`, exit with `Ctrl+C`.

### Double-check the pod status:
```bash
kubectl describe pod affinity-demo-xxxxx
```

**Look for the Events section (should show success this time):**
```
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  10s   default-scheduler  Successfully assigned default/affinity-demo-xxxxx to kind-control-plane
  Normal  Pulling    10s   kubelet            Pulling image "local/k8s-debug-app:v1"
  Normal  Created    5s    kubelet            Created container app
  Normal  Started    5s    kubelet            Started container app
```

### Check the logs to confirm the app is running:
```bash
kubectl logs affinity-demo-xxxxx
```

**Expected output:**
```
2026-05-20T14:35:12Z [INFO] Starting server...
2026-05-20T14:35:12Z [INFO] Server starting on 0.0.0.0:8080
```

Success! The pod is now scheduled and running.

---

## Instructor Talking Points

### 1. Why is the Pod Stuck in Pending?
"A pod in `Pending` means the scheduler hasn't found a suitable node yet. The most common reasons are:
- Resource constraints (CPU/memory requests exceed available capacity)
- Node affinity/selector mismatches (what we saw here)
- Missing tolerations for tainted nodes
- Volume binding issues (PV not available)
- Image pull errors (but those show `ImagePullBackOff`, not `Pending`)

The `kubectl describe pod` Events section is your first stop — the scheduler tells you exactly why it can't place the pod."

### 2. NodeSelector vs. NodeAffinity vs. Tolerations
- **`nodeSelector`** — Simple key-value matching. The pod only schedules on nodes with ALL the specified labels. Easy to use, but limited.
- **`nodeAffinity`** — More expressive scheduling rules with `requiredDuringSchedulingIgnoredDuringExecution` (hard) and `preferredDuringSchedulingIgnoredDuringExecution` (soft) constraints.
- **`tolerations`** — Allow pods to schedule on nodes that have matching taints. This is the flip side: the node says "keep out" with a taint, and the pod says "I'm allowed" with a toleration.

### 3. Which Fix is Better?
"It depends on your role:
- **Platform/Ops engineer:** Add the missing label to the node if the requirement is legitimate (e.g., `disktype=ssd` for a database).
- **Application developer:** Remove the unnecessary `nodeSelector` if it was copy-pasted from a different environment.

In a real interview, discussing both options shows you understand the trade-offs."

### 4. Real-World Impact
"In production, FailedScheduling usually happens because:
- A manifest was copied from a production cluster with different node labels to a dev cluster without them
- A node pool was resized or re-labeled, breaking existing deployments
- A new `nodeSelector` was added to a chart but the infrastructure team wasn't notified
- Taints were added to nodes for maintenance but pods weren't updated with tolerations

Always check `kubectl describe pod` Events first — the scheduler is surprisingly verbose and helpful."

### 5. Live Editing Workflow
"Notice how we:
1. **Identified** the issue with `get pods` (Pending is abnormal)
2. **Diagnosed** with `describe pod` (scheduler events)
3. **Correlated** with `get nodes --show-labels` (missing label)
4. **Fixed** it directly (removed nodeSelector or added node label)
5. **Verified** it works (pod transitioned to Running)

This is the 3-command intermediate pattern: get, describe, correlate."

---

## Cleanup

To remove the deployment and restore the node label (if you added it):
```bash
kubectl delete deployment affinity-demo
kubectl label nodes kind-control-plane disktype-
```

Or let it run and move to the next scenario.
