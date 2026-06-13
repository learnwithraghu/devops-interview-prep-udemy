# Debugging Guide: ConfigMap / Secret Key Mismatch

## Quick Start Checklist

- [ ] Cluster running: `kubectl get nodes`
- [ ] Image built: `docker images | grep k8s-debug-app`
- [ ] Deployment deployed: `kubectl get pods`
- [ ] Ready to debug: Pod shows `CreateContainerConfigError`

---

## Step 1: Observe the Broken State

### Deploy the broken version:
```bash
kubectl apply -f deployment.yaml
```

### Check the Pod status:
```bash
kubectl get pods
```

**Expected output:**
```
NAME                          READY   STATUS                       RESTARTS   AGE
config-demo-xxxxx            0/1     CreateContainerConfigError   0          15s
```

Notice the Pod is NOT in `Pending` or `CrashLoopBackOff` — it's in `CreateContainerConfigError`. This is a distinct state that tells us Kubernetes couldn't create the container due to a configuration problem.

---

## Step 2: Describe the Pod (Find the Config Error)

### Run describe with the pod name:
```bash
kubectl describe pod config-demo-xxxxx
```

### Look at the **Events** section at the bottom:

**Expected output:**
```
Events:
  Type     Reason     Age   From               Message
  ----     ------     ----  ----               -------
  Warning  Failed     5s    kubelet            Error: couldn't find key db-url in ConfigMap default/app-config
```

### Key indicators:
- **`CreateContainerConfigError`** — The kubelet couldn't build the container spec
- **`couldn't find key db-url`** — The Deployment referenced a key called `db-url` that doesn't exist in the ConfigMap
- **`ConfigMap default/app-config`** — The name and namespace of the ConfigMap being used

This single event tells us exactly what's wrong.

---

## Step 3: Inspect the ConfigMap

### Get the ConfigMap in YAML format:
```bash
kubectl get configmap app-config -o yaml
```

**Expected output:**
```yaml
apiVersion: v1
data:
  database-url: "postgres://db:5432/app"
kind: ConfigMap
metadata:
  name: app-config
  namespace: default
```

### Compare the keys:
- ConfigMap has key: **`database-url`**
- Deployment is looking for: **`db-url`**

They are different. That's the mismatch.

---

## Root Cause Analysis

By now you've seen:
- Pod stuck in `CreateContainerConfigError`
- `describe` shows `couldn't find key db-url in ConfigMap default/app-config`
- ConfigMap actually contains the key `database-url`, not `db-url`

The issue is in `deployment.yaml`:

```yaml
env:
  - name: DATABASE_URL
    valueFrom:
      configMapKeyRef:
        name: app-config
        key: db-url           # ❌ WRONG: ConfigMap has "database-url", not "db-url"
```

**What happens:**
1. Pod is created
2. kubelet tries to build the container environment
3. It looks up `db-url` in ConfigMap `app-config`
4. The key doesn't exist
5. kubelet refuses to start the container
6. Pod stays in `CreateContainerConfigError`

---

## Step 4: The Fix — Correct the Key Name

You need to change one line in the Deployment's env section.

### Edit the manifest:
```bash
vim deployment.yaml
```

1. Search for the problem key: `/db-url`
2. Navigate to the line:
   ```yaml
         key: db-url    # <-- EDIT THIS LINE: change to database-url
   ```
3. Press `i` to enter insert mode
4. Change `db-url` to `database-url`
5. Press `Esc` then save: `:wq`

Verify:
```bash
grep "database-url" deployment.yaml
```

---

## Step 5: Apply the Fix

### Apply the corrected manifest:
```bash
kubectl apply -f deployment.yaml
```

**Expected output:**
```
configmap/app-config unchanged
deployment.apps/config-demo configured
```

---

## Step 6: Verify the Fix

### Watch the Pod status:
```bash
kubectl get pods -w
```

**Expected output:**
```
NAME                          READY   STATUS            RESTARTS   AGE
config-demo-xxxxx            0/1     Pending           0          0s
config-demo-xxxxx            0/1     ContainerCreating 0          2s
config-demo-xxxxx            1/1     Running           0          5s
```

Once it shows `1/1 Running`, exit with `Ctrl+C`.

### Confirm the environment variable is populated:
```bash
kubectl exec config-demo-xxxxx -- printenv DATABASE_URL
```

**Expected output:**
```
postgres://db:5432/app
```

### Check the logs to confirm the app started:
```bash
kubectl logs config-demo-xxxxx
```

**Expected output:**
```
2026-05-20T14:35:12Z [INFO] Starting server...
2026-05-20T14:35:12Z [INFO] Server starting on 0.0.0.0:8080
```

Success! The ConfigMap key is now correctly referenced.

---

## Instructor Talking Points

### 1. CreateContainerConfigError vs. CrashLoopBackOff
"`CreateContainerConfigError` is fundamentally different from `CrashLoopBackOff`:
- **CrashLoopBackOff** — The container started but the process inside exited. The manifest is valid, the application is broken.
- **CreateContainerConfigError** — Kubernetes itself couldn't construct the container. The manifest references something invalid — a missing ConfigMap key, a missing Secret, an invalid subPath. The container never got a chance to run.

Recognizing which state a Pod is in tells you where to look first."

### 2. Kubernetes Validates References at Runtime
"Unlike some systems that lazily resolve config, Kubernetes validates ConfigMap and Secret references when the Pod is scheduled. If a key is missing, the Pod is blocked immediately. This is a safety feature — it prevents containers from starting with partially loaded configuration and failing in subtle ways later."

### 3. Common Causes of Key Mismatches
"In production, this usually happens because:
- A ConfigMap was updated and a key was renamed, but the Deployment wasn't updated
- A chart generates ConfigMap keys from template variables, but the Deployment template uses hardcoded names
- Someone manually edited a ConfigMap with `kubectl edit configmap` and changed a key name
- Different environments (dev/staging/prod) have ConfigMaps with slightly different key names

The fix is never to add `optional: true` to hide the error — it's to align the key names."

### 4. Volume Mount Key Mismatches
"The same principle applies to volume mounts. If you mount a ConfigMap as a volume with `items` mapping and specify a `key` that doesn't exist, you get a similar error. Or if you mount without `items`, the filenames in the mount are the ConfigMap keys — if your app expects `config.yaml` but the key is `app.conf`, the app can't find its file. Always verify keys match between source and consumer."

### 5. Secrets Behave Identically
"This scenario uses a ConfigMap, but Secrets behave the same way. A `secretKeyRef` with a missing key produces the exact same `CreateContainerConfigError` event. The debug flow is identical: `describe pod` → identify the missing key → `get secret -o yaml` → compare → fix.

In interviews, always mention that ConfigMaps and Secrets share the same validation behavior."

### 6. Multi-Step Deductive Reasoning
"This is an advanced scenario because it requires correlating three separate objects:
1. The Pod's status (`CreateContainerConfigError`)
2. The Pod's env reference (`key: db-url`)
3. The ConfigMap's actual keys (`database-url`)

The error message from `kubectl describe` is very explicit, but only if you know to look at Events. Junior engineers often stare at `kubectl logs` for a container that hasn't even started yet."

---

## Cleanup

To remove the deployment and configmap:
```bash
kubectl delete -f deployment.yaml
```

Or let them run and move to the next scenario.
