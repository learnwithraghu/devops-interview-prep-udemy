#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_NAME="course-admin"
DOCKER_HUB_USER="${DOCKER_HUB_USER:-local}"
IMAGE_NAME="k8s-debug-app"
IMAGE_TAG="${IMAGE_TAG:-v1}"
IMAGE="${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"

# Detect OS
detect_os() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo "${ID}"
  elif [[ -f /etc/redhat-release ]]; then
    echo "rhel"
  elif [[ -f /etc/debian_version ]]; then
    echo "debian"
  else
    echo "unknown"
  fi
}

info() {
  printf "\e[1;34m[INFO]\e[0m %s\n" "$1"
}

warn() {
  printf "\e[1;33m[WARN]\e[0m %s\n" "$1"
}

error() {
  printf "\e[1;31m[ERROR]\e[0m %s\n" "$1" >&2
  exit 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

install_docker() {
  if command_exists docker; then
    info "Docker is already installed"
    return
  fi

  if [[ "$(id -u)" -ne 0 ]]; then
    error "Docker installation requires sudo/root access. Run: sudo $0"
  fi

  local os_type=$(detect_os)
  info "Installing Docker Engine on ${os_type}..."

  case "${os_type}" in
    amzn|rhel|fedora|almalinux|rocky)
      # Amazon Linux, RHEL, Fedora, AlmaLinux, Rocky Linux
      yum update -y
      yum install -y docker
      systemctl start docker
      systemctl enable docker
      ;;
    ubuntu|debian)
      # Ubuntu, Debian
      apt-get update -qq
      apt-get install -y --no-install-recommends ca-certificates curl gnupg lsb-release

      mkdir -p /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      chmod 644 /etc/apt/keyrings/docker.gpg

      echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" \
        > /etc/apt/sources.list.d/docker.list

      apt-get update -qq
      apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      ;;
    *)
      error "Unsupported OS: ${os_type}. Please install Docker manually."
      ;;
  esac

  info "Docker installation complete"
}

install_kubectl() {
  if command_exists kubectl; then
    info "kubectl is already installed"
    return
  fi

  info "Installing kubectl..."
  curl -fsSLo /tmp/kubectl https://dl.k8s.io/release/stable.txt
  KUBECTL_VERSION="$(cat /tmp/kubectl)"
  curl -fsSLo /tmp/kubectl https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl

  if [[ "$(id -u)" -ne 0 ]]; then
    sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
  else
    install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
  fi
  rm -f /tmp/kubectl

  info "kubectl ${KUBECTL_VERSION} installed"
}

install_kind() {
  if command_exists kind; then
    info "kind is already installed"
    return
  fi

  info "Installing kind..."
  curl -fsSLo /tmp/kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64

  if [[ "$(id -u)" -ne 0 ]]; then
    sudo install -o root -g root -m 0755 /tmp/kind /usr/local/bin/kind
  else
    install -o root -g root -m 0755 /tmp/kind /usr/local/bin/kind
  fi
  rm -f /tmp/kind

  info "kind installed"
}

build_docker_image() {
  info "Building Docker image ${IMAGE}"
  docker build -t "${IMAGE}" "${SCRIPT_DIR}"
}

load_image_into_kind() {
  if ! command_exists kind; then
    error "kind is not installed, cannot load image into cluster"
  fi

  if ! kind get clusters | grep -qx "${CLUSTER_NAME}"; then
    error "kind cluster '${CLUSTER_NAME}' does not exist"
  fi

  info "Loading Docker image ${IMAGE} into kind cluster '${CLUSTER_NAME}'"
  kind load docker-image "${IMAGE}" --name "${CLUSTER_NAME}"
}

ensure_docker_group() {
  if [[ "$(id -u)" -ne 0 ]]; then
    if getent group docker >/dev/null; then
      if id -nG "$USER" | grep -qw docker; then
        info "User $USER is already in the docker group"
        return
      fi
      info "Adding $USER to the docker group"
      sudo usermod -aG docker "$USER"
      warn "You must log out and back in for docker group changes to take effect"
    else
      info "Creating docker group and adding $USER"
      sudo groupadd -f docker
      sudo usermod -aG docker "$USER"
      warn "You must log out and back in for docker group changes to take effect"
    fi
  fi
}

start_docker_service() {
  if command_exists docker && docker info >/dev/null 2>&1; then
    info "Docker is already running"
    return
  fi

  if command_exists systemctl; then
    if systemctl is-active --quiet docker; then
      info "Docker service is already running"
      return
    fi
    info "Starting Docker service with systemctl"
    sudo systemctl enable --now docker
    return
  fi

  if command_exists service; then
    if sudo service docker status >/dev/null 2>&1; then
      info "Docker service is already running"
      return
    fi
    info "Starting Docker service with service"
    sudo service docker start
    return
  fi

  warn "Could not manage Docker service automatically. Please start Docker manually."
}

create_kind_cluster() {
  if kind get clusters | grep -qx "${CLUSTER_NAME}"; then
    info "kind cluster '${CLUSTER_NAME}' already exists"
    return
  fi

  info "Creating kind cluster '${CLUSTER_NAME}'"
  cat <<EOF | kind create cluster --name "${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 8080
        hostPort: 8080
        protocol: TCP
EOF

  info "kind cluster '${CLUSTER_NAME}' created"
}

main() {
  if [[ "$(id -u)" -ne 0 ]]; then
    warn "Some operations may require sudo. You will be prompted if needed."
  fi

  install_docker
  start_docker_service
  ensure_docker_group
  install_kubectl
  install_kind
  build_docker_image
  create_kind_cluster
  load_image_into_kind

  info "Setup complete"
  echo
  echo "Next steps:" 
  echo "  1. Open a new terminal or log out/in if docker group changes were applied"
  echo "  2. Run from ${SCRIPT_DIR}:"
  echo "       make build DOCKER_HUB_USER=<user>" 
  echo "       make run DOCKER_HUB_USER=<user>" 
  echo "  3. Or deploy to kind with kubectl once your app image is available"
  echo
  echo "Cluster info:"
  kubectl cluster-info
}

main "$@"
