# Scenario 06: Helm Template Rendering Error

## Interview Problem Statement

> **Interviewer:** "A team member handed you a Helm chart to deploy an internal service. When you run the install command, Helm fails immediately before anything is created in the cluster. The error message mentions a template and a value reference, but the output is dense. You have the chart directory locally. Walk me through how you would narrow down exactly which template and which value is causing the failure, and what you would change to make the install succeed."

## Difficulty
⭐ Beginner — 2 debug commands + 1 chart edit

## Learning Outcomes
- Use `helm lint` to catch chart-level issues before installing
- Use `helm template --debug` to see exactly which template file and line failed
- Read Helm template rendering errors to identify nil pointers and missing keys
- Understand the relationship between `values.yaml` keys and template references
- Fix a missing value in `values.yaml` to resolve a template render error

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
cd section-02-helm-basics/06-helm-template-render-error
helm install helm-template-demo ./debug-chart
```

## Expected Behavior

Helm will fail with a template rendering error before creating any Kubernetes resources:

```bash
$ helm install helm-template-demo ./debug-chart
Error: template: debug-chart/templates/deployment.yaml:22:28: executing "debug-chart/templates/deployment.yaml" at <.Values.app.logLevel>: nil pointer evaluating interface {}.logLevel
```

No Pods, Services, or other resources are created.

## Debugging & Live Fixing

Follow [DEBUG.md](DEBUG.md) for:
- Using `helm lint` and `helm template --debug` to isolate the failure
- Reading the error output to identify the exact file and line
- Fixing the missing key in `values.yaml`
- Re-running `helm install` to verify

## Estimated Recording Time
- Debugging: 2–3 minutes
- Live editing + verification: 2–3 minutes
- **Total:** ~4–6 minutes

## Notes for Instructors

### No Running Resources to Clean Up
Because Helm fails at the template rendering stage, nothing is created in the cluster. After fixing, you can simply run `helm install` again.

### Editing Approach
You'll edit `values.yaml` live during recording. The file looks like a normal values file with no visible hints.

### Testing the Fix
After editing:
```bash
helm install helm-template-demo ./debug-chart
kubectl get pods
```

The Pod should be created and transition to `Running`.
