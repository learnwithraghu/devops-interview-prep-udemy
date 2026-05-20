# Course Plan: Real-World Kubernetes & Helm Debugging

## Overview
A hands-on, local-only video course focused on live scenario-based debugging. Every scenario runs on **Rancher Desktop, Docker Desktop, or Kind** with zero external cloud dependencies.  
The course is divided into **4 sections of 5 videos each**, with a deliberate difficulty curve inside every section.

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

## Per-Scenario Folder Contents

Every folder contains:
- `broken/` — manifests or Helm chart that deploys the bug
- `fixed/` — manifests or Helm chart with the correction
- `README.md` — one-paragraph description + exact deploy commands (run **before** recording)
- `DEBUG.md` — numbered debug steps, expected CLI output snippets, and instructor talking points (used **during** recording)

---

## Next Steps
1. Scaffold `course-admin/` (Dockerfile, Go app, Makefile).
2. Build and push the custom image.
3. Create all 20 folders with `broken/`, `fixed/`, `README.md`, `DEBUG.md`.
4. Test every scenario end-to-end on Rancher Desktop (and Kind for #19).
