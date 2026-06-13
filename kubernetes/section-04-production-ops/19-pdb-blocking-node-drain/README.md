# Scenario 19: PDB Blocking Node Drain

## Interview Problem Statement

> **Interviewer:** "We need to drain a worker node for maintenance, but `kubectl drain` fails saying it would violate a PodDisruptionBudget. The application must stay available during the maintenance window. Walk me through how you would identify the PDB constraint and safely proceed with the drain."

## Difficulty
⭐⭐⭐ Advanced — 5 debug commands + manifest edit

## Learning Outcomes
- Use `kubectl drain` and interpret PDB violation errors
- Use `kubectl get pdb` and `kubectl describe pdb` to inspect disruption budgets
- Correlate PDB `minAvailable` with Deployment replica count
- Safely adjust PDB or scale the Deployment for maintenance
- Understand the node drain workflow in production

## Prerequisites

### AWS EC2 Environment
- **Instance Type:** t3.2xlarge or larger  
- **Storage:** 30 GB (gp3 recommended)
- **OS:** Amazon Linux 2 or 2023

### Two-Node kind Cluster Required
This scenario requires a 2-node cluster. The single-node cluster from `setup.sh` cannot demonstrate drain meaningfully.

```bash
cd course-admin
make build DOCKER_HUB_USER=local
kind delete cluster --name course-admin
kind create cluster --name course-admin --config ../section-04-production-ops/19-pdb-blocking-node-drain/kind-config.yaml
kind load docker-image local/k8s-debug-app:v1 --name course-admin
```

### Docker Image Built
```bash
cd course-admin
make build DOCKER_HUB_USER=local
```

## Deploy the Broken State

```bash
cd section-04-production-ops/19-pdb-blocking-node-drain
kubectl apply -f deployment.yaml
```

Ensure Pods are spread across nodes:
```bash
kubectl get pods -o wide
```

## Expected Behavior

Draining the worker node fails:

```bash
$ kubectl drain course-admin-worker --ignore-daemonsets --delete-emptydir-data
...
Cannot evict pod pdb-demo-xxxxx: Would violate PodDisruptionBudget "pdb-demo"
```

## Debugging & Live Fixing

Follow [DEBUG.md](DEBUG.md) for the full drain → PDB → fix → retry workflow.

## Estimated Recording Time
- Debugging and drain attempt: 5–7 minutes
- PDB fix + successful drain: 3–4 minutes
- **Total:** ~8–11 minutes

## Notes for Instructors

The PDB requires `minAvailable: 2` but the Deployment has only `2` replicas. Draining a node that runs one of the two Pods would drop below the minimum. Fix by scaling to 3 replicas or lowering `minAvailable` to `1`.

After the scenario, recreate the default single-node cluster if needed for other scenarios.
