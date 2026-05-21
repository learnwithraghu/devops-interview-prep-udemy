# Debugging Guide: Helm Hook Lifecycle Failure

## Quick Start Checklist

- [ ] Helm installed: `helm version`
- [ ] Chart directory present: `ls debug-chart/`
- [ ] Docker image built: `make -C course-admin build DOCKER_HUB_USER=local`
- [ ] Install fails on pre-install hook: `helm install hook-lifecycle-demo ./debug-chart --debug`
- [ ] Ready to debug

---

## Step 1: Observe the Broken State

### Install the release with debug output:
```bash
cd section-02-helm-basics/10-helm-hook-lifecycle-failure
helm install hook-lifecycle-demo ./debug-chart --debug
```

**Expected output (last lines):**
```
install.go:200: [debug] Original chart version: ""
install.go:217: [debug] CHART PATH: /path/to/debug-chart
...
Error: INSTALLATION FAILED: pre-install hooks failed: 1 error occurred:
        * job hook-demo-migrate failed: BackoffLimitExceeded
```

Helm stops the install because a pre-install hook failed. The main application Deployment is never created.

### Check the release status:
```bash
helm list
```

**Expected output:**
```
NAME               	NAMESPACE	REVISION	UPDATED                 	STATUS	CHART            	APP VERSION
hook-lifecycle-demo	default  	1       	...                     	failed	debug-chart-0.1.0	
```

The release is in `failed` status. No application Pods exist yet.

---

## Step 2: Find the Failed Hook Job

### List Jobs in the namespace:
```bash
kubectl get jobs
```

**Expected output:**
```
NAME                COMPLETIONS   DURATION   AGE
hook-demo-migrate   0/1           30s        30s
```

The pre-install migration Job exists but never completed successfully.

### Check for hook-related Pods:
```bash
kubectl get pods
```

**Expected output:**
```
NAME                      READY   STATUS                       RESTARTS   AGE
hook-demo-migrate-xxxxx   0/1     CreateContainerConfigError   0          30s
```

The Pod cannot start because it references a ConfigMap that does not exist yet.

---

## Step 3: Read Hook Job Logs and Events

### View logs from the hook Job:
```bash
kubectl logs job/hook-demo-migrate
```

**Expected output:**
```
Error from server (BadRequest): container "migrate" in pod "hook-demo-migrate-xxxxx" is waiting to start: configmap "hook-demo-db-config" not found
```

Or the logs may be empty if the container never started. In that case, describe the Pod:

```bash
kubectl describe pod <pod-name>
```

Copy the pod name from the previous `kubectl get pods` output.

**Expected output (Events section):**
```
  Warning  Failed     ...  kubelet  Error: configmap "hook-demo-db-config" not found
```

The migration Job tries to mount a ConfigMap named `hook-demo-db-config`, but that ConfigMap has not been created yet.

---

## Step 4: Inspect the Hook Templates

### Read the hook Job template:
```bash
cat debug-chart/templates/hooks/run-migrations-job.yaml
```

**Expected output (annotations section):**
```yaml
  annotations:
    helm.sh/hook: pre-install
    helm.sh/hook-weight: "{{ .Values.hooks.migration.weight }}"
    helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded
```

### Read the ConfigMap hook template:
```bash
cat debug-chart/templates/hooks/db-config-configmap.yaml
```

**Expected output (annotations section):**
```yaml
  annotations:
    helm.sh/hook: pre-install
    helm.sh/hook-weight: "{{ .Values.hooks.dbConfig.weight }}"
    helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded
```

Both resources are pre-install hooks. Their execution order is controlled by `hook-weight`.

### Read the current weights in values.yaml:
```bash
cat debug-chart/values.yaml
```

**Expected output:**
```yaml
hooks:
  dbConfig:
    weight: 5
  migration:
    weight: 0
```

### Render the chart to confirm the weights:
```bash
helm template hook-lifecycle-demo ./debug-chart | grep hook-weight
```

**Expected output:**
```
    helm.sh/hook-weight: "5"
    helm.sh/hook-weight: "0"
```

Helm runs hooks with **lower weight first**. With the current values:
- Migration Job (weight `0`) runs **first**
- ConfigMap (weight `5`) runs **second**

The migration Job needs the ConfigMap, but it runs before the ConfigMap is created. That is the root cause.

---

## Root Cause Analysis

By now you've seen:
- `helm install --debug` fails with `pre-install hooks failed`
- `kubectl get jobs` shows `hook-demo-migrate` at `0/1` completions
- `kubectl logs job/hook-demo-migrate` or `describe pod` shows `configmap "hook-demo-db-config" not found`
- `values.yaml` has migration weight `0` and dbConfig weight `5`

**What happens:**
1. Helm begins install and enters the pre-install hook phase
2. Hooks are sorted by weight — migration Job (weight `0`) runs first
3. The migration Job Pod tries to mount ConfigMap `hook-demo-db-config`
4. The ConfigMap does not exist yet (it has weight `5`, runs later)
5. The Pod enters `CreateContainerConfigError`
6. The Job fails after exhausting its backoff limit
7. Helm aborts the install — the main Deployment is never created

