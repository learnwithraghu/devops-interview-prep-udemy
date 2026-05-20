# Scenario 02: CrashLoopBackOff - Wrong Command

## Interview Problem Statement

> **Interviewer:** "A developer deployed a new version of an application using a Kubernetes Deployment. The Pod is stuck in `CrashLoopBackOff` and the container exits immediately on startup. The developer is insisting the container image is fine because it runs perfectly with `docker run` on their laptop. You have the `deployment.yaml` and cluster access. How would you troubleshoot this, and what would you change to fix it?"

## Difficulty
⭐ Beginner — 2 debug commands + 1 manifest edit

## Learning Outcomes
- Understand how `command` and `args` override a container's default entrypoint
- Recognize exit code 127 (command not found)
- Use `kubectl describe pod` and `kubectl logs` to diagnose startup failures
- Edit manifests live and apply changes using `kubectl apply`
- Know when to override vs. rely on the image's built-in `ENTRYPOINT`

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
cd section-01-kubernetes-core/02-crashloop-wrong-command
kubectl apply -f deployment.yaml
```

## Expected Behavior

The Pod will start and immediately crash with status `Error`, then enter `CrashLoopBackOff`:

```bash
$ kubectl get pods
NAME                        READY   STATUS             RESTARTS   AGE
wrong-cmd-demo-xxx-yyy     0/1     CrashLoopBackOff   3          45s

$ kubectl describe pod wrong-cmd-demo-xxx-yyy
...
    Last State:     Terminated
      Reason:       Error
      Exit Code:    127
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
- This scenario uses minimal resources (<100 MB)
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
