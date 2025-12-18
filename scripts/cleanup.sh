#!/bin/bash
set -e

echo "Running cleanup..."

if command -v apt-get &> /dev/null; then
    apt-get autoremove -y
    apt-get clean
    rm -rf /var/lib/apt/lists/*
elif command -v apk &> /dev/null; then
    rm -rf /var/cache/apk/*
fi

rm -rf /tmp/*
rm -rf /var/tmp/*
rm -rf /root/.cache/*
rm -rf /home/*/.cache/* 2>/dev/null || true

cat /dev/null > /var/log/wtmp 2>/dev/null || true
cat /dev/null > /var/log/btmp 2>/dev/null || true

find /var/log -type f -name "*.log" -exec truncate -s 0 {} \; 2>/dev/null || true
find /var/log -type f -name "*.gz" -delete 2>/dev/null || true

echo "Cleanup completed."
