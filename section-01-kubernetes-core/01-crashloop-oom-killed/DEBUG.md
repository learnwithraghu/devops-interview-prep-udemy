# Debugging Guide: CrashLoopBackOff - OOMKilled

## Steps to Debug

### Step 1: Check Pod Status
```bash
kubectl get pods
```

**Expected Output:**
```
NAME                        READY   STATUS             RESTARTS   AGE
oom-demo-xxx-yyy           0/1     CrashLoopBackOff   3          45s
```

### Step 2: Describe the Pod
```bash
kubectl describe pod <pod-name>
```

**Expected Output (Container section):**
```
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    137
      Started:      ...
      Finished:     ...
```

**Expected Output (Events section):**
```
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  ...      ...        ...                ...                ...
  Warning  OOMKilling  5s (x3 over 30s)  ...                Memory cgroup out of memory: Killed process ...
```

## Root Cause
The container has a memory limit of `64Mi` but the application attempts to allocate `128MB` via the `OOM_ALLOCATE_MB` environment variable. When the process tries to allocate memory beyond its limit, the Linux OOM killer terminates it with exit code 137 (128 + 9 = SIGKILL).

## Fix Options

### Option 1: Increase Memory Limit (Recommended)
Increase the memory limit from `64Mi` to `256Mi` in the Deployment manifest:

```yaml
resources:
  limits:
    memory: "256Mi"  # Increased from 64Mi
  requests:
    memory: "64Mi"   # Increased from 32Mi
```

Apply the fix:
```bash
kubectl apply -f fixed/deployment.yaml
```

### Option 2: Reduce Memory Allocation
Alternatively, remove or reduce the `OOM_ALLOCATE_MB` environment variable to fit within the existing limit:

```yaml
env:
  - name: OOM_ALLOCATE_MB
    value: "32"  # Reduced from 128
```

## Verification

After applying the fix, verify the Pod is running:
```bash
kubectl get pods -l app=oom-demo
```

**Expected Output:**
```
NAME                        READY   STATUS    RESTARTS   AGE
oom-demo-xxx-yyy           1/1     Running   0          10s
```

Check the logs to confirm memory was allocated successfully:
```bash
kubectl logs <pod-name>
```

**Expected Output:**
```
2026-05-20 ... [INFO] Allocated 128 MB of memory
2026-05-20 ... [INFO] Server starting on 0.0.0.0:8080
```

## Instructor Talking Points

1. **Explain OOMKilled:** The container was killed because it exceeded its memory limit, not because of a bug in the code.

2. **Exit Code 137:** This is 128 + 9 (SIGKILL), indicating the process was forcefully killed by the system.

3. **Best Practice:** Always set both requests and limits, with limits >= requests. The gap between them determines how much the container can burst.

4. **Monitoring:** In production, OOMKilled events should trigger alerts as they indicate resource starvation or memory leaks.
