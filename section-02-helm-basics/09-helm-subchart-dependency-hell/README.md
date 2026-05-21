# Scenario 09: Helm Subchart Dependency Hell

## Interview Problem Statement

> **Interviewer:** "A teammate pulled the latest Helm umbrella chart and tried to deploy it, but `helm install` fails immediately. After they worked around that, the release installs but the application Pods are stuck in `ImagePullBackOff`. The chart wraps a subchart for the actual application workload. Walk me through how you would diagnose the dependency issues, verify the subchart is receiving the correct values, and get the release running."

## Difficulty
⭐⭐⭐ Advanced — 5 debug commands + 2 chart edits

## Learning Outcomes
- Use `helm dependency list` to find missing or out-of-sync subchart dependencies
- Compare `Chart.yaml` and `Chart.lock` to spot version drift
- Inspect the `charts/` directory for vendored subchart archives
- Use `helm template --debug` to verify subchart values are rendered correctly
- Understand Helm subchart value nesting (parent keys must match subchart name)
- Run `helm dependency update` to vendor dependencies before install

## Prerequisites

### AWS EC2 Environment
- **Instance Type:** t3.2xlarge or larger  
- **Storage:** 30 GB (gp3 recommended)
- **OS:** Amazon Linux 2 or 2023
- **Setup:** Run `sudo bash setup.sh` from `course-admin/` directory

### Helm Installed
```bash
helm version
```

### Docker Image Built
```bash
cd course-admin
make build DOCKER_HUB_USER=local
```

## Deploy the Broken State

```bash
cd section-02-helm-basics/09-helm-subchart-dependency-hell
helm install subchart-demo ./debug-chart
```

The install fails because the subchart dependency is declared in `Chart.yaml` but not vendored in `charts/`.

## Expected Behavior

### Phase 1: Install failure
```bash
$ helm install subchart-demo ./debug-chart
Error: INSTALLATION FAILED: found in Chart.yaml, but missing in charts/ directory: app-component
```

### Phase 2: After vendoring dependencies (still broken values)
Once dependencies are updated and the release installs, Pods fail to pull the image:

```bash
$ kubectl get pods
NAME                             READY   STATUS             RESTARTS   AGE
subchart-demo-xxx-yyy            0/1     ImagePullBackOff   0          30s
```

The subchart is using its default image tag because the parent `values.yaml` passes configuration at the wrong nesting level.

## Debugging & Live Fixing

Follow [DEBUG.md](DEBUG.md) for:
- Using `helm dependency list` to find the missing subchart
- Comparing `Chart.yaml` vs `Chart.lock` for version drift
- Running `helm dependency update` to populate `charts/`
- Using `helm template --debug` to see the subchart's rendered image tag
- Fixing subchart value nesting in `values.yaml`
- Re-installing and verifying the Pod reaches `Running`

## Estimated Recording Time
- Dependency debugging: 4–5 minutes
- Values nesting fix + verification: 3–4 minutes
- **Total:** ~8–10 minutes

## Notes for Instructors

### Two-Phase Failure
This scenario has two distinct bugs that mirror real dependency hell:
1. **Missing vendored subchart** — `Chart.yaml` declares a dependency but `charts/` is empty (common after a fresh git clone when `.tgz` files are not committed)
2. **Wrong values nesting** — parent `values.yaml` sets `image.tag` at the top level instead of under the subchart name `app-component`

Students must fix both to reach a healthy release.

### Chart.lock Drift
`Chart.lock` pins version `0.1.0` while `Chart.yaml` requires `0.2.0`. This is a secondary clue — `helm dependency update` resolves both the missing archive and the lock file.

### Editing Approach
You'll edit `values.yaml` live during recording. The file looks like a normal umbrella chart values file with no visible hints about subchart nesting.

### Testing the Fix
After editing:
```bash
helm uninstall subchart-demo
helm install subchart-demo ./debug-chart
kubectl get pods
```

The Pod should transition to `Running`.
