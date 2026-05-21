# Scenario 10: Helm Hook Lifecycle Failure

## Interview Problem Statement

> **Interviewer:** "A Helm release fails during install and never reaches a deployed state. The chart uses pre-install hooks to prepare database configuration and run migrations before the main application starts. The install hangs or errors out during the hook phase. Walk me through how you would diagnose the failing hook, understand the hook execution order, and fix the chart so the release installs successfully."

## Difficulty
⭐⭐ Intermediate — 3 debug commands + 1 chart edit

## Learning Outcomes
- Use `helm install --debug` to observe hook execution during install
- Use `kubectl get jobs` to find failing pre-install hook Jobs
- Use `kubectl logs job/<name>` to read hook container output
- Understand Helm hook execution order via `hook-weight`
- Fix hook ordering by adjusting weights in `values.yaml`
- Understand `hook-delete-policy` for clean hook retries

## Prerequisites

### AWS EC2 Environment
- **Instance Type:** t3.2xlarge or larger  
- **Storage:** 30 GB (gp3 recommended)
- **OS:** Amazon Linux 2 or 2023
- **Setup:** Run `sudo bash setup.sh` from `course-admin/` directory

### Helm Installed
```bash
helm version
```

### Docker Image Built
```bash
cd course-admin
make build DOCKER_HUB_USER=local
```

## Deploy the Broken State

```bash
cd section-02-helm-basics/10-helm-hook-lifecycle-failure
helm install hook-lifecycle-demo ./debug-chart --debug
```

The install fails during the pre-install hook phase because the migration Job runs before the ConfigMap it depends on is created.

## Expected Behavior

After install, Helm reports a hook failure and the release does not reach `deployed` status:

```bash
$ helm install hook-lifecycle-demo ./debug-chart --debug
...
Error: INSTALLATION FAILED: pre-install hooks failed: 1 error occurred:
        * job hook-demo-migrate failed: ...
```

```bash
$ kubectl get jobs
NAME                COMPLETIONS   DURATION   AGE
hook-demo-migrate   0/1           30s        30s

$ helm list
NAME                NAMESPACE  REVISION  STATUS
hook-lifecycle-demo default    1         failed
```

The main application Deployment is never created because pre-install hooks must succeed first.

## Debugging & Live Fixing

Follow [DEBUG.md](DEBUG.md) for:
- Using `helm install --debug` to see hook execution output
- Finding the failed hook Job with `kubectl get jobs`
- Reading hook logs with `kubectl logs job/hook-demo-migrate`
- Inspecting hook weights in `values.yaml`
- Fixing the weight ordering so ConfigMap is created before the migration Job
- Re-installing and verifying the release reaches `deployed`

## Estimated Recording Time
- Hook debugging: 3–4 minutes
- Weight fix + verification: 2–3 minutes
- **Total:** ~5–7 minutes

## Notes for Instructors

### Hook Weight Ordering
Helm runs hooks with lower `hook-weight` values first. In the broken state, the migration Job has weight `0` and the ConfigMap has weight `5`, so the Job runs first and fails because the ConfigMap does not exist yet.

### Two Pre-Install Hooks
The chart has two pre-install hooks:
1. **ConfigMap** (`hook-demo-db-config`) — provides migration SQL
2. **Job** (`hook-demo-migrate`) — reads the ConfigMap and applies the migration

The fix is to swap the weights so the ConfigMap (weight `0`) is created before the migration Job (weight `5`).

### Editing Approach
You'll edit `values.yaml` live during recording. The file looks like a normal values file with no visible hints about hook ordering.

### Testing the Fix
After editing:
```bash
helm uninstall hook-lifecycle-demo
helm install hook-lifecycle-demo ./debug-chart
kubectl get pods
```

The hook Jobs should complete and the application Pod should reach `Running`.
