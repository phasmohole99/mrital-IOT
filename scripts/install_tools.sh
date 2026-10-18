#!/usr/bin/env bash
set -euo pipefail

# Run as a regular user with sudo access on a Kali Linux VM.
K3D_VERSION=v5.9.0
KUBECTL_VERSION=v1.35.5

sudo apt-get update
sudo apt-get install -y ca-certificates curl docker.io
sudo systemctl enable --now docker

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh -o "$tmp_dir/k3d-install.sh"
TAG="$K3D_VERSION" bash "$tmp_dir/k3d-install.sh"

case "$(uname -m)" in
  x86_64) arch=amd64 ;;
  aarch64) arch=arm64 ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

kubectl_url="https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/$arch/kubectl"
curl -fsSL "$kubectl_url" -o "$tmp_dir/kubectl"
curl -fsSL "$kubectl_url.sha256" -o "$tmp_dir/kubectl.sha256"
printf '%s  %s\n' "$(cat "$tmp_dir/kubectl.sha256")" "$tmp_dir/kubectl" | sha256sum --check
sudo install -m 0755 "$tmp_dir/kubectl" /usr/local/bin/kubectl

sudo usermod -aG docker "$USER"
echo "Installed Docker, K3d $K3D_VERSION, and kubectl $KUBECTL_VERSION."
echo "Log out and back in to activate Docker group membership."
