# course-admin

This folder contains the Docker app used for the course.

## Build locally

From the `course-admin` folder, run:

```bash
make build DOCKER_HUB_USER=local
```

This builds the image as:

```text
local/k8s-debug-app:v1
```

## Run locally

```bash
make run DOCKER_HUB_USER=local
```

Then open `http://localhost:8080`.

## Notes

- The `Makefile` uses `DOCKER_HUB_USER` to name the image.
- Use `local` or any identifier when building for local use.
- This image can be consumed later by section-specific Kubernetes manifests.
