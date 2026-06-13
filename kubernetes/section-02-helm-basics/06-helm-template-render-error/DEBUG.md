# Debugging Guide: Helm Template Rendering Error

## Quick Start Checklist

- [ ] Helm installed: `helm version`
- [ ] Chart directory present: `ls debug-chart/`
- [ ] Ready to debug: `helm install` fails with a template error

---

## Step 1: Observe the Broken State

### Try to install the chart:
```bash
helm install helm-template-demo ./debug-chart
```

**Expected output:**
```
Error: template: debug-chart/templates/deployment.yaml:22:28: executing "debug-chart/templates/deployment.yaml" at <.Values.app.logLevel>: nil pointer evaluating interface {}.logLevel
```

Helm fails before creating anything. No Kubernetes resources exist yet.

---

## Step 2: Run helm lint

### Check for chart-level issues:
```bash
helm lint ./debug-chart
```

**Expected output:**
```
==> Linting debug-chart
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```

`helm lint` passes because the chart structure is valid — the issue is a runtime template rendering error, not a structural chart problem.

---

## Step 3: Run helm template --debug

### Render templates locally to see the exact failure:
```bash
helm template --debug helm-template-demo ./debug-chart
```

**Expected output (last lines):**
```
install.go:200: [debug] Original chart version: ""
install.go:217: [debug] CHART PATH: /path/to/debug-chart

Error: template: debug-chart/templates/deployment.yaml:22:28: executing "debug-chart/templates/deployment.yaml" at <.Values.app.logLevel>: nil pointer evaluating interface {}.logLevel
helm.go:84: [debug] template: debug-chart/templates/deployment.yaml:22:28: executing "debug-chart/templates/deployment.yaml" at <.Values.app.logLevel>: nil pointer evaluating interface {}.logLevel
```

### Key information from the error:
- **File:** `debug-chart/templates/deployment.yaml`
- **Line:** `22`
- **Column:** `28`
- **Expression:** `.Values.app.logLevel`
- **Error type:** `nil pointer evaluating interface {}.logLevel`

This means Helm tried to access `.Values.app.logLevel`, but `.Values.app` does not exist (is `nil`), so it cannot read `.logLevel` from it.

---

## Step 4: Inspect values.yaml

### Read the values file:
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

There is **no `app:` section** and therefore **no `logLevel` key** under it.

---

## Step 5: Inspect the Template

### Open the failing template to confirm the reference:
```bash
cat debug-chart/templates/deployment.yaml
```

**Expected output (line 20–23):**
```yaml
          env:
            - name: LOG_LEVEL
              value: {{ .Values.app.logLevel }}
```

The template at line 22 references `.Values.app.logLevel`, but `values.yaml` does not define `app` or `logLevel`.

---

## Root Cause Analysis

By now you've seen:
- `helm install` fails with a template rendering error
- `helm template --debug` pinpoints the exact file and line
- The error message says `.Values.app.logLevel` is a nil pointer
- `values.yaml` has no `app:` section at all

The issue is a missing key in `values.yaml`:

```yaml
# Missing from values.yaml:
app:
  logLevel: info
```

**What happens:**
1. Helm reads `values.yaml`
2. It renders `templates/deployment.yaml`
3. At line 22, it evaluates `{{ .Values.app.logLevel }}`
4. `.Values.app` is `nil` (not defined)
5. Helm cannot evaluate `.logLevel` on `nil`
6. Rendering aborts with a nil pointer error

---

## The Fix: Add the Missing Value

### Edit values.yaml:
```bash
vim debug-chart/values.yaml
```

1. Jump to the end of the file: `G`
2. Press `i` to enter insert mode
3. Add the missing section after the existing `service:` block:
   ```yaml
   app:
     logLevel: info     # <-- THIS IS THE LINE YOU ARE ADDING
   ```
4. Press `Esc` then save: `:wq`

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

app:
  logLevel: info
```

---

## Step 6: Verify the Fix

### Run helm template again to confirm rendering succeeds:
```bash
helm template helm-template-demo ./debug-chart
```

**Expected output:**
```yaml
---
# Source: debug-chart/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helm-template-demo
...
          env:
            - name: LOG_LEVEL
              value: info
```

The template now renders successfully and the value is populated.

### Install the chart:
```bash
helm install helm-template-demo ./debug-chart
```

**Expected output:**
```
NAME: helm-template-demo
LAST DEPLOYED: ...
NAMESPACE: default
STATUS: deployed
REVISION: 1
```

### Verify the pod is running:
```bash
kubectl get pods
```

**Expected output:**
```
NAME                               READY   STATUS    RESTARTS   AGE
helm-template-demo-xxx-yyy      1/1     Running   0          10s
```

Success! The chart installs cleanly.

---

## Instructor Talking Points

### 1. helm lint vs. helm template --debug
"`helm lint` checks chart structure — valid YAML, required fields in Chart.yaml, schema compatibility. It does NOT evaluate template expressions. Many broken charts pass `helm lint` with flying colors. `helm template --debug` is where you actually render the templates and catch nil pointers, typos in value references, and syntax errors in Go template expressions. Always run `helm template` as a smoke test before `helm install`."

### 2. Reading the Error Message
"Helm template errors look intimidating, but they contain everything you need:
- The **file path** — which template is broken
- The **line and column** — exactly where to look
- The **expression** — what was being evaluated
- The **error type** — `nil pointer` means a missing parent key, `not a dict` means wrong type, `function not defined` means a typo in a function name

Train yourself to parse these four pieces before googling."

### 3. Why Not Use `default` or `required`?
"In production, you often see:
```yaml
value: {{ .Values.app.logLevel | default \"info\" }}
```
or
```yaml
value: {{ required \"app.logLevel is required\" .Values.app.logLevel }}
```

Both are valid patterns, but they solve different problems:
- **`default`** — Silently uses a fallback. Good for optional settings.
- **`required`** — Fails with a custom message. Good for mandatory values.
- **Direct reference** — Fails with a raw nil pointer. Acceptable during development.

In this scenario, the simplest fix is adding the key to `values.yaml`. In an interview, mentioning all three options shows deep Helm knowledge."

### 4. Real-World Impact
"Template rendering errors usually happen because:
- A chart was cloned and its `values.yaml` wasn't updated for the new environment
- A subchart added a new required value, but the parent chart's `values.yaml` wasn't updated
- CI/CD passes `--set` flags that override a parent key, making child keys nil
- A developer renamed a key in `values.yaml` but forgot to update the template reference

The key discipline is: every key accessed in a template should either exist in `values.yaml` or be guarded with `default`/`required`/ `if`."

### 5. No Cluster Impact
"Notice that because Helm failed at the template rendering stage, **nothing was created in Kubernetes**. There are no Pods to debug, no Services to delete, no rollbacks needed. This is a pre-flight failure. Fix the chart locally, verify with `helm template`, then install cleanly. This is why `helm template` is your best friend in CI pipelines — catch errors before they touch the cluster."

---

## Cleanup

To remove the release after successful install:
```bash
helm uninstall helm-template-demo
```

Or move on to the next scenario.
