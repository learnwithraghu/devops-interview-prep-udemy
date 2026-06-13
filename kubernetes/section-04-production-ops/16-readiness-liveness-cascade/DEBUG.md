# Debugging Guide: Readiness / Liveness Cascade Failure

## Quick Start Checklist

- [ ] Cluster running on EC2: `kubectl get nodes`
- [ ] Image built: `docker images | grep k8s-debug-app`
- [ ] Manifest deployed: `kubectl apply -f deployment.yaml`
- [ ] Ready to debug: Service has no Endpoints

---

## Step 1: Observe the Broken State

### Deploy the broken version:
```bash
cd section-04-production-ops/16-readiness-liveness-cascade
kubectl apply -f deployment.yaml
```

### Check the Service Endpoints:
```bash
kubectl get endpoints cascade-demo
```

**Expected output:**
```
NAME           ENDPOINTS   AGE
cascade-demo   <none>      30s
```

The Service has zero backends — this is why users see 502 errors.

### Check the Pods:
```bash
kubectl get pods
```

**Expected output:**
```
NAME                            READY   STATUS             RESTARTS   AGE
cascade-demo-xxxxx              0/1     Running            0          60s
db-demo-yyyyy                   0/1     CrashLoopBackOff   3          60s
```

The app Pod is Running but not Ready (`0/1`). The DB Pod is crashlooping.

---

## Step 2: Describe the App Pod

### Inspect probe status:
```bash
kubectl describe pod cascade-demo-xxxxx
```

Copy the pod name from the previous step.

**Expected output (Conditions section):**
```
Conditions:
  Type           Status
  Ready          False
```

**Expected output (Readiness section):**
```
Readiness:  exec [sh -c wget -q -O- http://db-demo:8080/health || exit 1]
```

**Expected output (Events section):**
```
Warning  Unhealthy  ...  Readiness probe failed: ...
```

The readiness probe is failing. Kubernetes will not add this Pod to Service Endpoints until readiness passes.

---

## Step 3: Check App Logs

### Read the app container logs:
```bash
kubectl logs cascade-demo-xxxxx
```

The app itself may be running fine — the readiness probe failure is what matters. The probe tries to reach the DB before marking the Pod Ready.

---

## Step 4: Investigate the DB Dependency

### Check the DB Pod:
```bash
kubectl get pods -l app=db-demo
kubectl describe pod db-demo-yyyyy
```

**Expected output (Events):**
```
Warning  BackOff  ...  Back-off restarting failed container db
```

### Read DB logs:
```bash
kubectl logs db-demo-yyyyy
```

**Expected output:**
```
ERROR FAIL_START is true, exiting immediately with code 1
```

The DB container exits immediately because `FAIL_START=true`.

### Check DB Service Endpoints:
```bash
kubectl get endpoints db-demo
```

**Expected output:**
```
NAME      ENDPOINTS   AGE
db-demo   <none>      60s
```

The DB Service also has no Endpoints because the DB Pod never stays Running.

---

## Root Cause Analysis

The failure chain:
1. DB Deployment has `FAIL_START=true` → DB Pod crashloops
2. DB Service has no Endpoints → DB is unreachable
3. App readiness probe checks `http://db-demo:8080/health` → fails
4. App Pod stays Not Ready → removed from Service Endpoints
5. App Service has no Endpoints → 502 errors for users

The root cause is the DB Deployment, not the app probes themselves.

---

## The Fix: Repair the DB Deployment

### Edit deployment.yaml:
```bash
vim deployment.yaml
```

1. Search for the DB Deployment: `/name: db-demo`
2. Navigate to the FAIL_START env var:
   ```yaml
             - name: FAIL_START
               value: "true"          # <-- EDIT THIS LINE: change to "false"
   ```
3. Press `i` to enter insert mode
4. Change `"true"` to `"false"`
5. Press `Esc` then save: `:wq`

Alternatively, delete the entire `FAIL_START` env block — the default is `"false"`.

---

## Step 5: Apply and Verify

### Apply the fixed manifest:
```bash
kubectl apply -f deployment.yaml
```

### Wait for the DB Pod to recover:
```bash
kubectl get pods -w
```

**Expected output:**
```
db-demo-yyyyy                   1/1     Running   0          30s
cascade-demo-xxxxx              1/1     Running   0          90s
```

The DB Pod becomes Running first. Then the app readiness probe succeeds and the app Pod becomes Ready.

### Verify Service Endpoints are restored:
```bash
kubectl get endpoints cascade-demo
```

**Expected output:**
```
NAME           ENDPOINTS          AGE
cascade-demo   10.244.0.5:8080    5m
```

Success! Traffic can now reach the application.

---

## Instructor Talking Points

### 1. Empty Endpoints → Check Readiness First
"When a Service has no Endpoints but the Pod shows Running, the readiness probe is failing. Running ≠ Ready. Kubernetes only routes traffic to Ready Pods."

### 2. Readiness Probes Can Create Cascade Failures
"A readiness probe that checks a dependency creates a cascade: if the dependency is down, the app is removed from the Service even though the app container itself is healthy. This is correct behavior — you don't want to serve traffic from an app that can't reach its database."

### 3. Follow the Dependency Chain
"Don't stop at the first failing Pod. The app readiness probe tells you WHAT is failing (DB health check). The DB Pod logs tell you WHY (FAIL_START=true). Always trace one level deeper."

### 4. Readiness vs Liveness
"Readiness removes the Pod from the Service. Liveness restarts the Pod. In this scenario, the app liveness probe on `/health` passes — only readiness fails. If you had only a liveness probe, the Pod would stay in the Service and serve 502s."

---

## Cleanup

```bash
kubectl delete -f deployment.yaml
```
