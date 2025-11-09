#!/bin/bash
# Script to automatically configure dcsim.properties for TPCC runs
# Arguments:
#   $1: Path to dcsim.properties file
#   $2: PostgreSQL server hostname/IP (optional, will auto-detect if not provided)

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_dcsim.properties> [postgres_host]"
    exit 1
fi

PROPERTIES_FILE="$1"

# Auto-detect PostgreSQL host if not provided
if [ -z "$2" ]; then
    # Try to get the primary IP address (not localhost)
    # First try to get IP from hostname
    POSTGRES_HOST=$(hostname -I | awk '{print $1}')

    # If that fails, try to get default route interface IP
    if [ -z "$POSTGRES_HOST" ]; then
        POSTGRES_HOST=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' | head -1)
    fi

    # If still no IP, fall back to localhost
    if [ -z "$POSTGRES_HOST" ]; then
        POSTGRES_HOST="localhost"
    fi

    echo "Auto-detected PostgreSQL host: $POSTGRES_HOST"
else
    POSTGRES_HOST="$2"
fi

if [ ! -f "$PROPERTIES_FILE" ]; then
    echo "Error: Properties file not found: $PROPERTIES_FILE"
    exit 1
fi

echo "Configuring TPCC properties file: $PROPERTIES_FILE"
echo "PostgreSQL server: $POSTGRES_HOST"

# Function to detect network interface for reaching PostgreSQL server
detect_network_interface() {
    local target_host="$1"

    # If localhost, use loopback
    if [ "$target_host" == "localhost" ] || [ "$target_host" == "127.0.0.1" ]; then
        echo "lo"
        return
    fi

    # Get the route to the PostgreSQL server and extract the interface
    local interface=$(ip route get "$target_host" 2>/dev/null | grep -oP 'dev \K\S+' | head -1)

    if [ -z "$interface" ]; then
        echo "Warning: Could not detect network interface, using default eth0" >&2
        echo "eth0"
    else
        echo "$interface"
    fi
}

# Function to detect block device for the current directory
detect_block_device() {
    local dir="$1"

    # Get the mount point for this directory
    local mount_point=$(df "$dir" | tail -1 | awk '{print $1}')

    # Extract device name (remove /dev/ and partition number)
    local device=$(echo "$mount_point" | sed 's|/dev/||' | sed 's/[0-9]*$//' | sed 's/p$//')

    if [ -z "$device" ]; then
        echo "Warning: Could not detect block device, using default sda" >&2
        echo "sda"
    else
        echo "$device"
    fi
}

# Detect network interface
NETWORK_INTERFACE=$(detect_network_interface "$POSTGRES_HOST")
echo "Detected network interface: $NETWORK_INTERFACE"

# Detect block device for the properties file's directory
BLOCK_DEVICE=$(detect_block_device "$(dirname "$PROPERTIES_FILE")")
echo "Detected block device: $BLOCK_DEVICE"

# Update the JDBC connection string to use the PostgreSQL server
# Match lines like: conn=jdbc:postgresql://localhost:5432/postgres
# or: conn=jdbc:postgresql://10.10.14.133:5432/postgres
sed -i "s|conn=jdbc:postgresql://[^:]*:\([0-9]*\)/\(.*\)|conn=jdbc:postgresql://${POSTGRES_HOST}:\1/\2|" "$PROPERTIES_FILE"

# Update osCollectorDevices to use detected network and block device
# Match lines like: osCollectorDevices=net_eth0 blk_sda
sed -i "s|osCollectorDevices=net_[^ ]* blk_[^ ]*|osCollectorDevices=net_${NETWORK_INTERFACE} blk_${BLOCK_DEVICE}|" "$PROPERTIES_FILE"

echo "Configuration complete!"
echo "  PostgreSQL connection: $POSTGRES_HOST"
echo "  OS Collector devices: net_${NETWORK_INTERFACE} blk_${BLOCK_DEVICE}"
