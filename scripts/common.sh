#!/bin/bash
set -e

echo "Running common provisioning script..."

if command -v apt-get &> /dev/null; then
    echo "Detected Debian/Ubuntu system"
    
    timedatectl set-timezone UTC 2>/dev/null || true
    
    cat > /etc/profile.d/custom-env.sh << 'EOF'
export EDITOR=vim
export HISTSIZE=10000
export HISTFILESIZE=20000
EOF
    
elif command -v apk &> /dev/null; then
    echo "Detected Alpine system"
    
    apk add --no-cache tzdata
    cp /usr/share/zoneinfo/UTC /etc/localtime
    echo "UTC" > /etc/timezone
fi

echo "Common provisioning completed."
