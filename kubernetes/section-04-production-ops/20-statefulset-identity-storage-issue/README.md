# Scenario 20: StatefulSet Identity & Storage Issue

## Interview Problem Statement

> **Interviewer:** "We deployed a StatefulSet with a headless Service for stable network identity, but the headless Service has no Endpoints even though the StatefulSet Pod is Running. Walk me through how you would compare the StatefulSet, Service selector, and PVCs to find the mismatch and fix it."

## Difficulty
⭐⭐ Intermediate — 3 debug commands + manifest edit

## Learning Outcomes
- Use `kubectl describe statefulset` to inspect `serviceName` and volume claims
- Use `kubectl get endpoints` on a headless Service to verify Pod binding
- Compare Service `selector` labels with StatefulSet Pod template labels
- Fix a label selector mismatch on a headless Service

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

## Deploy the Broken State

```bash
cd section-04-production-ops/20-statefulset-identity-storage-issue
kubectl apply -f deployment.yaml
```

## Expected Behavior

The StatefulSet Pod is Running but the headless Service has no Endpoints:

```bash
$ kubectl get pods
NAME         READY   STATUS    RESTARTS   AGE
ss-demo-0    1/1     Running   0          30s

$ kubectl get endpoints ss-demo-headless
NAME               ENDPOINTS   AGE
ss-demo-headless   <none>      30s
```

## Debugging & Live Fixing

Follow [DEBUG.md](DEBUG.md) to compare labels and fix the Service selector.

## Estimated Recording Time
- Debugging: 3–4 minutes
- Live editing + verification: 2–3 minutes
- **Total:** ~5–7 minutes

## Notes for Instructors

The headless Service selector uses `app: ss-demo-wrong` but the StatefulSet Pods are labeled `app: ss-demo`. The `serviceName` in the StatefulSet correctly references `ss-demo-headless` — the bug is only in the Service selector.
