# Debugging Guide: Helm Upgrade & Rollback

## Quick Start Checklist

- [ ] Helm installed: `helm version`
- [ ] Chart directory present: `ls debug-chart/`
- [ ] Good revision installed (rev 1): `helm list`
- [ ] Broken revision applied (rev 2): `helm history`
- [ ] Ready to debug: Pods show `ImagePullBackOff`

---

## Step 1: Observe the Broken State

### Verify the release exists:
```bash
helm list
```

**Expected output:**
```
NAME              	NAMESPACE	REVISION	UPDATED                	STATUS  	CHART            	APP VERSION
helm-upgrade-demo	default  	2       	...                    	failed  	debug-chart-0.1.0	
```

### Check the Pod status:
```bash
kubectl get pods
```

**Expected output:**
```
NAME                                 READY   STATUS             RESTARTS   AGE
helm-upgrade-demo-xxx-yyy           0/1     ImagePullBackOff   0          30s
```

The upgrade broke the release. The Pod can't pull the image.

---

## Step 2: Inspect Release History

### View all revisions:
```bash
helm history helm-upgrade-demo
```

**Expected output:**
```
REVISION	UPDATED                  	STATUS      	CHART            	APP VERSION	DESCRIPTION
1       	...	deployed    	debug-chart-0.1.0	          	Install complete
2       	...	superseded  	debug-chart-0.1.0	          	Upgrade complete
```

We see:
- **Revision 1** — The original install (deployed)
- **Revision 2** — The upgrade that broke things (superseded or failed)

---

## Step 3: Compare Values Between Revisions

### Get values from the working revision:
```bash
helm get values helm-upgrade-demo --revision 1
```

**Expected output:**
```yaml
image:
  tag: v1
```

### Get values from the broken revision:
```bash
helm get values helm-upgrade-demo --revision 2
```

**Expected output:**
```yaml
image:
  pullPolicy: Never
  repository: local/k8s-debug-app
  tag: v2-broken
```

### Compare:
- Revision 1 has `image.tag: v1` (working)
- Revision 2 has `image.tag: v2-broken` (broken)

The upgrade changed the image tag to a version that doesn't exist.

---

## Step 4: Quick Recovery — Rollback

### Roll back to revision 1:
```bash
helm rollback helm-upgrade-demo 1
```

**Expected output:**
```
Rollback was a success! Happy Helming!
```

### Verify the Pods recover:
```bash
kubectl get pods
```

**Expected output:**
```
NAME                                 READY   STATUS    RESTARTS   AGE
helm-upgrade-demo-xxx-yyy           1/1     Running   0          10s
```

Service is restored. But the chart files on disk still have the bad value.

---

## Step 5: Inspect values.yaml On Disk

### Read the current chart values:
```bash
cat debug-chart/values.yaml
```

**Expected output:**
```yaml
replicaCount: 1

image:
  repository: local/k8s-debug-app
  tag: v2-broken
  pullPolicy: Never
```

The `tag: v2-broken` is the root cause. This file was used for the broken upgrade.

---

## Root Cause Analysis

By now you've seen:
- Revision 1 used `image.tag: v1` and worked
- Revision 2 used `image.tag: v2-broken` and failed with ImagePullBackOff
- `values.yaml` on disk still contains `tag: v2-broken`

**What happens:**
1. Good install with `--set image.tag=v1` (revision 1)
2. Upgrade using `values.yaml` which has `tag: v2-broken` (revision 2)
3. Kubernetes tries to pull `local/k8s-debug-app:v2-broken`
4. Image does not exist → `ImagePullBackOff`
5. Rollback restores revision 1's manifest
6. But `values.yaml` is still broken — next upgrade will fail again

---

## The Fix: Correct values.yaml

### Edit values.yaml:
```bash
vim debug-chart/values.yaml
```

1. Search for the bad tag: `/v2-broken`
2. Navigate to the line:
   ```yaml
     tag: v2-broken     # <-- EDIT THIS LINE: change to v1
   ```
