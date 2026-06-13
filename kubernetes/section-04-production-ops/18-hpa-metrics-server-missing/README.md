# Scenario 18: HPA Not Scaling

## Interview Problem Statement

> **Interviewer:** "We created a HorizontalPodAutoscaler for our application, but it shows `<unknown>` for current metrics and never scales up under load. The Deployment and HPA look correctly configured. Walk me through how you would diagnose why the HPA cannot read metrics and fix it."

## Difficulty
⭐ Beginner — 2 debug commands + metrics-server install

## Learning Outcomes
- Use `kubectl get hpa` to spot missing metrics (`<unknown>`)
- Verify the metrics-server is running in `kube-system`
- Confirm the Deployment has `resources.requests` defined (required for CPU-based HPA)
- Install or fix metrics-server on a kind cluster

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
cd section-04-production-ops/18-hpa-metrics-server-missing
kubectl apply -f deployment.yaml
```

## Expected Behavior

The HPA exists but cannot read metrics:

```bash
$ kubectl get hpa
NAME       REFERENCE             TARGETS         MINPODS   MAXPODS   REPLICAS
hpa-demo   Deployment/hpa-demo   cpu: <unknown>/50%   1         5         1
```

## Debugging & Live Fixing

Follow [DEBUG.md](DEBUG.md) to install metrics-server and verify the HPA reads CPU metrics.

## Estimated Recording Time
- Debugging: 2–3 minutes
- metrics-server install + verification: 3–4 minutes
- **Total:** ~5–7 minutes

## Notes for Instructors

The kind cluster from `setup.sh` does not include metrics-server by default. The HPA and Deployment are correctly configured — the missing component is metrics-server.
