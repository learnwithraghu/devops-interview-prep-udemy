# Scenario 15: CoreDNS Custom Config Break

## Interview Problem Statement

> **Interviewer:** "After a ConfigMap update, DNS resolution across the cluster stopped working. Pods cannot resolve `kubernetes.default` or any external hostnames. CoreDNS Pods may be running but queries time out or fail. Walk me through how you would diagnose the CoreDNS configuration and restore cluster DNS."

## Difficulty
⭐⭐ Intermediate — 3 debug commands + manifest edit

## Learning Outcomes
- Use `kubectl logs` to inspect CoreDNS Pod output
- Test DNS resolution from a debug Pod with `nslookup`
- Inspect the CoreDNS ConfigMap in `kube-system`
- Identify a broken `forward` directive or missing `kubernetes` plugin
- Fix the Corefile and rollout restart CoreDNS

## Prerequisites

### AWS EC2 Environment
- **Instance Type:** t3.2xlarge or larger  
- **Storage:** 30 GB (gp3 recommended)
- **OS:** Amazon Linux 2 or 2023
- **Setup:** Run `sudo bash setup.sh` from `course-admin/` directory

This creates a kind cluster named `course-admin` on the EC2 instance.

### Important
This scenario modifies the CoreDNS ConfigMap in `kube-system`. Run it on a dedicated training cluster, not production. Restore the fixed ConfigMap before moving to the next scenario.

## Deploy the Broken State

```bash
cd section-03-networking-storage-security/15-coredns-custom-config-break
kubectl apply -f deployment.yaml
kubectl rollout restart deployment/coredns -n kube-system
```

Wait for CoreDNS to restart, then DNS will be broken.

## Expected Behavior

DNS resolution fails cluster-wide:

```bash
$ kubectl run debug --rm -it --image=busybox --restart=Never -- nslookup kubernetes.default
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local
nslookup: can't resolve 'kubernetes.default'
```

## Debugging & Live Fixing

Follow [DEBUG.md](DEBUG.md) for:
- Reading CoreDNS logs for configuration errors
- Testing DNS from a debug Pod
- Inspecting the CoreDNS ConfigMap
- Restoring the valid Corefile with the `kubernetes` plugin
- Rolling out the CoreDNS restart and verifying resolution

## Estimated Recording Time
- Debugging: 3–4 minutes
- Live editing + verification: 3–4 minutes
- **Total:** ~6–8 minutes

## Notes for Instructors

### Cluster-Wide Impact
This scenario intentionally breaks cluster DNS. The broken ConfigMap removes the `kubernetes` plugin and forwards all queries to a dead IP (`192.0.2.1`). Always apply the fix and verify DNS is restored before ending the session.

### Editing Approach
You'll edit the CoreDNS ConfigMap in `deployment.yaml` live during recording. Restore the `kubernetes` plugin block and fix the `forward` directive.

### Testing the Fix
After editing:
```bash
kubectl apply -f deployment.yaml
kubectl rollout restart deployment/coredns -n kube-system
kubectl run debug --rm -it --image=busybox --restart=Never -- nslookup kubernetes.default
```

DNS resolution should succeed.
