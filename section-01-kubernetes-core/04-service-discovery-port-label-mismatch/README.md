# Scenario 04: Service Discovery - Port & Label Mismatch

## Interview Problem Statement

> **Interviewer:** "We deployed an application with a Kubernetes Service in front of it. From inside the cluster, requests to the Service's ClusterIP hang and eventually time out. `kubectl get endpoints` shows the Service has no endpoints at all, even though the Pod is Running and ready. You have the combined manifest file. Walk me through how you would systematically debug this and what you would change to make the Service reachable."

## Difficulty
⭐⭐⭐ Advanced — 5 debug commands + manifest edit

## Learning Outcomes
- Understand how Kubernetes Services route traffic to Pods via Endpoints
- Use `kubectl get endpoints` to verify Service-to-Pod binding
- Correlate Service `selector` labels with Pod labels
- Verify `targetPort` in the Service matches the container's `containerPort`
- Use a temporary debug Pod to test connectivity inside the cluster
- Fix multiple correlated misconfigurations in a single manifest

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
cd section-01-kubernetes-core/04-service-discovery-port-label-mismatch
kubectl apply -f deployment.yaml
```

## Expected Behavior

The Pod will start and show `Running`, but the Service will have zero endpoints:

```bash
$ kubectl get pods
NAME                       READY   STATUS    RESTARTS   AGE
svc-demo-xxx-yyy          1/1     Running   0          30s

$ kubectl get endpoints svc-demo
NAME       ENDPOINTS   AGE
svc-demo   <none>      30s
```

Even after fixing labels, a curl from a debug Pod to the Service ClusterIP on port 80 will fail because the targetPort is also wrong.

## Debugging & Live Fixing

Follow [DEBUG.md](DEBUG.md) for:
- Step-by-step debugging commands across multiple resources
- How to verify Endpoints, selectors, and ports
- Running a temporary debug Pod to test cluster connectivity
- Fixing both the label selector and the port mismatch

## Estimated Recording Time
- Debugging: 6–8 minutes
- Live editing + verification: 3–4 minutes
- **Total:** ~9–12 minutes

## Notes for Instructors

### Resource Headroom on AWS EC2
- t3.2xlarge has 32 GB RAM
- kind control-plane uses ~2-4 GB  
- This scenario uses minimal resources (<100 MB)
- Plenty of headroom for multiple scenarios per instance

### Editing Approach
You'll edit `deployment.yaml` live during recording. The file contains both the Deployment and the Service separated by `---`. The file looks like a normal manifest with no visible hints.

### Testing the Fix
After editing, simply:
```bash
kubectl apply -f deployment.yaml
kubectl get endpoints svc-demo
kubectl run debug --rm -it --image=busybox -- wget -O- http://svc-demo
```

The Service should show endpoints and the wget should return a response.
