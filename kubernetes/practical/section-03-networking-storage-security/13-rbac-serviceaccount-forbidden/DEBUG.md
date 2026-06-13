# Debugging Guide: RBAC ServiceAccount Forbidden

## Quick Start Checklist

- [ ] Cluster running on EC2: `kubectl get nodes`
- [ ] Manifest deployed: `kubectl apply -f deployment.yaml`
- [ ] Ready to debug: Pod Running but API calls return Forbidden

---

## Step 1: Observe the Broken State

### Deploy the broken version:
```bash
cd section-03-networking-storage-security/13-rbac-serviceaccount-forbidden
kubectl apply -f deployment.yaml
```

### Check the Pod is running:
```bash
kubectl get pods
```

**Expected output:**
```
NAME                          READY   STATUS    RESTARTS   AGE
rbac-demo-xxxxx               1/1     Running   0          15s
```

The Pod itself is healthy. The problem is API authorization.

### Test API access from inside the Pod:
```bash
kubectl exec rbac-demo-xxxxx -- kubectl get pods
```

Copy the pod name from the previous step.

**Expected output:**
```
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:default:rbac-demo-sa" cannot list resource "pods" in API group "" in the namespace "default"
```

The ServiceAccount `rbac-demo-sa` does not have permission to list Pods.

---

## Step 2: Check Permissions with auth can-i

### List all permissions for the ServiceAccount:
```bash
kubectl auth can-i --list --as=system:serviceaccount:default:rbac-demo-sa
```

**Expected output:**
```
Resources  Non-Resource URLs  Resource Names  Verbs
```

The output is empty — the ServiceAccount has no permissions at all.

### Confirm the specific action is denied:
```bash
kubectl auth can-i list pods --as=system:serviceaccount:default:rbac-demo-sa
```

**Expected output:**
```
no
```

---

## Step 3: Inspect the Role and RoleBinding

### Read the Role:
```bash
kubectl get role rbac-demo-role -o yaml
```

**Expected output (rules section):**
```yaml
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
```

The Role itself is correct — it grants `get` and `list` on Pods.

### Read the RoleBinding:
```bash
kubectl get rolebinding rbac-demo-binding -o yaml
```

**Expected output (subjects section):**
```yaml
subjects:
- kind: ServiceAccount
  name: rbac-demo
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: rbac-demo-role
```

The RoleBinding references ServiceAccount `rbac-demo`, but the Pod uses `rbac-demo-sa`.

### Confirm the Pod's ServiceAccount:
```bash
kubectl get pod rbac-demo-xxxxx -o jsonpath='{.spec.serviceAccountName}'
```

**Expected output:**
```
rbac-demo-sa
```

The Pod uses `rbac-demo-sa`, but the RoleBinding grants permissions to `rbac-demo`. The names do not match.

---

## Step 4: Verify the ServiceAccount Exists

### List ServiceAccounts:
```bash
kubectl get serviceaccount
```

**Expected output:**
```
NAME           SECRETS   AGE
default        0         10m
rbac-demo-sa   0         2m
```

ServiceAccount `rbac-demo-sa` exists. There is no ServiceAccount named `rbac-demo`.

---

## Root Cause Analysis

By now you've seen:
- Pod uses `serviceAccountName: rbac-demo-sa`
- `auth can-i` shows no permissions for `rbac-demo-sa`
- Role `rbac-demo-role` correctly grants `list pods`
- RoleBinding `rbac-demo-binding` binds the Role to ServiceAccount `rbac-demo` (wrong name)

**What happens:**
1. The Pod runs as ServiceAccount `rbac-demo-sa`
2. The Role grants list/get on Pods
3. The RoleBinding connects the Role to ServiceAccount `rbac-demo` — a different name
4. ServiceAccount `rbac-demo-sa` has no RoleBinding → no permissions
5. API calls return `403 Forbidden`

---

## The Fix: Correct the RoleBinding Subject

### Edit deployment.yaml:
```bash
vim deployment.yaml
```

1. Search for the RoleBinding section: `/RoleBinding`
2. Navigate to the subject name line:
   ```yaml
     name: rbac-demo              # <-- EDIT THIS LINE: change to rbac-demo-sa
   ```
3. Press `i` to enter insert mode
4. Change `rbac-demo` to `rbac-demo-sa`
5. Press `Esc` then save: `:wq`

Verify the RoleBinding section now looks like this:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: rbac-demo-binding
subjects:
  - kind: ServiceAccount
    name: rbac-demo-sa
    namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: rbac-demo-role
```

---

## Step 5: Apply and Verify

### Apply the fixed manifest:
```bash
kubectl apply -f deployment.yaml
```

### Verify permissions are now granted:
```bash
kubectl auth can-i list pods --as=system:serviceaccount:default:rbac-demo-sa
```

**Expected output:**
```
yes
```

### Test from inside the Pod:
```bash
kubectl exec rbac-demo-xxxxx -- kubectl get pods
```

**Expected output:**
```
NAME                          READY   STATUS    RESTARTS   AGE
rbac-demo-xxxxx               1/1     Running   0          5m
```

Success! The ServiceAccount can now list Pods.

---

## Instructor Talking Points

### 1. auth can-i Is Your RBAC Debugger
"`kubectl auth can-i --list --as=system:serviceaccount:<namespace>:<name>` shows you exactly what a ServiceAccount can do. When you get a Forbidden error, run this first. If the list is empty, the ServiceAccount has no bindings — don't bother checking the Role until you verify the binding chain."

### 2. The Permission Chain Has Three Links
"RBAC requires three things to connect: a Role (defines permissions), a RoleBinding (connects Role to subject), and the Pod's `serviceAccountName` (identifies the subject). A typo in any link breaks the chain. The Role can be perfect and still useless if the binding points to the wrong ServiceAccount."

### 3. Subject Namespace Matters Too
"In this scenario the namespace matches, but in production I frequently see RoleBindings in namespace A referencing a ServiceAccount in namespace B without specifying the correct namespace in `subjects`. Always verify both `name` and `namespace` in the binding match the Pod's ServiceAccount."

### 4. Roles vs ClusterRoles
"A Role is namespace-scoped. A ClusterRole can be namespace-scoped (via RoleBinding) or cluster-scoped (via ClusterRoleBinding). For listing Pods in one namespace, a Role is appropriate. For cluster-wide access, you'd need a ClusterRole and ClusterRoleBinding."

### 5. Real-World RBAC Failures
"This exact bug — RoleBinding subject name mismatch — happens when:
- Someone renames a ServiceAccount but forgets to update the binding
- Helm chart generates different names for SA and binding
- Copy-paste from another namespace leaves the old SA name
- CI/CD applies Role and RoleBinding from different templates

The debugging workflow is always: auth can-i → Role → RoleBinding → Pod serviceAccountName."

---

## Cleanup

To remove all resources:
```bash
kubectl delete -f deployment.yaml
```

Or move on to the next scenario.
