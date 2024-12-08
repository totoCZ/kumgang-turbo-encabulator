#!/bin/bash

set -euo pipefail

# Ensure cleanup on exit or interruption
trap 'cleanup' EXIT

cleanup() {
    echo "Cleaning up... (>_<)"
    if mount | grep -q '/mnt/pwd'; then
        rm -f /mnt/pwd/pwd
        umount /mnt/pwd || echo "Failed to unmount /mnt/pwd!"
    fi
}

echo "Stopping Web3Signer service... UwU~"
systemctl stop web3signer

# Secure tmpfs mount for password storage
mkdir -p /mnt/pwd
mount -t tmpfs -o size=1m tmpfs /mnt/pwd

# Prompt for password securely
PASSWORD=$(systemd-ask-password "Please enter the secret password: ")
echo -n "$PASSWORD" > /mnt/pwd/pwd

echo "Starting Web3Signer service... OwO~"
systemctl start web3signer

# Wait for keys to load
echo "Waiting for keys to load into memory... UwU~"
TIMEOUT=60  # Max wait time in seconds
SECONDS=0
while ! docker logs systemd-web3signer 2>&1 | grep -q "Total signers (keys) currently loaded in memory: "; do
    sleep 2
    if [ $SECONDS -ge $TIMEOUT ]; then
        echo "Timeout waiting for keys to load (>_<)"
        exit 1
    fi
done

# Confirm keys are loaded
echo "$(docker logs systemd-web3signer | grep -o 'Total signers (keys) currently loaded in memory: .*')"

# Wait for Web3Signer to start
echo "Waiting for Web3Signer to start... OwO~"
SECONDS=0
while ! docker logs systemd-web3signer 2>&1 | grep -q "Runner | Web3Signer has started"; do
    sleep 2
    if [ $SECONDS -ge $TIMEOUT ]; then
        echo "Timeout waiting for Web3Signer to start (>_<)"
        exit 1
    fi
done

# Confirm Web3Signer has started
echo "$(docker logs systemd-web3signer | grep 'Runner | Web3Signer has started')"

systemctl restart teku-vc

# Securely remove the password file and unmount
#cleanup

echo "All done! \(>w<)/"
