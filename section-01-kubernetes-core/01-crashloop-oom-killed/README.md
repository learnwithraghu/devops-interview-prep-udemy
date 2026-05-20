# Scenario 01: CrashLoopBackOff - OOMKilled

## Description
A Pod gets killed by the kernel due to exceeding its memory limit, causing a CrashLoopBackOff. You'll debug the issue live, identify the memory misconfiguration, and fix it by editing the `deployment.yaml` in real-time.

## Difficulty
⭐ Beginner — 2 debug commands + 1 manifest edit

## Learning Outcomes
- Understand memory limits vs. requests in Kubernetes
- Recognize OOMKilled errors and exit code 137 (SIGKILL)
- Use `kubectl describe pod` and `kubectl logs` to diagnose memory issues
- Edit manifests live and apply changes using `kubectl apply`
- Understand resource constraints on AWS EC2 t3.2xlarge instances

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
cd section-01-kubernetes-core/01-crashloop-oom-killed
kubectl apply -f deployment.yaml
```

## Expected Behavior

The Pod will start and immediately be killed with status `OOMKilled`, then enter `CrashLoopBackOff`:

```bash
$ kubectl get pods
NAME                        READY   STATUS             RESTARTS   AGE
oom-demo-xxx-yyy           0/1     CrashLoopBackOff   3          45s

$ kubectl describe pod oom-demo-xxx-yyy
...
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    137
```

## Debugging & Live Fixing

Follow [DEBUG.md](DEBUG.md) for:
- Step-by-step debugging commands
- Vim/sed editor tricks to fix the issue
- How to identify and edit the problem lines
- Applying the fix and verifying it works

## Estimated Recording Time
- Debugging: 3–4 minutes
- Live editing + verification: 2–3 minutes
- **Total:** ~5–7 minutes

## Notes for Instructors

### Resource Headroom on AWS EC2
- t3.2xlarge has 32 GB RAM
- kind control-plane uses ~2-4 GB  
- This scenario uses <500 MB after fix
- Plenty of headroom for multiple scenarios per instance

### Editing Approach
You'll edit `deployment.yaml` live during recording. The file includes:
- Clear comments marking the problem area
- `❌` and `✅` symbols to highlight issues vs. fixes
- Both broken and fixed versions (commented) for reference

### Testing the Fix
After editing, simply:
```bash
kubectl apply -f deployment.yaml
watch kubectl get pods
```

The Pod should transition to `Running` status within seconds.
