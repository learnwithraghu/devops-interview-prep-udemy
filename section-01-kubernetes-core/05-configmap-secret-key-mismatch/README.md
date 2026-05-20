# Scenario 05: ConfigMap / Secret Key Mismatch

## Interview Problem Statement

> **Interviewer:** "We updated a Deployment to load configuration from a ConfigMap instead of hardcoding values. Now the Pod is stuck in `CreateContainerConfigError` and won't start at all. Before this change, the same container image started fine. You have the combined manifest. Walk me through how you would figure out what's preventing the container from starting and what you would change to fix it."

## Difficulty
⭐⭐⭐ Advanced — 4–5 debug commands + manifest edit

## Learning Outcomes
- Understand how Kubernetes validates ConfigMap and Secret key references before starting a container
- Read `kubectl describe pod` events to find `CreateContainerConfigError` details
- Inspect ConfigMap keys with `kubectl get configmap -o yaml`
- Correlate Deployment `env.valueFrom.configMapKeyRef.key` with actual ConfigMap `data` keys
- Fix key name mismatches in volume mounts or environment variable references
- Understand the difference between missing ConfigMaps and missing keys within them

## Prerequisites

### AWS EC2 Environment
- **Instance Type:** t3.2xlarge or larger  
- **Storage:** 30 GB (gp3 recommended)
- **OS:** Amazon Linux 2 or 2023
- **Setup:** Run `sudo bash setup.sh` from `course-admin/` directory

### Docker Image Built
```bash
cd course-admin
make build DOCKER_HUB_USER=local
```

Verify the image exists:
```bash
docker images | grep k8s-debug-app
```

## Deploy the Broken State

```bash
cd section-01-kubernetes-core/05-configmap-secret-key-mismatch
kubectl apply -f deployment.yaml
```

## Expected Behavior

The ConfigMap will be created successfully, but the Pod will be stuck in `CreateContainerConfigError`:

```bash
$ kubectl get pods
NAME                          READY   STATUS                       RESTARTS   AGE
config-demo-xxx-yyy          0/1     CreateContainerConfigError   0          15s

$ kubectl describe pod config-demo-xxx-yyy
...
Events:
  Warning  Failed     5s    kubelet            Error: couldn't find key db-url in ConfigMap default/app-config
```

## Debugging & Live Fixing

Follow [DEBUG.md](DEBUG.md) for:
- Step-by-step debugging commands
- How to inspect ConfigMap keys vs. Deployment references
- Vim/sed editor tricks to fix the key mismatch
- Applying the fix and verifying the pod starts

## Estimated Recording Time
- Debugging: 5–7 minutes
- Live editing + verification: 2–3 minutes
- **Total:** ~7–10 minutes

## Notes for Instructors

### Resource Headroom on AWS EC2
- t3.2xlarge has 32 GB RAM
- kind control-plane uses ~2-4 GB  
- This scenario uses minimal resources (<100 MB)
- Plenty of headroom for multiple scenarios per instance

### Editing Approach
You'll edit `deployment.yaml` live during recording. The file contains both the ConfigMap and the Deployment separated by `---`. The file looks like a normal manifest with no visible hints.

### Testing the Fix
After editing, simply:
```bash
kubectl apply -f deployment.yaml
watch kubectl get pods
```

The Pod should transition to `Running` status within seconds.
