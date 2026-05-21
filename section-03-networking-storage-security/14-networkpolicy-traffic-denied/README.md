# Scenario 14: NetworkPolicy Traffic Denial

## Interview Problem Statement

> **Interviewer:** "We deployed an application with a Service and a NetworkPolicy to restrict traffic. The Pod is Running and the Service has Endpoints, but other Pods in the cluster cannot reach the application — connections time out. Walk me through how you would inspect the NetworkPolicy and fix the traffic rules so legitimate clients can connect."

## Difficulty
⭐⭐ Intermediate — 3 debug commands + manifest edit

## Learning Outcomes
- Use `kubectl get networkpolicy` and `kubectl describe networkpolicy` to inspect rules
- Test connectivity from a debug Pod using `wget` or `curl`
- Understand NetworkPolicy `ingress` and `egress` `from` / `to` selectors
- Fix a namespace or pod selector that blocks legitimate traffic

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
cd section-03-networking-storage-security/14-networkpolicy-traffic-denied
kubectl apply -f deployment.yaml
```

## Expected Behavior

The app Pod is healthy but unreachable from other Pods:

```bash
$ kubectl get pods
NAME                            READY   STATUS    RESTARTS   AGE
netpol-demo-xxxxx               1/1     Running   0          30s

$ kubectl get endpoints netpol-demo
NAME          ENDPOINTS          AGE
netpol-demo   10.244.0.5:8080    30s

$ kubectl run debug --rm -it --image=busybox --restart=Never -- wget -O- -T 3 http://netpol-demo:8080
wget: download timed out
```

## Debugging & Live Fixing

Follow [DEBUG.md](DEBUG.md) for:
- Inspecting the NetworkPolicy ingress rules
- Testing connectivity from a debug Pod
- Identifying the namespace selector that blocks traffic
- Fixing the NetworkPolicy to allow traffic from the default namespace

## Estimated Recording Time
- Debugging: 3–4 minutes
- Live editing + verification: 2–3 minutes
- **Total:** ~5–7 minutes

## Notes for Instructors

### Default-Deny Ingress
Once a NetworkPolicy selects a Pod and defines ingress rules, only explicitly allowed traffic is permitted. The broken policy only allows traffic from the `kube-system` namespace, blocking the debug Pod in `default`.

### Editing Approach
You'll edit the NetworkPolicy section in `deployment.yaml` live during recording. Change the `namespaceSelector` to allow traffic from the `default` namespace.

### Testing the Fix
After editing:
```bash
kubectl apply -f deployment.yaml
kubectl run debug --rm -it --image=busybox --restart=Never -- wget -O- http://netpol-demo:8080
```

The wget should return a successful HTTP response.
