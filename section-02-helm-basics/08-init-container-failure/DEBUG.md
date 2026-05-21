# Debugging Guide: Init Container Failure

## Quick Start Checklist

- [ ] Helm installed: `helm version`
- [ ] Chart directory present: `ls debug-chart/`
- [ ] Release installed: `helm list`
- [ ] Ready to debug: Pods show `Init:Error`

---

## Step 1: Observe the Broken State

### Check the release:
```bash
helm list
```

**Expected output:**
```
NAME               	NAMESPACE	REVISION	UPDATED                 	STATUS  	CHART            	APP VERSION
init-container-demo	default  	1       	...                     	deployed	debug-chart-0.1.0	
```

### Check the Pod status:
```bash
kubectl get pods
```

**Expected output:**
```
NAME                                 READY   STATUS       RESTARTS   AGE
init-container-demo-xxx-yyy        0/1     Init:Error   3          45s
```

The Pod is stuck in `Init:Error` with 3 restarts. The main container has not started because the init container is failing.

---

## Step 2: Describe the Pod

### Inspect events and container status:
```bash
kubectl describe pod <pod-name>
```

Copy the pod name from the previous `kubectl get pods` output.

**Expected output (key sections):**

Under `Init Containers:`:
```
  wait-for-api:
    State:          Waiting
      Reason:       CrashLoopBackOff
    Last State:     Terminated
      Reason:       Error
      Exit Code:    1
```

Under `Events:`:
```
  Warning  BackOff  15s (x3 over 45s)  kubelet  Back-off restarting failed container wait-for-api in pod ...
```

This tells us:
- The init container `wait-for-api` is failing
- Exit code is `1`
- Kubernetes is backing off restarts

---

## Step 3: Read Init Container Logs

### View the logs from the failing init container:
```bash
kubectl logs <pod-name> -c wait-for-api
```

**Expected output:**
```
nc: bad address 'data-api'
```

Or:
```
can't connect to remote host (0.0.0.0): Connection refused
```

The init container is running `nc -z data-api 8080` but the hostname `data-api` cannot be resolved. The container exits with code 1, and Kubernetes restarts it.

---

## Step 4: Inspect the Chart

### Read values.yaml:
```bash
cat debug-chart/values.yaml
```

**Expected output:**
```yaml
replicaCount: 1

image:
  repository: local/k8s-debug-app
  tag: v1
  pullPolicy: Never

service:
  type: ClusterIP
  port: 8080

initContainer:
  enabled: true
  image: busybox:latest
  command: ["sh", "-c", "nc -z data-api 8080 || exit 1"]
```

The `command` references `data-api:8080`, but no Service or Pod with that name exists in the cluster.

### Read the template:
```bash
cat debug-chart/templates/deployment.yaml
```

**Expected output (initContainers section):**
```yaml
      initContainers:
        - name: wait-for-api
          image: busybox:latest
          command:
            - sh
            - -c
            - nc -z data-api 8080 || exit 1
```

The template renders the command from `values.yaml` directly. The bug is in the value, not the template.

---

## Root Cause Analysis

By now you've seen:
- `kubectl get pods` shows `Init:Error`
- `kubectl describe pod` shows the init container `wait-for-api` exiting with code 1
- `kubectl logs -c wait-for-api` shows `nc` cannot resolve `data-api`
- `values.yaml` defines `command: ["sh", "-c", "nc -z data-api 8080 || exit 1"]`

**What happens:**
1. Helm renders the Deployment with the init container
2. Kubernetes schedules the Pod
3. The init container `wait-for-api` starts before the main `app` container
4. `nc -z data-api 8080` tries to resolve `data-api` and fails
5. The container exits with code 1
6. Kubernetes restarts the init container
7. After repeated failures, the Pod shows `Init:Error`
8. The main `app` container never starts

---

## The Fix: Correct the Init Container Command

### Edit values.yaml:
```bash
vim debug-chart/values.yaml
```

1. Search for the bad command: `/data-api`
2. Navigate to the line:
   ```yaml
     command: ["sh", "-c", "nc -z data-api 8080 || exit 1"]     # <-- EDIT THIS LINE
   ```
3. Press `i` to enter insert mode
4. Change the command to:
   ```yaml
     command: ["sh", "-c", "echo 'API dependency check passed'"]
   ```
5. Press `Esc` then save: `:wq`

Verify the file now looks like this:
```yaml
replicaCount: 1

image:
  repository: local/k8s-debug-app
  tag: v1
  pullPolicy: Never

service:
  type: ClusterIP
  port: 8080

initContainer:
  enabled: true
  image: busybox:latest
  command: ["sh", "-c", "echo 'API dependency check passed'"]
```

---

## Step 5: Re-Install and Verify

### Uninstall the broken release:
```bash
helm uninstall init-container-demo
```

### Install the chart with the fixed values:
```bash
helm install init-container-demo ./debug-chart
```

**Expected output:**
```
NAME: init-container-demo
LAST DEPLOYED: ...
NAMESPACE: default
STATUS: deployed
REVISION: 1
```

### Verify the Pod is running:
```bash
kubectl get pods
```

**Expected output:**
```
NAME                                 READY   STATUS    RESTARTS   AGE
init-container-demo-xxx-yyy        1/1     Running   0          10s
```

The init container now exits cleanly with code 0, so Kubernetes proceeds to start the main `app` container. The Pod reaches `Running`.

---

## Instructor Talking Points

### 1. Init Containers Run Before Main Containers
"Init containers are a powerful Kubernetes primitive. They run sequentially, in order, before any main container starts. If any init container fails, Kubernetes restarts it according to the Pod's restart policy. The main containers never start until all init containers succeed. This is why a single broken init container completely blocks your application."

### 2. describe pod vs logs -c init
"When a Pod is stuck in `Init:Error` or `Init:CrashLoopBackOff`, `kubectl describe pod` tells you WHICH init container is failing and its exit code. But `kubectl logs -c <init-container-name>` tells you WHY it's failing. Both commands are essential — describe gives you the symptom, logs give you the root cause."

### 3. Helm Values Drive Init Container Behavior
"In this chart, the init container is not hardcoded in the template — it's parameterized through `values.yaml`. This is a common Helm pattern: you expose init container image, command, and enablement as values so different environments can configure them differently. The bug was in the values, not the template. This means the fix belongs in `values.yaml`, not in `templates/deployment.yaml`."

### 4. Real-World Fixes
"In a real cluster, a failing init container like this usually means one of three things:
- The dependency service (`data-api`) hasn't been deployed yet or is in another namespace
- The service name or port in the init container command is wrong
- The init container image doesn't have the tool you need (e.g., `curl` instead of `wget`)

The proper fix is to correct the command to match the actual dependency. For this demo, we replaced it with a harmless `echo` so the main app starts. In production, you'd fix the hostname or ensure the service exists."

### 5. Why Not Just Disable the Init Container?
"You might notice `initContainer.enabled: true` in `values.yaml` and wonder if you could just set it to `false`. You could, but that bypasses the dependency check entirely. If the main app truly needs the API to be available before starting, disabling the init container could cause the app to crash or behave incorrectly. The right fix is to make the check valid, not remove it."

---

## Cleanup

To remove the release:
```bash
helm uninstall init-container-demo
```

Or move on to the next scenario.