3. Press `i` to enter insert mode
4. Change `v2-broken` to `v1`
5. Press `Esc` then save: `:wq`

Verify the file now looks like this:
```yaml
replicaCount: 1

image:
  repository: local/k8s-debug-app
  tag: v1
  pullPolicy: Never

service:
  type: ClusterIP
  port: 8080
```

---

## Step 6: Re-Upgrade Safely

### Run the upgrade with fixed values:
```bash
helm upgrade helm-upgrade-demo ./debug-chart
```

**Expected output:**
```
Release "helm-upgrade-demo" has been upgraded. Happy Helming!
```

### Verify the new revision:
```bash
helm history helm-upgrade-demo
```

**Expected output:**
```
REVISION	UPDATED                  	STATUS      	CHART            	APP VERSION	DESCRIPTION
1       	...	deployed    	debug-chart-0.1.0	          	Install complete
2       	...	superseded  	debug-chart-0.1.0	          	Upgrade complete
3       	...	deployed    	debug-chart-0.1.0	          	Rollback to 1
4       	...	deployed    	debug-chart-0.1.0	          	Upgrade complete
```

Notice:
- Revision 3 was the rollback
- Revision 4 is the new, safe upgrade

### Verify the Pod is running:
```bash
kubectl get pods
```

**Expected output:**
```
NAME                                 READY   STATUS    RESTARTS   AGE
helm-upgrade-demo-xxx-yyy           1/1     Running   0          10s
```

Success! The upgrade now works because the underlying values are correct.

---

## Instructor Talking Points

### 1. helm rollback is a Temporary Band-Aid
"Rollback restores the previous Kubernetes manifest, but it does NOT change the chart files on disk. If you rollback and walk away, the next person who runs `helm upgrade` will hit the exact same failure. The proper workflow is: rollback to restore service, fix the root cause in the chart, then re-upgrade."

### 2. helm history and helm get values
"`helm history` shows you the timeline of changes. `helm get values --revision N` shows you exactly what values were used for any revision. This is incredibly powerful for debugging. In a production incident, comparing `helm get values --revision <last-known-good>` against `helm get values --revision <current>` often reveals the smoking gun in seconds."

### 3. Revision Semantics in Helm 3
"Helm 3 stores release metadata as Secrets in the same namespace. Every install, upgrade, and rollback creates a new Secret. Rollback doesn't delete the bad revision — it creates a new revision that is a copy of the old one. This means you can roll forward to a previously broken revision if you ever need to. The revision number always increments; nothing is ever truly lost."

### 4. Real-World Incident Response
"In a real on-call situation, the priority is:
1. **Restore service** — `helm rollback` (30 seconds)
2. **Investigate** — `helm history` + `helm get values` (2 minutes)
3. **Fix root cause** — Edit chart values (5 minutes)
4. **Re-deploy safely** — `helm upgrade` with fixed values (2 minutes)

Never skip step 3. Rolling back without fixing the underlying issue just delays the next outage."

### 5. Image Tag Mismatches in CI/CD
"In production, this exact failure mode happens when:
- CI/CD pushes a new image tag but the chart's `values.yaml` still references the old one
- A developer manually edits `values.yaml` with a tag that hasn't been built yet
- A Helm `--set` override in a pipeline shadows the wrong value
- Different environments (dev/staging/prod) have different image registries and tags get out of sync

Best practice: image tags should be set explicitly during install/upgrade, not hardcoded in `values.yaml` for production releases."

### 6. Advanced Pattern: helm diff
"Before upgrading in production, many teams use `helm diff upgrade` to preview changes:
```bash
helm diff upgrade helm-upgrade-demo ./debug-chart
```

This shows exactly what Kubernetes resources will change before you apply them. If you see the image tag changing unexpectedly, you can catch it before the upgrade breaks anything."

---

## Cleanup

To remove the release:
```bash
helm uninstall helm-upgrade-demo
```

Or move on to the next scenario.
