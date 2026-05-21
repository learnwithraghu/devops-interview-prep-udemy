# Scenario 12: PVC Stuck Pending

## Interview Problem Statement

> **Interviewer:** "We deployed an application that mounts a PersistentVolumeClaim for data storage. The Pod has been stuck in `Pending` state for several minutes and never schedules. The cluster is running normally otherwise. Walk me through how you would diagnose why the PVC is not binding and how you would fix it."

## Difficulty
⭐ Beginner — 2 debug commands + manifest edit

## Learning Outcomes
- Use `kubectl describe pvc` to read PersistentVolumeClaim events
- Use `kubectl get storageclass` to see available StorageClasses
- Understand how `storageClassName` controls PVC provisioning
- Fix a non-existent StorageClass reference in a manifest

## Prerequisites

### AWS EC2 Environment
- **Instance Type:** t3.2xlarge or larger  
- **Storage:** 30 GB (gp3 recommended)
- **OS:** Amazon Linux 2 or 2023
- **Setup:** Run `sudo bash setup.sh` from `course-admin/` directory

This creates a kind cluster named `course-admin` on the EC2 instance with the course app image pre-loaded.

### Docker Image Built
```bash
cd course-admin
make build DOCKER_HUB_USER=local
```

## Deploy the Broken State

```bash
cd section-03-networking-storage-security/12-pvc-storageclass-missing
kubectl apply -f deployment.yaml
```

## Expected Behavior

The PVC stays Pending and the Pod cannot schedule:

```bash
$ kubectl get pvc
NAME            STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-demo-data   Pending                                      fast-ssd       30s

$ kubectl get pods
NAME                        READY   STATUS    RESTARTS   AGE
pvc-demo-xxxxx              0/1     Pending   0          30s
```

## Debugging & Live Fixing

Follow [DEBUG.md](DEBUG.md) for:
- Using `kubectl describe pvc` to read provisioning events
- Listing available StorageClasses with `kubectl get storageclass`
- Fixing the `storageClassName` in the manifest
- Verifying the PVC binds and the Pod starts

## Estimated Recording Time
- Debugging: 2–3 minutes
- Live editing + verification: 2 minutes
- **Total:** ~4–5 minutes

## Notes for Instructors

### kind Default StorageClass
The kind cluster from `setup.sh` provides a default StorageClass named `standard`. The broken manifest references `fast-ssd`, which does not exist.

### Editing Approach
You'll edit the PVC section in `deployment.yaml` live during recording. Change `storageClassName: fast-ssd` to `storageClassName: standard`.

### Testing the Fix
After editing:
```bash
kubectl apply -f deployment.yaml
kubectl get pvc
kubectl get pods
```

The PVC should reach `Bound` and the Pod should reach `Running`.
