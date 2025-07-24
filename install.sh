#!/bin/bash

# Create main folder
mkdir -p ~/tunn3l
cd ~/tunn3l || exit

# Create base node directory
mkdir -p nodes

# Download Psiphon binary
echo "[+] Downloading Psiphon Tunnel Core..."
wget -O psiphon-tunnel-core https://github.com/Psiphon-Labs/psiphon-tunnel-core-binaries/raw/master/linux/psiphon-tunnel-core-x86_64
chmod +x psiphon-tunnel-core

echo "[+] Installation completed."
