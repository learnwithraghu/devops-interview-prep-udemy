# Course Plan: Real-World Kubernetes & Helm Debugging

## Overview
A hands-on video course focused on live scenario-based debugging and hands-on fixing. Every scenario runs on:
- **Local:** Rancher Desktop, Docker Desktop, or Kind (zero cloud dependencies)
- **AWS EC2:** t3.2xlarge instances with Amazon Linux 2 (30 GB storage) — recommended for team training and production-like environments

The course is divided into **4 sections of 5 videos each**, with a deliberate difficulty curve inside every section. The teaching approach emphasizes **live editing** — students watch you identify the issue in YAML files, then use editor tricks (vim, sed, etc.) to fix them in real-time. You'll roll out fixes progressively, showing debugging workflow and deployment strategies.

**Difficulty convention**
- ⭐ **Beginner** — 1 to 2 debug commands to find the root cause.
- ⭐⭐ **Intermediate** — 3 debug commands; requires correlating 2–3 resources.
- ⭐⭐⭐ **Advanced** — 4 to 5 debug commands; requires following a chain of failures across multiple objects.

Each section contains **2 Advanced** videos to force multi-step deductive reasoning.

---

## Repository Structure

```
course-admin/
  ├── Dockerfile
  ├── app/
  └── Makefile

section-01-kubernetes-core/
  ├── 01-crashloop-oom-killed/
  ├── 02-crashloop-wrong-command/
  ├── 03-pod-pending-node-affinity/
  ├── 04-service-discovery-port-label-mismatch/
  └── 05-configmap-secret-key-mismatch/

section-02-helm-basics/
  ├── 06-helm-template-render-error/
  ├── 07-helm-upgrade-rollback/
  ├── 08-init-container-failure/
  ├── 09-helm-subchart-dependency-hell/
  └── 10-helm-hook-lifecycle-failure/

section-03-networking-storage-security/
  ├── 11-ingress-path-host-tls-misconfig/
  ├── 12-pvc-storageclass-missing/
  ├── 13-rbac-serviceaccount-forbidden/
  ├── 14-networkpolicy-traffic-denied/
  └── 15-coredns-custom-config-break/

section-04-production-ops/
  ├── 16-readiness-liveness-cascade/
  ├── 17-resourcequota-limitrange-denial/
  ├── 18-hpa-metrics-server-missing/
  ├── 19-pdb-blocking-node-drain/
  └── 20-statefulset-identity-storage-issue/
```

---

## Tech Stack
- **Local Kubernetes:** Rancher Desktop (primary) or Docker Desktop / Kind
- **Helm:** v3.x
- **CLI Tools:** `kubectl`, `helm`, `stern`, `k9s`
- **Custom Image:** `course-admin/` builds a configurable debug app pushed to your Docker Hub
- **Ingress:** Rancher Desktop ships Traefik; script provided if Nginx is preferred
- **Metrics Server:** Installed locally via Helm for HPA scenario
- **Multi-node (optional):** Scenario 19 uses a 2-node Kind cluster (still 100 % local)

---

## Section 1: Kubernetes Core — Pod Debugging Fundamentals
**Theme:** Master `kubectl` before touching Helm. All scenarios use raw manifests.

| # | Scenario | Difficulty | Steps | Why it is this level |
|---|----------|------------|-------|----------------------|
| 01 | CrashLoopBackOff: OOMKilled | ⭐ Beginner | 2 | `describe pod` immediately shows `OOMKilled`; fix is a manifest edit. |
| 02 | CrashLoopBackOff: Wrong Command | ⭐ Beginner | 2 | `describe pod` + `logs` reveal exit code 127; fix `command` / `args`. |
| 03 | Pod Stuck Pending: Node Affinity | ⭐⭐ Intermediate | 3 | `describe pod` → scheduler events → `get nodes --show-labels` → add label or toleration. |
| 04 | Service Discovery: Port & Label Mismatch | ⭐⭐⭐ Advanced | 5 | `get endpoints` empty → inspect Service `selector` → inspect Pod labels → inspect `targetPort` vs container `containerPort` → run debug pod to `wget` → fix manifest. |
| 05 | ConfigMap / Secret Key Mismatch | ⭐⭐⭐ Advanced | 4–5 | `exec` into pod → `ls` mount path or `printenv` → `get configmap/secret -o yaml` → compare keys with `volumeMounts` / `env.valueFrom` paths → fix Deployment. |

