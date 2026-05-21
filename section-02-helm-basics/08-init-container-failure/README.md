# Scenario 08: Init Container Failure

## Interview Problem Statement

> **Interviewer:** "A Helm release was deployed and the application Pods are stuck in `Init` state. They never reach the `Running` phase. The chart includes an init container meant to wait for a backend API before starting the main app. Walk me through how you would identify which init container is failing, what the actual error is, and how you would fix it so the application starts correctly."

## Difficulty
⭐⭐ Intermediate — 3 debug commands + 1 chart edit

## Learning Outcomes
- Use `kubectl describe pod` to identify failing init containers
- Use `kubectl logs -c <init-container>` to read init container output
- Understand how Helm templates inject `initContainers` from `values.yaml`
- Fix a broken init container command in `values.yaml`
- Re-install the chart and verify the Pod reaches `Running`

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
cd section-02-helm-basics/08-init-container-failure
helm install init-container-demo ./debug-chart
```

## Expected Behavior

After install, the Pod is created but never becomes `Running`:

```bash
$ kubectl get pods
NAME                                 READY   STATUS       RESTARTS   AGE
init-container-demo-xxx-yyy        0/1     Init:Error   3          45s
```

The init container exits with an error, causing the Pod to be stuck.

## Debugging & Live Fixing

Follow [DEBUG.md](DEBUG.md) for:
- Using `kubectl describe pod` to identify the failing init container
- Using `kubectl logs -c wait-for-api` to see the actual error
- Inspecting the `values.yaml` init container command
- Fixing the wrong hostname in the command
- Re-installing the chart and verifying the Pod becomes `Running`

## Estimated Recording Time
- Debugging: 3–4 minutes
- Live editing + verification: 2–3 minutes
- **Total:** ~5–7 minutes

## Notes for Instructors

### Init Container Failure
The init container runs `nc -z data-api 8080` but `data-api` does not exist. `nc` fails immediately, the container exits with code 1, and Kubernetes restarts it. After a few attempts the Pod shows `Init:Error`.

### Editing Approach
You'll edit `values.yaml` live during recording. The file looks normal — the bug is the wrong hostname in the `initContainer.command` string.

### Testing the Fix
After editing:
```bash
helm uninstall init-container-demo
helm install init-container-demo ./debug-chart
kubectl get pods
```

The Pod should transition to `Running` because the init container command is now a harmless `echo` that always succeeds. In a real cluster, the proper fix would be to correct the service name or ensure the dependency is deployed.