# Scenario 17: ResourceQuota & LimitRange Denial

## Interview Problem Statement

> **Interviewer:** "We deployed an application into a namespace with resource quotas, but only one of two expected Pods is running. The second Pod is stuck in Pending. Walk me through how you would identify the quota constraint and fix the deployment so all replicas schedule."

## Difficulty
⭐⭐ Intermediate — 3 debug commands + manifest edit

## Learning Outcomes
- Use `kubectl describe resourcequota` to read namespace quota limits
- Use `kubectl describe pod` to see quota-related scheduling failures
- Sum existing resource usage against quota limits
- Fix a Deployment whose replica count or resource requests exceed the quota

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
cd section-04-production-ops/17-resourcequota-limitrange-denial
kubectl apply -f deployment.yaml
```

## Expected Behavior

Only one Pod schedules; the second stays Pending:

```bash
$ kubectl get pods -n quota-demo
NAME                          READY   STATUS    RESTARTS   AGE
quota-demo-xxxxx              1/1     Running   0          30s
quota-demo-yyyyy              0/1     Pending   0          30s
```

## Debugging & Live Fixing

Follow [DEBUG.md](DEBUG.md) for quota inspection and the fix.

## Estimated Recording Time
- Debugging: 3–4 minutes
- Live editing + verification: 2–3 minutes
- **Total:** ~5–7 minutes

## Notes for Instructors

The namespace quota allows `500m` CPU total. Each Pod requests `500m`, so only one Pod fits. Fix by reducing replicas to `1` or lowering CPU requests to `250m`.