---

## Section 2: Helm Basics & Chart Debugging
**Theme:** Apply Helm to familiar concepts. Learn templating, releases, subcharts, and hooks.

| # | Scenario | Difficulty | Steps | Why it is this level |
|---|----------|------------|-------|----------------------|
| 06 | Helm Template Rendering Errors | ⭐ Beginner | 2 | `helm lint` → `helm template --debug` → fix typo or nil pointer in chart. |
| 08 | Init Container Failure | ⭐⭐ Intermediate | 3 | `describe pod` → `logs -c init` → inspect Helm `initContainers` template → fix wait logic or command. |
| 10 | Helm Hook Lifecycle Failure | ⭐⭐ Intermediate | 3 | `helm install --debug` → `get jobs` → `logs job/...` → adjust hook `weight` or `hook-delete-policy`. |
| 07 | Helm Upgrade & Rollback | ⭐⭐⭐ Advanced | 5 | Install good revision → upgrade to broken revision → observe failure → `helm history` → `get values` on both revisions → `helm rollback` → fix chart values → re-upgrade safely. |
| 09 | Helm Subchart Dependency Hell | ⭐⭐⭐ Advanced | 5 | `helm dependency list` → check `Chart.lock` vs `Chart.yaml` → inspect `charts/` folder → `helm template --debug` → verify `values.yaml` nesting for subchart keys → `helm dependency update` → reinstall. |

---

## Section 3: Networking, Storage & Security
**Theme:** Domain-specific deep dives. Students now combine K8s knowledge with Helm charts.

| # | Scenario | Difficulty | Steps | Why it is this level |
|---|----------|------------|-------|----------------------|
| 12 | PVC Stuck Pending | ⭐ Beginner | 2 | `describe pvc` → Events show `StorageClass` not found → `get storageclass` → fix `storageClassName` in PVC template. |
| 14 | NetworkPolicy Traffic Denial | ⭐⭐ Intermediate | 3 | `get networkpolicy` → `describe netpol` → run a debug pod and `curl` / `nc` to test ingress/egress → fix `from` / `to` rules. |
| 15 | CoreDNS Custom Config Break | ⭐⭐ Intermediate | 3 | `logs -n kube-system -l k8s-app=kube-dns` → `nslookup kubernetes.default` from debug pod → `get configmap coredns -n kube-system` → revert invalid forwarder / stub-domain → rollout restart CoreDNS. |
| 11 | Ingress Misconfiguration | ⭐⭐⭐ Advanced | 5 | `get ingress` → `describe ingress` → inspect `rules`, `paths`, and `tls` blocks → verify TLS secret exists and is valid → read Ingress controller (Traefik/Nginx) logs → check backend Service has Endpoints → fix Ingress manifest or secret reference. |
| 13 | RBAC: ServiceAccount Forbidden | ⭐⭐⭐ Advanced | 5 | `auth can-i --list --as=system:serviceaccount:...` → `get role` / `get clusterrole` → `get rolebinding` / `get clusterrolebinding` → verify `subjects` namespace and name → inspect Pod `serviceAccountName` → fix Role, Binding, or Pod spec. |

---

## Section 4: Production Operations & Advanced Workloads
**Theme:** Day-2 ops, autoscaling, maintenance windows, and stateful applications.

