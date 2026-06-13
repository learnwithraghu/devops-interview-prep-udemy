# Debugging Guide: Helm Subchart Dependency Hell

## Quick Start Checklist

- [ ] Helm installed: `helm version`
- [ ] Chart directory present: `ls debug-chart/`
- [ ] Subchart source present: `ls app-component/`
- [ ] Install fails with missing dependency: `helm install subchart-demo ./debug-chart`
- [ ] Ready to debug

---

## Step 1: Observe the Install Failure

### Attempt to install the release:
```bash
cd section-02-helm-basics/09-helm-subchart-dependency-hell
helm install subchart-demo ./debug-chart
```

**Expected output:**
```
Error: INSTALLATION FAILED: found in Chart.yaml, but missing in charts/ directory: app-component
```

Helm refuses to install because `Chart.yaml` declares a dependency on `app-component`, but no vendored subchart archive exists in `charts/`.

---

## Step 2: List Dependencies

### Check dependency status:
```bash
helm dependency list ./debug-chart
```

**Expected output:**
```
NAME         	VERSION	REPOSITORY             	STATUS 
app-component	0.2.0  	file://../app-component	missing
```

This tells us:
- The umbrella chart expects `app-component` version `0.2.0`
- The dependency is sourced from a local path (`file://../app-component`)
- Status is `missing` — nothing is vendored in `charts/`

---

## Step 3: Compare Chart.yaml and Chart.lock

### Read the declared dependency:
```bash
cat debug-chart/Chart.yaml
```

**Expected output (dependencies section):**
```yaml
dependencies:
  - name: app-component
    version: 0.2.0
    repository: file://../app-component
```

### Read the lock file:
```bash
cat debug-chart/Chart.lock
```

**Expected output:**
```yaml
dependencies:
- name: app-component
  repository: file://../app-component
  version: 0.1.0
```

### Compare:
- `Chart.yaml` requires version **0.2.0**
- `Chart.lock` is pinned to version **0.1.0**

The lock file is stale. Someone bumped the dependency version in `Chart.yaml` but never ran `helm dependency update`.

### Inspect the charts directory:
```bash
ls debug-chart/charts/
```

**Expected output:**
```
(empty — no .tgz files)
```

The `charts/` folder should contain vendored subchart archives (e.g., `app-component-0.2.0.tgz`). It is empty, which is why Helm reports the dependency as missing. This commonly happens when `.tgz` files are gitignored and a teammate clones the repo without running `helm dependency update`.

---

## Step 4: Vendor the Dependencies

### Update and download subchart dependencies:
```bash
helm dependency update ./debug-chart
```

**Expected output:**
```
Saving 1 charts
Deleting outdated charts
```

### Verify the charts directory is populated:
```bash
ls debug-chart/charts/
```

**Expected output:**
```
app-component-0.2.0.tgz
```

### Confirm dependency status is now ok:
```bash
helm dependency list ./debug-chart
```

**Expected output:**
```
NAME         	VERSION	REPOSITORY             	STATUS
app-component	0.2.0  	file://../app-component	ok    
```

---

## Step 5: Install and Observe the Second Failure

### Install the release now that dependencies are vendored:
```bash
helm install subchart-demo ./debug-chart
```

**Expected output:**
```
NAME: subchart-demo
LAST DEPLOYED: ...
NAMESPACE: default
STATUS: deployed
REVISION: 1
```

The install succeeds, but the application may not be healthy.

### Check the Pod status:
```bash
kubectl get pods
```

**Expected output:**
```
NAME                             READY   STATUS             RESTARTS   AGE
subchart-demo-xxx-yyy            0/1     ImagePullBackOff   0          30s
```

The Pod cannot pull its container image. The dependency issue is fixed, but something is still wrong with the configuration.

### Describe the Pod:
```bash
kubectl describe pod <pod-name>
```

Copy the pod name from the previous `kubectl get pods` output.

**Expected output (Events section):**
```
  Warning  Failed     ...  Failed to pull image "local/k8s-debug-app:missing-tag": ...
  Warning  Failed     ...  Error: ErrImagePull
```

The image tag is `missing-tag`, not the `v1` tag defined in the parent chart's `values.yaml`.

---

## Step 6: Template Debug — Verify Subchart Values

### Render the chart and inspect the subchart output:
```bash
helm template subchart-demo ./debug-chart --debug
```

Scroll through the rendered YAML and find the Deployment from the subchart. Look for the `image:` line.

**Expected output (subchart Deployment section):**
```yaml
          image: "local/k8s-debug-app:missing-tag"
          imagePullPolicy: Never
```

The subchart is using its **default** tag (`missing-tag`), not the `v1` tag from the parent `values.yaml`.

### Read the parent values file:
```bash
cat debug-chart/values.yaml
```

**Expected output:**
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

These values are at the **top level** of the parent chart. They configure the umbrella chart itself, not the subchart.

### Read the subchart defaults:
```bash
cat app-component/values.yaml
```

**Expected output:**
```yaml
replicaCount: 1

image:
  repository: local/k8s-debug-app
  tag: missing-tag
  pullPolicy: Never

service:
  type: ClusterIP
  port: 8080
```

The subchart's default tag is `missing-tag`. Since the parent never passed overrides under the correct key, the subchart kept its defaults.

