#!/bin/bash
# This script installs and configures automatic updates and automatic reboots on Raspbian/Ubuntu using unattended-upgrades.
# Run this script as root.
# sudo nano unattendedupdates.sh
# sudo chmod +x unattendedupdates.sh 
# sudo ./unattendedupdates.sh

# Exit immediately if a command exits with a non-zero status.
set -e

# Check if the script is running as root.
if [[ $EUID -ne 0 ]]; then
  echo "Please run this script as root or with sudo."
  exit 1
fi

echo "Updating package lists..."
apt update

echo "Installing unattended-upgrades package..."
apt install -y unattended-upgrades

echo "Configuring periodic updates..."
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

echo "Ensuring security updates are enabled in unattended-upgrades configuration..."
if grep -q '"${distro_id}:${distro_codename}-security";' /etc/apt/apt.conf.d/50unattended-upgrades; then
  echo "Security updates are configured."
else
  echo "WARNING: The security updates entry ('${distro_id}:${distro_codename}-security') was not found in /etc/apt/apt.conf.d/50unattended-upgrades."
  echo "Please edit the file manually to include this entry if needed."
fi

echo "Enabling automatic reboots if needed..."
# Append automatic reboot configuration if not already present.
if ! grep -q 'Unattended-Upgrade::Automatic-Reboot' /etc/apt/apt.conf.d/50unattended-upgrades; then
  cat >> /etc/apt/apt.conf.d/50unattended-upgrades <<'EOF'

Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
EOF
  echo "Automatic reboot configuration appended."
else
  echo "Automatic reboot configuration already present."
fi

echo "Running a test of unattended-upgrades..."
unattended-upgrade -d

echo "Automatic update and reboot configuration is complete."
