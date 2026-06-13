# Scenario 07: Helm Upgrade & Rollback

## Interview Problem Statement

> **Interviewer:** "A team upgraded a Helm release to deploy a new version of an application. After the upgrade, the application stopped working and the Pods are failing to start. The previous version was running fine just minutes ago. You have access to the Helm release, the chart directory, and the cluster. Walk me through how you would restore service quickly, identify what changed between the working and broken versions, and then permanently fix the issue so you can upgrade safely."

## Difficulty
⭐⭐⭐ Advanced — 5 debug/Helm commands + manifest edit + rollback

## Learning Outcomes
- Use `helm history` to inspect release revisions
- Use `helm get values` to compare configuration between revisions
- Perform a `helm rollback` to restore a working state quickly
- Understand the difference between `helm rollback` and `helm upgrade`
- Fix the root cause in `values.yaml` and re-upgrade safely
- Understand release revision semantics in Helm 3

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

This scenario requires two steps to reach the broken state:

### Step 1: Install the good revision
```bash
cd section-02-helm-basics/07-helm-upgrade-rollback
helm install helm-upgrade-demo ./debug-chart --set image.tag=v1
```

Verify the Pod is running:
```bash
kubectl get pods
```

### Step 2: Upgrade to the broken revision
```bash
helm upgrade helm-upgrade-demo ./debug-chart
```

The `values.yaml` in the chart now references a non-existent image tag, so the upgrade will break the release.

## Expected Behavior

After the upgrade, the Pods will enter `ImagePullBackOff`:

```bash
$ kubectl get pods
NAME                                 READY   STATUS             RESTARTS   AGE
helm-upgrade-demo-xxx-yyy           0/1     ImagePullBackOff   0          30s

$ helm history helm-upgrade-demo
REVISION	UPDATED                  	STATUS      	CHART            	APP VERSION	DESCRIPTION
1       	...	deployed    	debug-chart-0.1.0	          	Install complete
2       	...	superseded  	debug-chart-0.1.0	          	Upgrade complete
```

## Debugging & Live Fixing

Follow [DEBUG.md](DEBUG.md) for:
- Using `helm history` and `helm get values` to compare revisions
- Rolling back to the working revision
- Identifying the bad value in `values.yaml`
- Fixing the value and re-upgrading safely

## Estimated Recording Time
- Debugging and rollback: 5–7 minutes
- Root cause fix + re-upgrade: 2–3 minutes
- **Total:** ~7–10 minutes

## Notes for Instructors

### Two-Phase Deployment
Unlike other scenarios, this one requires a good install followed by a bad upgrade. The `values.yaml` in the chart is intentionally in the broken state.

### Rollback is Temporary
`helm rollback` restores the previous Kubernetes manifest but does NOT modify the chart files on disk. After rollback, you must still fix `values.yaml` to prevent the same breakage on the next upgrade.

### Editing Approach
You'll edit `values.yaml` live during recording. The file looks like a normal values file with no visible hints.

### Testing the Fix
After editing:
```bash
helm upgrade helm-upgrade-demo ./debug-chart
kubectl get pods
```

The Pod should transition to `Running`.
