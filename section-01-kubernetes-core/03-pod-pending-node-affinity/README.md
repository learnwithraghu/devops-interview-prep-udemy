# Scenario 03: Pod Stuck Pending - Node Affinity

## Interview Problem Statement

> **Interviewer:** "We deployed a new service to our Kubernetes cluster, but the Pod has been sitting in `Pending` for over five minutes and never transitions to `Running`. There are no image pull errors and the cluster has plenty of CPU and memory available. You have the `deployment.yaml` and cluster access. Walk me through how you would figure out why it won't schedule and how you'd fix it."

## Difficulty
⭐⭐ Intermediate — 3 debug commands + 1 manifest or node edit

## Learning Outcomes
- Understand how the Kubernetes scheduler makes placement decisions
- Use `kubectl describe pod` to read scheduler events and failure messages
- Inspect node labels with `kubectl get nodes --show-labels`
- Fix scheduling constraints by either adding node labels or relaxing pod requirements
- Understand the difference between `nodeSelector`, `nodeAffinity`, and `tolerations`

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
cd section-01-kubernetes-core/03-pod-pending-node-affinity
kubectl apply -f deployment.yaml
```

## Expected Behavior

The Pod will be created but remain in `Pending` indefinitely:

```bash
$ kubectl get pods
NAME                            READY   STATUS    RESTARTS   AGE
affinity-demo-xxx-yyy          0/1     Pending   0          5m

$ kubectl describe pod affinity-demo-xxx-yyy
...
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  10s   default-scheduler  0/1 nodes are available: 1 node(s) didn't match Pod's node affinity/selector.
```

## Debugging & Live Fixing

Follow [DEBUG.md](DEBUG.md) for:
- Step-by-step debugging commands
- Vim/sed editor tricks to fix the issue
- How to identify and edit the problem lines
- Applying the fix and verifying it works

## Estimated Recording Time
- Debugging: 4–5 minutes
- Live editing + verification: 2–3 minutes
- **Total:** ~6–8 minutes

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
