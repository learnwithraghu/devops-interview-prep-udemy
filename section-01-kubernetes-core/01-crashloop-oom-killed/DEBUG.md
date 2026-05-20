# Debugging Guide: CrashLoopBackOff - OOMKilled

## Quick Start Checklist

- [ ] Cluster running: `kubectl get nodes`
- [ ] Image built: `docker images | grep k8s-debug-app`
- [ ] Deployment deployed: `kubectl get pods`
- [ ] Ready to debug: Pod shows `CrashLoopBackOff`

---

## Step 1: Observe the Broken State

### Deploy the broken version:
```bash
kubectl apply -f deployment.yaml
```

### Watch it fail:
```bash
kubectl get pods -w
```

**Expected output:**
```
NAME               READY   STATUS             RESTARTS   AGE
oom-demo-xxxxx     0/1     CrashLoopBackOff   1          15s
oom-demo-xxxxx     0/1     CrashLoopBackOff   2          27s
oom-demo-xxxxx     0/1     CrashLoopBackOff   3          43s
```

Exit watch with `Ctrl+C`.

---

## Step 2: Get the Pod Name

### List all pods and copy the name:
```bash
kubectl get pods
```

**Expected output:**
```
NAME               READY   STATUS             RESTARTS   AGE
oom-demo-xxxxx     0/1     CrashLoopBackOff   3          45s
```

Copy the pod name (e.g., `oom-demo-xxxxx`).

---

## Step 3: Describe the Pod (Find the Root Cause)

### Run describe with the pod name:
```bash
kubectl describe pod oom-demo-xxxxx
```

### Look for the "Last State" section (scroll down):

**Expected output:**
```
Last State:     Terminated
  Reason:       OOMKilled
  Exit Code:    137
  Started:      Fri, 20 May 2026 14:32:10 +0000
  Finished:     Fri, 20 May 2026 14:32:11 +0000
```

### Key indicators:
- **Reason: OOMKilled** — The container was killed by the kernel
- **Exit Code: 137** — This is 128 (SIGKILL) + 9 = forced termination

---

## Step 4: Check the Events Section

Still in the describe output, scroll down to **Events:**

**Expected output:**
```
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Warning  OOMKilling 20s (x2 over 40s)  kubelet            Memory cgroup out of memory: Killed process 1 (python)
```

This tells you the Linux kernel's OOM killer is terminating the process.

---

## Step 5: View the Logs (Optional, but helpful)

### Check what the app tried to do before it was killed:
```bash
kubectl logs oom-demo-xxxxx
```

**Expected output:**
```
2026-05-20T14:32:09Z [INFO] Starting server...
2026-05-20T14:32:09Z [INFO] Attempting to allocate 128 MB of memory...
<killed by kernel before completing>
```

---

## Root Cause Analysis

By now you've seen:
- Pod in `CrashLoopBackOff` state
- `describe` output showing `OOMKilled` with exit code 137
- Kernel events showing "Memory cgroup out of memory"

The issue is in `deployment.yaml`:

```yaml
resources:
  limits:
    memory: "64Mi"      # ❌ Limit is 64 MB
  requests:
    memory: "32Mi"

env:
  - name: OOM_ALLOCATE_MB
    value: "128"        # ❌ App tries to allocate 128 MB → exceeds limit → killed
```

**What happens:**
1. Container starts with 64 MB limit
2. App tries to allocate 128 MB
3. Linux kernel detects violation
4. Process killed with exit code 137 (SIGKILL)
5. Pod restarts → loop continues

---

## The Fix: Step-by-Step (Live Editing)

You need to change two lines in the `resources` section:

**Before:**
```yaml
resources:
  limits:
    memory: "64Mi"
  requests:
    memory: "32Mi"
```

**After:**
```yaml
resources:
  limits:
    memory: "256Mi"
  requests:
    memory: "64Mi"
```

Pick any of these three methods:

### Option 1: Vim (Interactive)

```bash
vim deployment.yaml
```

1. Search for the problem: Press `/` then type `64Mi` and press Enter
2. Navigate to the line with `memory: "64Mi"` 
3. Press `i` to enter insert mode
4. Change `"64Mi"` to `"256Mi"`
5. Find and edit the `"32Mi"` request line to `"64Mi"`
6. Press `Esc` to exit insert mode
7. Save: `:wq`

### Option 2: Sed (One-liner, fastest)

```bash
sed -i 's/memory: "64Mi"/memory: "256Mi"/g' deployment.yaml
sed -i 's/memory: "32Mi"/memory: "64Mi"/g' deployment.yaml
```

Verify:
```bash
grep "memory:" deployment.yaml
```

### Option 3: Nano (Simplest)

```bash
nano deployment.yaml
```

Use arrow keys to navigate, edit the lines directly, then `Ctrl+O` to save, `Ctrl+X` to exit.

