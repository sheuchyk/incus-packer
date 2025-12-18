#!/bin/bash
set -e

echo "Applying security hardening..."

if command -v apt-get &> /dev/null; then
    apt-get install -y unattended-upgrades
    dpkg-reconfigure -plow unattended-upgrades
fi

if [ -f /etc/ssh/sshd_config ]; then
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/#PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
fi

echo "Security hardening completed."
