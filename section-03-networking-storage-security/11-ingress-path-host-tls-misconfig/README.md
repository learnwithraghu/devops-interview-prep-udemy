# Scenario 11: Ingress Misconfiguration

## Interview Problem Statement

> **Interviewer:** "We deployed an application with a Service and an Ingress in front of it. The Pod is Running and healthy, but users get 404 or 502 errors when accessing the app through the Ingress URL at `https://app.demo.local`. Direct cluster-internal access to the Service works fine. Walk me through how you would debug the Ingress configuration and get external traffic routing correctly."

## Difficulty
⭐⭐⭐ Advanced — 5 debug commands + manifest edit

## Learning Outcomes
- Use `kubectl get ingress` and `kubectl describe ingress` to inspect routing rules
- Correlate Ingress `rules`, `paths`, and `tls` blocks with actual cluster state
- Verify TLS Secrets exist and match the names referenced in the Ingress
- Check that backend Services have healthy Endpoints before blaming the Ingress
- Read Ingress controller logs (Traefik/Nginx) for routing errors
- Fix path, port, and TLS secret mismatches in an Ingress manifest

## Prerequisites

### AWS EC2 Environment
- **Instance Type:** t3.2xlarge or larger  
- **Storage:** 30 GB (gp3 recommended)
- **OS:** Amazon Linux 2 or 2023
- **Security Group:** Allow inbound ports 8080 (app), 6443 (Kubernetes API), 80 and 443 (Ingress)
- **Setup:** Run `sudo bash setup.sh` from `course-admin/` directory

This creates a kind cluster named `course-admin` on the EC2 instance with the course app image pre-loaded.

### Ingress Controller (One-Time Setup)
The kind cluster from `setup.sh` does not include an Ingress controller. Install Nginx Ingress once on the EC2 instance:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### Docker Image Built
```bash
cd course-admin
make build DOCKER_HUB_USER=local
```

## Deploy the Broken State

```bash
cd section-03-networking-storage-security/11-ingress-path-host-tls-misconfig
kubectl apply -f deployment.yaml
```

## Expected Behavior

The Pod and Service are healthy, but Ingress routing fails:

```bash
$ kubectl get pods
NAME                            READY   STATUS    RESTARTS   AGE
ingress-demo-xxx-yyy            1/1     Running   0          30s

$ kubectl get endpoints ingress-demo
NAME           ENDPOINTS          AGE
ingress-demo   10.244.0.5:8080    30s

$ curl -k -H "Host: app.demo.local" https://localhost/
404 Not Found
```

Run the curl from the EC2 instance (where kind is running). The `-H "Host: app.demo.local"` header routes the request to the correct Ingress rule — no `/etc/hosts` changes needed.

Internal Service access works, but the Ingress returns errors.

## Debugging & Live Fixing

Follow [DEBUG.md](DEBUG.md) for:
- Inspecting Ingress rules, paths, and TLS configuration
- Verifying the TLS Secret exists and matches the Ingress reference
- Confirming the backend Service has Endpoints
- Reading Ingress controller logs for routing errors
- Fixing the path, backend port, and TLS secret name in the manifest

## Estimated Recording Time
- Debugging: 6–8 minutes
- Live editing + verification: 3–4 minutes
- **Total:** ~9–12 minutes

## Notes for Instructors

### Backend Is Healthy
Unlike Service discovery scenarios, the Pod labels, Service selector, and Endpoints are all correct. The bug is entirely in the Ingress layer — wrong path, wrong backend port, and wrong TLS secret name.

### EC2 Testing
All commands run on the EC2 instance via SSH. Use `curl -H "Host: app.demo.local"` to hit the Ingress without modifying `/etc/hosts`. The Host header simulates what a real DNS entry for `app.demo.local` would send.

### Editing Approach
You'll edit `deployment.yaml` live during recording. The file contains Deployment, Service, TLS Secret, and Ingress separated by `---`. The Ingress section is where all fixes live.

### Testing the Fix
After editing:
```bash
kubectl apply -f deployment.yaml
curl -k -H "Host: app.demo.local" https://localhost/
```

The curl should return a successful HTTP response from the debug app.
