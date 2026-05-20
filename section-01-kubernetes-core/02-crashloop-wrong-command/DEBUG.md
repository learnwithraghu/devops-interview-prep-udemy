# Debugging Guide: CrashLoopBackOff - Wrong Command

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
NAME                   READY   STATUS             RESTARTS   AGE
wrong-cmd-demo-xxxxx  0/1     CrashLoopBackOff   1          15s
wrong-cmd-demo-xxxxx  0/1     CrashLoopBackOff   2          27s
wrong-cmd-demo-xxxxx  0/1     CrashLoopBackOff   3          43s
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
NAME                   READY   STATUS             RESTARTS   AGE
wrong-cmd-demo-xxxxx  0/1     CrashLoopBackOff   3          45s
```

Copy the pod name (e.g., `wrong-cmd-demo-xxxxx`).

---

## Step 3: Describe the Pod (Find the Root Cause)

### Run describe with the pod name:
```bash
kubectl describe pod wrong-cmd-demo-xxxxx
```

### Look for the "Last State" section (scroll down):

**Expected output:**
```
Last State:     Terminated
  Reason:       Error
  Exit Code:    127
  Started:      Fri, 20 May 2026 14:32:10 +0000
  Finished:     Fri, 20 May 2026 14:32:10 +0000
```

### Key indicators:
- **Exit Code: 127** — The container tried to run a command that does not exist
- **Reason: Error** — The process failed to start

---

## Step 4: Check the Logs

### See exactly what the shell reported:
```bash
kubectl logs wrong-cmd-demo-xxxxx
```

**Expected output:**
```
/bin/sh: 1: run-app: not found
```

Or if the container uses a different shell:
```
sh: run-app: not found
```

This tells you the binary `run-app` is missing from the container's `$PATH`.

---

## Root Cause Analysis

By now you've seen:
- Pod in `CrashLoopBackOff` state
- `describe` output showing `Exit Code: 127`
- Logs showing `run-app: not found`

The issue is in `deployment.yaml`:

```yaml
containers:
  - name: app
    image: local/k8s-debug-app:v1
    command: ["/bin/sh", "-c", "run-app"]   # ❌ PROBLEM: run-app does not exist
```

**What happens:**
1. Container starts
2. Kubernetes overrides the default image entrypoint with `command`
3. `/bin/sh` tries to execute `run-app`
4. `run-app` is not found in the container filesystem or `$PATH`
5. Shell returns exit code 127
6. Pod restarts → loop continues

---

## The Fix: Step-by-Step (Live Editing)

You need to remove the bad `command` so the container falls back to its built-in `ENTRYPOINT`.

**Before:**
```yaml
containers:
  - name: app
    image: local/k8s-debug-app:v1
    command: ["/bin/sh", "-c", "run-app"]      # ❌ PROBLEM: Overrides default entrypoint with missing binary
```

**After:**
```yaml
containers:
  - name: app
    image: local/k8s-debug-app:v1
    # ✅ FIXED: Removed command/args so image's default ENTRYPOINT runs
```

Pick any of these two methods:

### Option 1: Vim (Interactive)

```bash
vim deployment.yaml
```

1. Search for the problem: Press `/` then type `command` and press Enter
2. Navigate to the line:
   ```yaml
     command: ["/bin/sh", "-c", "run-app"]    # <-- DELETE THIS LINE
   ```
3. Delete the entire `command:` line:
   - Place cursor on the line
   - Press `dd` to delete the whole line
4. Press `Esc` to ensure you're in normal mode
5. Save: `:wq`

### Option 2: Nano (Simplest)

```bash
nano deployment.yaml
```

Use arrow keys to navigate to the `command:` line, delete it with `Backspace` or `Delete`, then `Ctrl+O` to save, `Ctrl+X` to exit.

---

## Editor Tips for Large Files

If your manifest gets big (100+ lines), use these tricks:

### Search in Vim
```bash
vim deployment.yaml
```

Once inside, search for text:
```
/command
```

Press `n` to find next, `N` to find previous.

### Jump to Line Number
```bash
vim +25 deployment.yaml
```

Opens vim and jumps directly to line 25.

### Use grep to find line numbers first
```bash
grep -n "command" deployment.yaml
```

Shows you exactly which lines contain this string. Very helpful when editing!

### Compare before/after changes
```bash
cp deployment.yaml deployment.yaml.bak
vim deployment.yaml
diff -u deployment.yaml.bak deployment.yaml
```

---

## Step 5: Apply the Fix

### Apply the corrected manifest:
```bash
kubectl apply -f deployment.yaml
```

**Expected output:**
```
deployment.apps/wrong-cmd-demo configured
```

---

## Step 6: Verify the Fix

### Watch the pod restart and become healthy:
```bash
kubectl get pods -w
```

**Expected output:**
```
NAME                   READY   STATUS        RESTARTS   AGE
wrong-cmd-demo-xxxxx  0/1     Terminating   3          2m
wrong-cmd-demo-xxxxx  0/1     Pending       0          0s
wrong-cmd-demo-xxxxx  0/1     ContainerCreating 0      0s
wrong-cmd-demo-xxxxx  1/1     Running       0          5s
```

Once it shows `1/1 Running`, exit with `Ctrl+C`.

### Double-check the pod status:
```bash
kubectl describe pod wrong-cmd-demo-xxxxx
```

**Look for Last State (should show success this time):**
```
Last State:     Terminated
  Reason:       Completed
  Exit Code:    0
```

Or if just started, there may be no "Last State" yet.

### Check the logs to confirm the default entrypoint is running:
```bash
kubectl logs wrong-cmd-demo-xxxxx
```

**Expected output:**
```
2026-05-20T14:35:12Z [INFO] Starting server...
2026-05-20T14:35:12Z [INFO] Server starting on 0.0.0.0:8080
```

Success! The image's built-in command is now executing correctly.

---

## Instructor Talking Points

### 1. What is Exit Code 127?
"Exit code 127 means 'command not found.' In Linux, when a shell or the OS tries to execute a program and can't locate it in the filesystem or `$PATH`, it returns 127. In Kubernetes, this almost always means the `command` or `args` in your manifest points to a binary or script that doesn't exist inside the container."

### 2. Command vs. Entrypoint
"Docker images have a default `ENTRYPOINT` and `CMD`. In Kubernetes:
- **`command`** overrides the image's `ENTRYPOINT`
- **`args`** overrides the image's `CMD`

If you specify `command`, you are fully responsible for what runs. If that binary is missing, the container crashes immediately. Best practice: only override `command`/`args` when you absolutely need to, and verify the binary exists in the image first."

### 3. Real-World Impact
"In production, wrong-command crashes usually happen because:
- A manifest was copied from another project with a different image
- A script name changed in a newer image tag but the manifest wasn't updated
- Developers assume `bash` or `sh` is available in minimal images like `distroless` or `scratch`
- CI/CD injects dynamic commands without validating them against the image contents

Always test your overridden `command` locally with `docker run` before deploying to Kubernetes."

### 4. Live Editing Workflow
"Notice how we:
1. **Identified** the issue with `describe` and `logs` (2 commands)
2. **Located** the problem in the YAML (vim search)
3. **Fixed** it directly (deleted the bad `command` line)
4. **Applied** the fix (`kubectl apply`)
5. **Verified** it works (`get pods` + `logs`)

This is the same debugging workflow you'll use on every scenario."

---

## Cleanup

To remove the deployment:
```bash
kubectl delete deployment wrong-cmd-demo
```

Or let it run and move to the next scenario.