| # | Scenario | Difficulty | Steps | Why it is this level |
|---|----------|------------|-------|----------------------|
| 18 | HPA Not Scaling | ⭐ Beginner | 2 | `get hpa` shows `<unknown>` → verify `metrics-server` pod in `kube-system` → `top nodes` → confirm Deployment has `resources.requests` → fix or reinstall metrics-server. |
| 17 | ResourceQuota & LimitRange Denial | ⭐⭐ Intermediate | 3 | `describe resourcequota` → `describe limitrange` → sum the namespace’s existing resource usage → compare with Deployment replica + resource totals → lower request or adjust Quota. |
| 20 | StatefulSet Identity & Storage Issue | ⭐⭐ Intermediate | 3 | `describe statefulset` → `get pvc -l app=...` → `get endpoints` → compare `serviceName` in StatefulSet with actual headless Service name / selector → fix Service or `volumeClaimTemplates` `storageClassName`. |
| 16 | Readiness / Liveness Cascade Failure | ⭐⭐⭐ Advanced | 5 | App returns 502 → `get pods` → `describe pod` shows `Unhealthy` readiness → `get endpoints` shows 0 addresses → `logs` show app can’t reach DB → `describe svc` for DB shows endpoints missing → discover DB Pod is down → fix DB or loosen readiness probe / add startup probe. |
| 19 | PDB Blocking Node Drain | ⭐⭐⭐ Advanced | 5 | `kubectl drain <node>` → observe `Cannot evict pod because it would violate PDB` → `get pdb` → `describe pdb` → `get deployment` to see replica count vs `minAvailable` → temporarily scale Deployment or adjust PDB → retry drain → show safe maintenance workflow. |

**Note on 19:** Use a local **2-node Kind cluster** for this scenario (still 100 % offline). A single-node desktop cluster cannot meaningfully drain. Provide a `kind-config.yaml` in the folder.

---

## course-admin/ — Custom Scenario Image

All scenarios that need an application container use a single configurable HTTP server you build once.

### App capabilities (env-var driven)
| Variable | Effect |
|---|---|
| `LISTEN_PORT` | Port the HTTP server binds to (default `8080`) |
| `FAIL_START` | If `true`, exits immediately with code `1` |
| `READINESS_DELAY` | Seconds to wait before `/ready` returns `200` |
| `LIVENESS_FAIL_AFTER` | Seconds before `/health` starts returning `500` |
| `OOM_ALLOCATE_MB` | Allocates this many MB of memory on startup |
| `RESPONSE_CODE` | HTTP status code for root path `/` |
| `LOG_SPIKE` | If `true`, spews logs rapidly to demo `stern` |

### Build & Push
```bash
cd course-admin/
make build   # docker build -t <your-dockerhub>/k8s-debug-app:v1 .
make push    # docker push <your-dockerhub>/k8s-debug-app:v1
```

---

## Per-Scenario Folder Structure

Every scenario folder contains **exactly 3 files for live editing**:

```
section-01-kubernetes-core/01-crashloop-oom-killed/
├── README.md              # Scenario overview & learning outcomes
├── DEBUG.md               # Step-by-step debugging guide
└── deployment.yaml        # Live editable manifest (starts in broken state)
```

No Makefiles—students learn by typing real `kubectl` commands.

### Teaching Workflow (All Scenarios Follow This Pattern)

1. **Before Recording:** Deploy the broken state
   ```bash
   kubectl apply -f deployment.yaml
   ```

2. **During Recording:** Use **simple, real-world commands**
   - Get resource names first: `kubectl get pods` (copy pod name from output)
   - Describe using the actual name: `kubectl describe pod oom-demo-xxxxx`
   - View logs with pod name: `kubectl logs oom-demo-xxxxx`
   - **No complex one-liners** — this is how real debugging works
   - Identify the root cause in the output
   - Edit the manifest **live** using vim, sed, or nano (show your editing process)
   - Apply the fix: `kubectl apply -f deployment.yaml`
   - Verify: `kubectl get pods` and watch the pod become healthy

3. **After Recording:** Keep the fixed version for the next student/team

### File Organization (For All Scenarios)

- **`README.md`** — Scenario overview
  - **Interview Problem Statement** — A short narrative prompt (2–3 sentences max) setting the on-call or interview scene. It should describe the **symptoms** the candidate sees (e.g., Pod is crashlooping, service is unreachable) without naming the root cause, exit codes, or specific Kubernetes events. The candidate must deduce the issue. Format: *"We deployed X, and Y is happening... Walk me through how you would figure out what's going on and how you'd fix it."*
  - Difficulty level (⭐ to ⭐⭐⭐)
  - Learning outcomes
  - Prerequisites (AWS EC2 specs if needed)
  - Deploy command: `kubectl apply -f deployment.yaml`

