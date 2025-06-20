#!/bin/bash

set -e

echo "== Tailscale Setup for Debian/Ubuntu =="

# === Ensure root ===
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Please run as root or with sudo."
  exit 1
fi

# === Detect OS ID and Codename ===
OS_ID=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
OS_CODENAME=$(lsb_release -cs)

# Validate supported OS
if [[ "$OS_ID" != "ubuntu" && "$OS_ID" != "debian" ]]; then
  echo "❌ Unsupported OS: $OS_ID (only Ubuntu or Debian supported)"
  exit 1
fi

echo "📦 Detected: $OS_ID $OS_CODENAME"

# === Prompt for Auth Key (hidden input) ===
read -s -p "Enter your Tailscale Auth Key (will be hidden): " TAILSCALE_AUTH_KEY
echo
if [ -z "$TAILSCALE_AUTH_KEY" ]; then
  echo "❌ TAILSCALE_AUTH_KEY is required."
  exit 1
fi

# === Optional hostname ===
read -p "Enter hostname to show in Tailscale (default: vps-$(hostname)): " TAILSCALE_HOSTNAME
TAILSCALE_HOSTNAME=${TAILSCALE_HOSTNAME:-vps-$(hostname)}

# === Update and install dependencies ===
echo "🔧 Updating and installing dependencies..."
apt-get update -y && apt-get install -y curl gnupg2 lsb-release

# === Add Tailscale repo (auto based on OS) ===
echo "➕ Adding Tailscale APT repo..."

curl -fsSL "https://pkgs.tailscale.com/stable/${OS_ID}/${OS_CODENAME}.noarmor.gpg" | \
  tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null

echo "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/${OS_ID} ${OS_CODENAME} main" \
  | tee /etc/apt/sources.list.d/tailscale.list

# === Install Tailscale ===
apt-get update -y
apt-get install -y tailscale

# === Start and enable tailscaled ===
echo "🚀 Starting Tailscale service..."
systemctl enable --now tailscaled

# === Connect to Tailscale ===
echo "🔑 Connecting to Tailscale..."
tailscale up --authkey "$TAILSCALE_AUTH_KEY" --hostname "$TAILSCALE_HOSTNAME" --ssh

# === Show IPs ===
echo "✅ Tailscale is connected!"
tailscale ip -4 -6
