# Section 01: Kubernetes Core Debugging

This section contains hands-on scenarios for debugging core Kubernetes issues. Each scenario is designed to teach a specific debugging skill and can be practiced on a local kind cluster or production-like environments.

## Scenario Structure

Each scenario folder contains **production-ready files for live editing**:

```
section-01-kubernetes-core/01-crashloop-oom-killed/
├── README.md              # Scenario overview & setup
├── DEBUG.md               # Step-by-step debugging guide with vim/sed tricks
├── deployment.yaml        # Live editable manifest (starts in broken state)
└── Makefile              # Quick commands: deploy, describe, logs, fix, verify
```

**No separate `broken/` and `fixed/` folders.** Instead:
- Start with one manifest in the broken state
- Edit it live during the recording using vim/sed/nano
- Show students the debugging workflow and editing process
- Apply the fix and verify it works

This approach teaches the real-world workflow: identify → locate → edit → apply → verify.

## AWS EC2 Environment Setup

### Recommended Configuration
- **Instance Type**: t3.2xlarge
- **vCPUs**: 8
- **Memory**: 32 GB (plenty of headroom for kind cluster and multiple scenarios)
- **Storage**: 30 GB (gp3 recommended for better I/O performance)
- **OS**: Amazon Linux 2 or Amazon Linux 2023
- **Security Groups**: Allow port 8080 (application) and 6443 (Kubernetes API)

### Initial Setup
1. SSH into your EC2 instance:
```bash
ssh -i your-key.pem ec2-user@your-instance-ip
```

2. Clone the repository:
```bash
git clone https://github.com/learnwithraghu/k8-debugging-interview.git
cd k8-debugging-interview
```

3. Run the setup script:
```bash
cd course-admin
sudo bash setup.sh
```

This will:
- Install Docker
- Install kubectl
- Install kind
- Build the course application Docker image
- Create a local Kubernetes cluster named `course-admin`
- Configure Docker daemon permissions

4. Verify the setup:
```bash
kubectl cluster-info
kubectl get nodes
```

## Running Scenarios

### General Workflow

Each scenario follows this pattern:

1. **Deploy the broken state:**
   ```bash
   cd section-01-kubernetes-core/01-crashloop-oom-killed
   kubectl apply -f deployment.yaml
   ```

2. **Observe and debug** (use Makefile shortcuts):
   ```bash
   make watch              # Watch pods in real-time
   make describe           # See pod details and events
   make logs              # View container output
   ```

3. **Identify the root cause** using DEBUG.md

4. **Edit the manifest live** (show vim/sed tricks):
   ```bash
   vim deployment.yaml
   # or use quick fix:
   make fix
   ```

5. **Apply the fix:**
   ```bash
   kubectl apply -f deployment.yaml
   ```

6. **Verify** the pod is now running:
   ```bash
   make verify
   kubectl logs <pod-name>
   ```

### Using the Makefile

Most scenarios include a Makefile with quick commands:

```bash
make deploy    # Apply the broken manifest
make describe  # Check pod status and events
make logs      # View pod logs
make watch     # Watch pod status in real-time
make fix       # Apply sed-based quick fix
make verify    # Confirm the fix worked
make clean     # Delete the deployment
```

These shortcuts save time during recording and demos.

## Available Scenarios

### 01-crashloop-oom-killed
- **Topic**: Memory limits and OOMKilled errors
- **Difficulty**: ⭐ Beginner
- **Skills**: Resource requests/limits, container memory management, debugging OOMKilled
- **Files**: [README.md](01-crashloop-oom-killed/README.md) | [DEBUG.md](01-crashloop-oom-killed/DEBUG.md)

## Resource Constraints on AWS EC2

### Memory Distribution
- **OS and system services**: ~2-3 GB
- **kind cluster (control-plane container)**: ~2-4 GB
- **Available for workloads**: ~25-28 GB

### Scenario Resource Requirements
- **01-crashloop-oom-killed**: <500 MB

This leaves ample room to run multiple scenarios simultaneously or add more scenarios.

## Troubleshooting

### Pod not starting
```bash
# Check pod status
kubectl get pods
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

### kind cluster not accessible
```bash
# Verify kind cluster is running
kind get clusters

# Check Docker containers
docker ps -a

# Restart Docker if needed
sudo systemctl restart docker
sudo systemctl restart docker-containerd
```

### Disk space issues
```bash
# Check available space
df -h

# Clean up Docker resources
docker system prune -a --volumes

# Check kind cluster disk usage
docker exec -it course-admin-control-plane df -h
```

### Memory pressure
```bash
# Monitor memory usage on host
free -h

# Check Pod resource usage
kubectl top pods
kubectl top nodes
```

## Next Steps

After completing Section 01 scenarios, proceed to:
- Section 02: Networking issues
- Section 03: Storage and persistence
- Section 04: Advanced debugging techniques

## Tips for Instructors

1. **Demo Setup**: Pre-setup the AWS EC2 instance before the training session to save time
2. **Recording**: Use tmux or screen for better terminal recording during demos
3. **Resource Monitoring**: Open a second terminal to run `watch kubectl get pods` while demonstrating scenarios
4. **Group Size**: This setup supports training groups of 2-5 people per instance

## Notes

- The setup.sh script in `course-admin/` automatically detects Amazon Linux and installs appropriate packages
- All scenarios use `imagePullPolicy: Never` to use locally built Docker images
- Ensure the Docker image is built before deploying scenarios: `make build DOCKER_HUB_USER=local` from `course-admin/`
- Log out and back in after running setup.sh if you get Docker permission errors