- **`DEBUG.md`** — The instructor's step-by-step script
  - **Step 1–3:** Simple debugging commands (get, describe, logs)
    ```bash
    kubectl get pods
    kubectl describe pod <pod-name>  # Copy pod name from previous step
    kubectl logs <pod-name>
    ```
  - **Root cause analysis:** Explain what you found
  - **The fix:** Show the exact YAML lines to change, with surrounding context so the instructor knows where to navigate in the file. For Helm scenarios (Section 02), always show a block of the file before and after the change so the edit location is unambiguous. **Highlight the changed line(s)** using an inline marker like `# <-- EDIT THIS LINE` so the exact edit is visually obvious during prep.
  - **Editing options:** Vim or Nano only. Do not include `sed` one-liners — live editing should be visible and methodical.
  - **Verification:** Run describe/logs again to confirm fix
  - **Editor tips for large files:** 
    - Search in vim: `/pattern` → press `n` for next
    - Jump to line: `vim +20 deployment.yaml`
    - Use grep to find lines first: `grep -n "keyword" deployment.yaml`
    - Compare changes: `diff -u backup.yaml deployment.yaml`
  - **Talking points:** What students should understand from this scenario

- **`deployment.yaml`** (or `Chart.yaml` + `values.yaml` for Helm)
  - **Starts in broken state** — Deploy it, watch it fail
  - **Clean manifest — NO fix hints, NO ❌/✅ symbols, NO explanatory comments** that reveal the issue. The file must look like a real manifest you would show in a live demo or interview. Students should not be able to spot the bug by reading the YAML.
  - All root-cause explanations, before/after diffs, and fix instructions belong exclusively in `DEBUG.md`

---

## AWS EC2 Setup Prerequisites

For team training or production-like testing:

### Infrastructure
- **Instance Type:** t3.2xlarge (8 vCPU, 32 GB RAM)
- **Storage:** 30 GB gp3
- **OS:** Amazon Linux 2 or 2023
- **Security Groups:** Allow ports 8080 (app), 6443 (k8s API)

### Setup (Run Once)
```bash
cd course-admin
sudo bash setup.sh        # Detects OS and installs Docker, kubectl, kind
make build DOCKER_HUB_USER=local   # Build the scenario app image
```

The setup.sh script automatically handles both Ubuntu and Amazon Linux—no extra steps needed.

---

## Debugging Philosophy: Keep It Real

All scenarios emphasize **realistic, live debugging workflow**:

✅ **DO:** Use simple commands students can type and copy  
✅ **DO:** Show the actual pod/resource names you see in the output  
✅ **DO:** Edit manifests live in vim/sed/nano (messy is okay, it's real)  
✅ **DO:** Use grep and search to find lines before editing  
✅ **DO:** Show copy-paste mistakes and how to fix them (students learn recovery)  

❌ **DON'T:** Use complex one-liners with command substitution  
❌ **DON'T:** Script commands that look like magic (defeats the purpose)  
❌ **DON'T:** Hide the debugging process (show your thinking!)  
❌ **DON'T:** Over-engineer the examples  

**Example:**
```bash
# ✅ Real-world debugging
kubectl get pods
# Copy pod name: oom-demo-xxxxx
kubectl describe pod oom-demo-xxxxx
# Read output, identify issue, edit file
vim deployment.yaml
kubectl apply -f deployment.yaml

# ❌ Unnecessarily complex
kubectl describe pod $(kubectl get pods -l app=oom-demo -o jsonpath='{.items[0].metadata.name}')
```

---

## Next Steps
1. ✅ Scaffold `course-admin/` — **DONE**
2. ✅ Setup scripts for AWS EC2 — **DONE**
3. ✅ Scenario 01 restructured — **DONE**
4. Create scenarios 02–20 following the same pattern:
   - Single `deployment.yaml` (or `Chart.yaml`) starting in broken state
   - `README.md` with clear problem description
   - `DEBUG.md` with simple, copy-paste kubectl commands (no one-liners)
   - No scenario Makefiles; students learn by typing actual commands
   - Comments marking the problem area in the manifest
5. Test each scenario end-to-end on AWS EC2 t3.2xlarge
6. Record videos showing **realistic live debugging** — students learn how you actually think through problems