---

## The Fix: Correct Hook Weights

### Edit values.yaml:
```bash
vim debug-chart/values.yaml
```

1. Search for the hooks block: `/hooks:`
2. Navigate to the weight lines:
   ```yaml
   hooks:
     dbConfig:
       weight: 5          # <-- EDIT THIS LINE: change to 0
     migration:
       weight: 0          # <-- EDIT THIS LINE: change to 5
   ```
3. Press `i` to enter insert mode
4. Change `dbConfig.weight` from `5` to `0`
5. Change `migration.weight` from `0` to `5`
6. Press `Esc` then save: `:wq`

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

hooks:
  dbConfig:
    weight: 0
  migration:
    weight: 5
```

The ConfigMap (weight `0`) will now be created before the migration Job (weight `5`).

---

## Step 5: Re-Install and Verify

### Remove the failed release:
```bash
helm uninstall hook-lifecycle-demo
```

The `hook-delete-policy: before-hook-creation` annotation on the hooks ensures stale hook resources are cleaned up on the next install.

### Confirm the corrected hook order:
```bash
helm template hook-lifecycle-demo ./debug-chart | grep hook-weight
```

**Expected output:**
```
    helm.sh/hook-weight: "0"
    helm.sh/hook-weight: "5"
```

ConfigMap hook runs first, migration Job runs second.

### Install the fixed release:
```bash
helm install hook-lifecycle-demo ./debug-chart
```

**Expected output:**
```
NAME: hook-lifecycle-demo
LAST DEPLOYED: ...
NAMESPACE: default
STATUS: deployed
REVISION: 1
```

### Verify hook Jobs completed:
```bash
kubectl get jobs
```

**Expected output:**
```
NAME                COMPLETIONS   DURATION   AGE
hook-demo-migrate   1/1           5s         15s
```

The migration Job completed successfully.

### Verify the application Pod is running:
```bash
kubectl get pods
```

**Expected output:**
```
NAME                                   READY   STATUS      RESTARTS   AGE
hook-demo-migrate-xxxxx                0/1     Completed   0          20s
hook-lifecycle-demo-xxx-yyy            1/1     Running     0          15s
```

The pre-install hooks succeeded, and the main application Pod is `Running`.

### Optional — read migration Job logs to confirm success:
```bash
kubectl logs job/hook-demo-migrate
```

**Expected output:**
```
Applying migration:
CREATE TABLE users (id INT);
```

---

## Instructor Talking Points

### 1. Helm Hooks Run Before (or After) Main Resources
"Helm hooks let you run Jobs, ConfigMaps, or other resources at specific points in the release lifecycle — before install, after install, before delete, and so on. Pre-install hooks must all succeed before Helm creates the main chart resources. If any hook fails, the entire release fails. This is why a misconfigured hook blocks your entire deployment."

### 2. hook-weight Controls Execution Order
"Within the same hook phase, Helm sorts resources by `hook-weight`. Lower numbers run first. Negative weights run before zero. This is how you orchestrate multi-step hook sequences — create a ConfigMap at weight 0, run a migration Job at weight 5, run a validation Job at weight 10. Getting the order wrong causes exactly the failure we saw: a Job referencing a resource that doesn't exist yet."

### 3. hook-delete-policy Prevents Stale Hook Resources
"The `hook-delete-policy` annotation controls what happens to hook resources after they run. Common policies:
- `before-hook-creation` — delete the previous hook resource before creating a new one (essential for retries)
- `hook-succeeded` — delete the hook resource after it succeeds
- `hook-failed` — delete the hook resource after it fails

Without `before-hook-creation`, a failed hook Job can block subsequent install attempts because the resource name already exists."

### 4. Debugging Hook Failures
"The debugging workflow for hook failures is:
1. `helm install --debug` — see which hook phase failed
2. `kubectl get jobs` — find the hook Job
3. `kubectl logs job/<name>` — read the container output
4. If logs are empty, `kubectl describe pod` — the Pod may not have started due to missing dependencies
5. Inspect hook templates for weight, phase, and delete-policy annotations
6. Fix and re-install"

### 5. Real-World Hook Patterns
"In production, pre-install hooks commonly handle:
- Database schema migrations (Flyway, Liquibase, raw SQL)
- Cache warming or seed data loading
- TLS certificate provisioning
- Service account or RBAC setup
- Validation that external dependencies are reachable

The weight ordering pattern — setup at 0, migrate at 5, validate at 10 — appears in most production Helm charts that use hooks."

### 6. Hooks vs Init Containers
"Students sometimes ask: why use a Helm hook instead of an init container? Init containers run on every Pod restart and are tied to a specific Pod. Helm hooks run once per release operation (install, upgrade, delete) and are independent of the application Pod lifecycle. Use hooks for one-time setup like database migrations. Use init containers for per-Pod dependencies like waiting for a service to be ready."

---

## Cleanup

To remove the release:
```bash
helm uninstall hook-lifecycle-demo
```

Or move on to the next section.
