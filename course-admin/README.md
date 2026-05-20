# course-admin

This folder contains the Docker app used for the course.

## AWS EC2 Environment Setup

### Recommended AWS Configuration

For running interview scenarios with this course material, use the following AWS EC2 configuration:

- **Instance Type**: `t3.2xlarge` or larger
- **Storage**: 30 GB (gp3 recommended)
- **OS**: Amazon Linux 2 or Amazon Linux 2023
- **Security Group**: Allow inbound traffic on ports 8080 (application), 6443 (Kubernetes API)

### Initial Setup on Amazon Linux EC2

The `setup.sh` script automatically detects your OS and installs the required tools for both Ubuntu and Amazon Linux environments.

Run the setup script on your EC2 instance:

```bash
cd course-admin
sudo bash setup.sh
```

This script will:
- Install Docker Engine
- Install kubectl
- Install kind (Kubernetes in Docker)
- Build the course application Docker image
- Create a local Kubernetes cluster with kind
- Configure Docker daemon and user permissions

**Note**: After running the setup script, log out and back in for Docker group changes to take effect.

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
- The `setup.sh` script supports both Ubuntu and Amazon Linux distributions.
- Ensure 30 GB of storage is available before running interview scenarios to avoid disk space issues.