---

## Editor Tips for Large Files

If your manifest gets big (100+ lines), use these tricks:

### Search in Vim
```bash
vim deployment.yaml
```

Once inside, search for text:
```
/memory:
```

Press `n` to find next, `N` to find previous.

### Jump to Line Number
```bash
vim +20 deployment.yaml
```

Opens vim and jumps directly to line 20.

### Use grep to find line numbers first
```bash
grep -n "memory:\|OOM_ALLOCATE" deployment.yaml
```

Shows you exactly which lines contain these strings. Very helpful when editing!

### Compare before/after changes
```bash
cp deployment.yaml deployment.yaml.bak
vim deployment.yaml
diff -u deployment.yaml.bak deployment.yaml
```

---

## Step 6: Apply the Fix

### Edit deployment.yaml
```bash
vim deployment.yaml
```

1. Search for the memory limit: `/memory: "64Mi"`
2. Position cursor on that line
3. Press `i` to enter insert mode
4. Change `"64Mi"` to `"256Mi"`
5. Press `Esc` to exit insert mode
6. Also change the request from `"32Mi"` to `"64Mi"` (best practice: request ≈ limit/4)
7. Save: `:wq`

**Fixed resources block should look like:**
```yaml
resources:
  limits:
    memory: "256Mi"     # ✅ Increased from 64Mi
  requests:
    memory: "64Mi"      # ✅ Increased from 32Mi
```

### Apply the fix:
```bash
kubectl apply -f deployment.yaml
```

**Expected output:**
```
deployment.apps/oom-demo configured
```

---

## Step 7: Verify the Fix

### Watch the pod restart and become healthy:
```bash
kubectl get pods -w
```

**Expected output:**
```
NAME               READY   STATUS        RESTARTS   AGE
oom-demo-xxxxx     0/1     Terminating   3          2m
oom-demo-xxxxx     0/1     Pending       0          0s
oom-demo-xxxxx     0/1     ContainerCreating 0      0s
oom-demo-xxxxx     1/1     Running       0          5s
```

Once it shows `1/1 Running`, exit with `Ctrl+C`.

### Double-check the pod status:
```bash
kubectl describe pod oom-demo-xxxxx
```

**Look for Last State (should show success this time):**
```
Last State:     Terminated
  Reason:       Completed
  Exit Code:    0
```

Or if just started, there may be no "Last State" yet.

### Check the logs to confirm memory allocation succeeded:
```bash
kubectl logs oom-demo-xxxxx
```

**Expected output:**
```
2026-05-20T14:35:12Z [INFO] Starting server...
2026-05-20T14:35:12Z [INFO] Attempting to allocate 128 MB of memory...
2026-05-20T14:35:12Z [INFO] Memory allocation successful!
2026-05-20T14:35:12Z [INFO] Server starting on 0.0.0.0:8080
```

Success! The app allocated memory without hitting the limit.

---

## Instructor Talking Points

### 1. What is OOMKilled?
"When a process tries to use more memory than its cgroup limit allows, the Linux kernel's OOM (Out Of Memory) killer steps in and terminates the process. Exit code 137 is `128 + 9 = SIGKILL`, meaning the process was forcefully killed by the system."

### 2. Exit Code 137 Breakdown
- **128** = base value for fatal signal
- **9** = SIGKILL signal number
- **Result:** 137 = immediate, non-graceful termination

### 3. Requests vs. Limits (Best Practice)
"Kubernetes has two resource settings:
- **Requests:** What the scheduler reserves when placing the pod (for fair distribution)
- **Limits:** The hard ceiling the container cannot exceed (enforced by cgroups)

Best practice: `requests ≈ limit / 4` to allow some burst, but keep limits realistic."

### 4. Real-World Impact
"In production, OOMKilled pods usually indicate:
- Resource estimates are too low
- Memory leaks in the application code
- Sudden traffic spikes exceeding expected usage
- Missing autoscaling or HPA configuration

Setting correct limits prevents runaway processes from crashing entire nodes."

### 5. AWS EC2 Context
"On this t3.2xlarge instance with 32 GB RAM, we have plenty of headroom. The kind cluster uses ~3GB, leaving ~29GB for workloads. Even after we fix this to 256Mi, we're using <1% of available memory. But the principle—respecting limits—applies everywhere from dev laptops to production clouds."

### 6. Live Editing Workflow
"Notice how we:
1. **Identified** the issue with `describe` and logs (2 commands)
2. **Located** the problem in the YAML (vim search)
3. **Fixed** it directly (one sed/vim edit)
4. **Applied** the fix (kubectl apply)
5. **Verified** it works (describe + logs)

This is the debugging workflow you'll use on every scenario."

---

## Cleanup

To remove the deployment:
```bash
kubectl delete deployment oom-demo
```

Or let it run and move to the next scenario.
