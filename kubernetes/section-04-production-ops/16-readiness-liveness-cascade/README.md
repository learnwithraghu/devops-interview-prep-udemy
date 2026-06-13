# Scenario 16: Readiness / Liveness Cascade Failure

## Interview Problem Statement

> **Interviewer:** "Users report 502 errors from our application Service. The app Deployment looks like it should be running, but the Service has no healthy backends. Walk me through how you would trace this from the Service back to the Pod probes, find the root cause, and restore traffic."

## Difficulty
⭐⭐⭐ Advanced — 5 debug commands + manifest edit

## Learning Outcomes
- Trace a Service outage from empty Endpoints back to failing readiness probes
- Use `kubectl describe pod` to inspect readiness and liveness probe status
- Follow a cascade failure from app → DB dependency
- Distinguish between readiness failures (removed from Service) and liveness failures (restart)
- Fix the root cause by repairing a broken dependency Deployment

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
cd section-04-production-ops/16-readiness-liveness-cascade
kubectl apply -f deployment.yaml
```

## Expected Behavior

The app Pod runs but never becomes Ready, and the Service has no endpoints:

```bash
$ kubectl get pods
NAME                            READY   STATUS    RESTARTS   AGE
cascade-demo-xxxxx              0/1     Running   0          60s
db-demo-yyyyy                   0/1     CrashLoopBackOff   3   60s

$ kubectl get endpoints cascade-demo
NAME           ENDPOINTS   AGE
cascade-demo   <none>      60s
```

## Debugging & Live Fixing

Follow [DEBUG.md](DEBUG.md) for the full cascade: Service → Endpoints → readiness probe → DB dependency → fix.

## Estimated Recording Time
- Debugging: 6–8 minutes
- Live editing + verification: 3–4 minutes
- **Total:** ~9–12 minutes

## Notes for Instructors

The DB Deployment has `FAIL_START=true`, causing it to crash immediately. The app Deployment's readiness probe checks `db-demo:8080/health` and fails, keeping the app out of Service Endpoints.

The fix is in the DB Deployment — remove or set `FAIL_START` to `"false"`.