---

## Root Cause Analysis

By now you've seen two separate issues:

**Issue 1 — Missing vendored dependency:**
- `Chart.yaml` declares `app-component` version `0.2.0`
- `Chart.lock` is stale at version `0.1.0`
- `charts/` directory is empty
- `helm install` fails until `helm dependency update` vendors the subchart

**Issue 2 — Wrong values nesting:**
- Parent `values.yaml` sets `image.tag: v1` at the top level
- Helm subchart values must be nested under the subchart's name: `app-component.image.tag`
- The subchart never receives the override and uses its default `missing-tag`
- Pod enters `ImagePullBackOff`

**What happens:**
1. Developer clones the repo; `charts/*.tgz` are not present
2. `helm install` fails with missing dependency
3. After `helm dependency update`, install succeeds
4. Subchart renders with default `missing-tag` because parent values are at wrong nesting level
5. Kubernetes cannot pull `local/k8s-debug-app:missing-tag`
6. Pod stays in `ImagePullBackOff`

---

## The Fix: Correct Subchart Value Nesting

### Edit values.yaml:
```bash
vim debug-chart/values.yaml
```

1. Search for the image block: `/image:`
2. The entire file needs restructuring. Replace the contents with:
   ```yaml
   app-component:
     replicaCount: 1
     image:
       repository: local/k8s-debug-app
       tag: v1                          # <-- EDIT THIS LINE: move under app-component
       pullPolicy: Never
     service:
       type: ClusterIP
       port: 8080
   ```
3. Press `i` to enter insert mode
4. Delete the old top-level keys and paste the nested structure above
5. Press `Esc` then save: `:wq`

Verify the file now looks like this:
```yaml
app-component:
  replicaCount: 1
  image:
    repository: local/k8s-debug-app
    tag: v1
    pullPolicy: Never
  service:
    type: ClusterIP
    port: 8080
```

The key rule: values for a subchart named `app-component` must be nested under `app-component:` in the parent `values.yaml`.

---

## Step 7: Re-Install and Verify

### Uninstall the broken release:
```bash
helm uninstall subchart-demo
```

### Confirm the rendered template uses the correct tag:
```bash
helm template subchart-demo ./debug-chart | grep "image:"
```

**Expected output:**
```
          image: "local/k8s-debug-app:v1"
```

The subchart now receives the correct image tag.

### Install the fixed release:
```bash
helm install subchart-demo ./debug-chart
```

**Expected output:**
```
NAME: subchart-demo
LAST DEPLOYED: ...
NAMESPACE: default
STATUS: deployed
REVISION: 1
```

### Verify the Pod is running:
```bash
kubectl get pods
```

**Expected output:**
```
NAME                             READY   STATUS    RESTARTS   AGE
subchart-demo-xxx-yyy            1/1     Running   0          10s
```

Success! Dependencies are vendored and the subchart receives the correct values.

---

## Instructor Talking Points

### 1. helm dependency list is Your First Stop
"When a Helm chart with subchart dependencies fails to install, `helm dependency list` immediately tells you what's declared, what version is expected, and whether it's actually present. The `missing` status means you forgot to run `helm dependency update` — or your CI pipeline didn't vendor dependencies before packaging."

### 2. Chart.lock vs Chart.yaml Drift
"`Chart.lock` is like a lockfile in other package managers. It pins exact dependency versions. If someone bumps a version in `Chart.yaml` but doesn't regenerate the lock file, you get drift. Always run `helm dependency update` after changing dependency versions, and commit both `Chart.lock` and the vendored `charts/*.tgz` files — or document that teammates must run the update step after cloning."

### 3. Subchart Value Nesting is the #1 Values Mistake
"This is the most common Helm subchart bug in the wild. Values for a subchart named `redis` go under `redis:` in the parent `values.yaml`. Values for `app-component` go under `app-component:`. Top-level keys in the parent chart do NOT automatically flow into subcharts. If you alias a dependency, the key becomes the alias name instead. Always verify with `helm template --debug`."

### 4. helm template --debug Before Every Install
"Before installing an umbrella chart in production, run `helm template --debug` and inspect the rendered output for each subchart. Look at the image tags, replica counts, and resource names. This catches nesting mistakes in seconds — long before Kubernetes tries to pull a nonexistent image."

### 5. Real-World Dependency Hell Patterns
"In production, dependency hell usually looks like:
- Fresh clone → `helm install` fails → missing `charts/` archives
- Upgraded subchart version in `Chart.yaml` → forgot `helm dependency update` → stale lock file
- CI builds the chart but doesn't run `helm dependency build` → packaged chart is incomplete
- Values overrides in ArgoCD/Flux at the wrong nesting level → subchart silently uses defaults
- Dependency aliased as `web` but values still under the original chart name

The debugging workflow is always the same: dependency list → lock file → charts/ folder → template debug → values nesting."

### 6. Umbrella Charts vs Subcharts
"An umbrella chart is a thin wrapper that composes multiple subcharts into one release. The parent chart often has minimal or no templates of its own — it just declares dependencies and passes values. Understanding this separation is critical: the parent's job is dependency management and value routing, not deploying workloads directly."

---

## Cleanup

To remove the release:
```bash
helm uninstall subchart-demo
```

Or move on to the next scenario.
