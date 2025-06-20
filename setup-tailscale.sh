#!/bin/bash

set -e

# === Ensure root ===
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Please run as root or with sudo."
  exit 1
fi

echo "== Tailscale Setup for IPv6-only VPS =="

# === Prompt for TAILSCALE_AUTH_KEY securely ===
read -s -p "Enter your Tailscale Auth Key (will be hidden): " TAILSCALE_AUTH_KEY
echo
if [ -z "$TAILSCALE_AUTH_KEY" ]; then
  echo "❌ TAILSCALE_AUTH_KEY is required."
  exit 1
fi

# === Prompt for optional hostname ===
read -p "Enter hostname to show in Tailscale (default: vps-$(hostname)): " TAILSCALE_HOSTNAME
TAILSCALE_HOSTNAME=${TAILSCALE_HOSTNAME:-vps-$(hostname)}

# === Update system ===
echo "📦 Updating packages..."
apt-get update -y && apt-get upgrade -y

# === Install dependencies ===
echo "🔧 Installing required tools..."
apt-get install -y curl gnupg2 lsb-release

# === Add Tailscale APT repo ===
echo "➕ Adding Tailscale repository..."
curl -fsSL https://pkgs.tailscale.com/stable/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/$(lsb_release -cs).noarmor.gpg \
  | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null

curl -fsSL https://pkgs.tailscale.com/stable/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/tailscale.list \
  | sed 's/^/deb [signed-by=\/usr\/share\/keyrings\/tailscale-archive-keyring.gpg] /' \
  | tee /etc/apt/sources.list.d/tailscale.list

apt-get update -y
apt-get install -y tailscale

# === Start Tailscale ===
echo "🚀 Enabling and starting tailscaled..."
systemctl enable --now tailscaled

# === Authenticate ===
echo "🔑 Logging into Tailscale..."
tailscale up --authkey "$TAILSCALE_AUTH_KEY" --hostname "$TAILSCALE_HOSTNAME" --ssh

# === Output Tailscale IP ===
echo "✅ Tailscale is connected."
echo "🔗 Tailscale IPs:"
tailscale ip -4 -6
