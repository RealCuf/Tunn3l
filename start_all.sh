#!/bin/bash

BASE_DIR="$HOME/tunn3l"
BINARY="$BASE_DIR/psiphon-tunnel-core"

for dir in "$BASE_DIR/nodes/"*/; do
  if [[ -f "$dir/config.json" ]]; then
    echo "[*] Starting node: $(basename "$dir")"
    nohup "$BINARY" -config "$dir/config.json" > "$dir/log.txt" 2>&1 &
  fi
done
echo "[+] All nodes started."
