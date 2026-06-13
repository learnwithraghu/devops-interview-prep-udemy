# Scenario 13: RBAC ServiceAccount Forbidden

## Interview Problem Statement

> **Interviewer:** "We deployed an application that uses a ServiceAccount to list Pods in its namespace. The Pod starts fine, but when the application calls the Kubernetes API it gets `403 Forbidden` errors. Walk me through how you would trace the permission chain from the Pod to the Role and RoleBinding, and fix the access issue."

## Difficulty
⭐⭐⭐ Advanced — 5 debug commands + manifest edit

## Learning Outcomes
- Use `kubectl auth can-i` to test permissions as a ServiceAccount
- Inspect Roles and RoleBindings to trace the permission chain
- Verify RoleBinding `subjects` match the Pod's `serviceAccountName`
- Understand how RBAC grants permissions in Kubernetes
- Fix a subject name mismatch in a RoleBinding

## Prerequisites

### AWS EC2 Environment
- **Instance Type:** t3.2xlarge or larger  
- **Storage:** 30 GB (gp3 recommended)
- **OS:** Amazon Linux 2 or 2023
- **Setup:** Run `sudo bash setup.sh` from `course-admin/` directory

This creates a kind cluster named `course-admin` on the EC2 instance.

## Deploy the Broken State

```bash
cd section-03-networking-storage-security/13-rbac-serviceaccount-forbidden
kubectl apply -f deployment.yaml
```

## Expected Behavior

The Pod runs, but API calls are forbidden:

```bash
$ kubectl get pods
NAME                          READY   STATUS    RESTARTS   AGE
rbac-demo-xxxxx               1/1     Running   0          30s

$ kubectl exec rbac-demo-xxxxx -- kubectl get pods
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:default:rbac-demo-sa" cannot list resource "pods"
```

## Debugging & Live Fixing

Follow [DEBUG.md](DEBUG.md) for:
- Testing permissions with `kubectl auth can-i --list`
- Inspecting the Role, RoleBinding, and ServiceAccount
- Tracing the subject name mismatch in the RoleBinding
- Fixing the RoleBinding and verifying API access

## Estimated Recording Time
- Debugging: 5–7 minutes
- Live editing + verification: 2–3 minutes
- **Total:** ~7–10 minutes

## Notes for Instructors

### Role Is Correct, Binding Is Wrong
The Role grants `get` and `list` on Pods. The RoleBinding references the wrong ServiceAccount name (`rbac-demo` instead of `rbac-demo-sa`). The Pod uses the correct ServiceAccount but the binding does not connect to it.

### Editing Approach
You'll edit the RoleBinding section in `deployment.yaml` live during recording. Change the subject name from `rbac-demo` to `rbac-demo-sa`.

### Testing the Fix
After editing:
```bash
kubectl apply -f deployment.yaml
kubectl exec <pod-name> -- kubectl get pods
```

The command should return the list of Pods successfully.
