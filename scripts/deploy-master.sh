#!/bin/bash
set -e

CONTAINER_NAME="${1:?Usage: $0 <container-name> [image-name]}"
IMAGE_NAME="${2:-debian-salt-master}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MASTER_CONFIG="${SCRIPT_DIR}/../salt/master"

if [[ ! -f "$MASTER_CONFIG" ]]; then
    echo "Error: master config not found at $MASTER_CONFIG"
    exit 1
fi

echo "Creating container '$CONTAINER_NAME' from image '$IMAGE_NAME'..."
incus launch "$IMAGE_NAME" "$CONTAINER_NAME"

echo "Waiting for container to start..."
sleep 2

echo "Copying master configuration..."
incus file push "$MASTER_CONFIG" "$CONTAINER_NAME/etc/salt/master"

echo "Copying Salt states..."
incus exec "$CONTAINER_NAME" -- mkdir -p /srv/salt/states /srv/salt/pillar
incus file push -r "${SCRIPT_DIR}/../salt/states/" "$CONTAINER_NAME/srv/salt/states/"
incus file push -r "${SCRIPT_DIR}/../salt/pillar/" "$CONTAINER_NAME/srv/salt/pillar/"

echo "Enabling and starting salt-master..."
incus exec "$CONTAINER_NAME" -- systemctl enable salt-master
incus exec "$CONTAINER_NAME" -- systemctl restart salt-master

CONTAINER_IP=$(incus list "$CONTAINER_NAME" -f csv -c 4 | cut -d' ' -f1)

echo ""
echo "Done. Salt Master '$CONTAINER_NAME' is running."
echo "Master IP: $CONTAINER_IP"
echo ""
echo "To accept minion keys: incus exec $CONTAINER_NAME -- salt-key -L"
echo "To accept all keys:    incus exec $CONTAINER_NAME -- salt-key -A"
