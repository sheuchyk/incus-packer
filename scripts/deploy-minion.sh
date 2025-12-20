#!/bin/bash
set -e

CONTAINER_NAME="${1:?Usage: $0 <container-name> [image-name]}"
IMAGE_NAME="${2:-ubuntu-salt}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MINION_CONFIG="${SCRIPT_DIR}/../salt/minion.production"

if [[ ! -f "$MINION_CONFIG" ]]; then
    echo "Error: minion.production not found at $MINION_CONFIG"
    exit 1
fi

echo "Creating container '$CONTAINER_NAME' from image '$IMAGE_NAME'..."
incus launch "$IMAGE_NAME" "$CONTAINER_NAME"

echo "Waiting for container to start..."
sleep 2

echo "Copying minion configuration..."
incus file push "$MINION_CONFIG" "$CONTAINER_NAME/etc/salt/minion"

echo "Enabling and starting salt-minion..."
incus exec "$CONTAINER_NAME" -- systemctl enable salt-minion
incus exec "$CONTAINER_NAME" -- systemctl start salt-minion

echo "Done. Container '$CONTAINER_NAME' is running with salt-minion connected to master."
echo "Accept the key on master: salt-key -a $CONTAINER_NAME"
