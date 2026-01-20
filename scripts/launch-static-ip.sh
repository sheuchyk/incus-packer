#!/bin/bash
set -e

show_help() {
    echo "Usage: $0 <container-name> [options]"
    echo ""
    echo "Options:"
    echo "  -i, --image <name>      Image name (default: ubuntu-salt)"
    echo "  -a, --ip <address>      Static IP address (e.g., 10.0.0.100)"
    echo "  -g, --gateway <address> Gateway address (e.g., 10.0.0.1)"
    echo "  -n, --netmask <mask>    Network mask (default: 24)"
    echo "  -d, --dns <servers>     DNS servers (default: 8.8.8.8,8.8.4.4)"
    echo "  -N, --network <name>    Incus network name (default: incusbr0)"
    echo "  -p, --profile <name>    Incus profile to use"
    echo "  -h, --help              Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 mycontainer -a 10.0.0.100 -g 10.0.0.1"
    echo "  $0 mycontainer -i debian-salt -a 192.168.1.50 -g 192.168.1.1 -n 24"
}

CONTAINER_NAME=""
IMAGE_NAME="ubuntu-salt"
STATIC_IP=""
GATEWAY=""
NETMASK="24"
DNS_SERVERS="8.8.8.8,8.8.4.4"
NETWORK="incusbr0"
PROFILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--image)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -a|--ip)
            STATIC_IP="$2"
            shift 2
            ;;
        -g|--gateway)
            GATEWAY="$2"
            shift 2
            ;;
        -n|--netmask)
            NETMASK="$2"
            shift 2
            ;;
        -d|--dns)
            DNS_SERVERS="$2"
            shift 2
            ;;
        -N|--network)
            NETWORK="$2"
            shift 2
            ;;
        -p|--profile)
            PROFILE="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            if [[ -z "$CONTAINER_NAME" ]]; then
                CONTAINER_NAME="$1"
            else
                echo "Unexpected argument: $1"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$CONTAINER_NAME" ]]; then
    echo "Error: Container name is required"
    show_help
    exit 1
fi

PROFILE_ARGS=""
if [[ -n "$PROFILE" ]]; then
    PROFILE_ARGS="-p $PROFILE"
fi

echo "Creating container '$CONTAINER_NAME' from image '$IMAGE_NAME'..."
incus launch "$IMAGE_NAME" "$CONTAINER_NAME" $PROFILE_ARGS

echo "Waiting for container to start..."
sleep 3

if [[ -n "$STATIC_IP" ]]; then
    if [[ -z "$GATEWAY" ]]; then
        echo "Error: Gateway (-g) is required when using static IP"
        incus delete "$CONTAINER_NAME" --force
        exit 1
    fi

    echo "Configuring static IP: $STATIC_IP/$NETMASK (gateway: $GATEWAY)..."

    OS_ID=$(incus exec "$CONTAINER_NAME" -- cat /etc/os-release 2>/dev/null | grep "^ID=" | cut -d= -f2 | tr -d '"')

    if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" ]]; then
        incus exec "$CONTAINER_NAME" -- bash -c "cat > /etc/netplan/50-static.yaml << EOF
network:
  version: 2
  ethernets:
    eth0:
      addresses:
        - ${STATIC_IP}/${NETMASK}
      routes:
        - to: default
          via: ${GATEWAY}
      nameservers:
        addresses: [${DNS_SERVERS//,/, }]
EOF"
        incus exec "$CONTAINER_NAME" -- chmod 600 /etc/netplan/50-static.yaml
        incus exec "$CONTAINER_NAME" -- rm -f /etc/netplan/10-incus.yaml 2>/dev/null || true
        incus exec "$CONTAINER_NAME" -- netplan apply
    else
        echo "Error: Unsupported OS '$OS_ID'. Only Ubuntu and Debian are supported."
        incus delete "$CONTAINER_NAME" --force
        exit 1
    fi

    echo "Setting Incus network device to use static IP..."
    incus config device override "$CONTAINER_NAME" eth0 ipv4.address="$STATIC_IP"

    echo "Static IP configured successfully."
fi

echo ""
echo "Container '$CONTAINER_NAME' is running."
if [[ -n "$STATIC_IP" ]]; then
    echo "  IP Address: $STATIC_IP/$NETMASK"
    echo "  Gateway: $GATEWAY"
    echo "  DNS: $DNS_SERVERS"
fi
echo ""
echo "Access: incus exec $CONTAINER_NAME -- bash"
