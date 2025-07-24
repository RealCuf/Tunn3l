#!/bin/bash

BASE_DIR=~/tunn3l
NODES_DIR="$BASE_DIR/nodes"
BINARY="$BASE_DIR/psiphon-tunnel-core"

mkdir -p "$NODES_DIR"

create_node() {
  read -p "Enter node name: " name
  read -p "Enter SOCKS5 port (e.g. 1080): " port

  DIR="$NODES_DIR/$name"
  mkdir -p "$DIR"

  cat > "$DIR/config.json" <<EOF
{
  "socks5ProxyPort": $port
}
EOF

  echo "[+] Node '$name' created with port $port"
}

start_node() {
  read -p "Enter node name to start: " name
  DIR="$NODES_DIR/$name"

  if [[ -f "$DIR/config.json" ]]; then
    cd "$DIR" && nohup "$BINARY" -config config.json > "$DIR/log.txt" 2>&1 &
    echo "[+] Node '$name' started."
  else
    echo "[-] Node '$name' not found!"
  fi
}

stop_node() {
  read -p "Enter node name to stop: " name
  pkill -f "$NODES_DIR/$name"
  echo "[+] Node '$name' stopped."
}

list_nodes() {
  echo "[*] Available nodes:"
  ls "$NODES_DIR"
}

menu() {
  echo "=== Tunn3l Control Menu ==="
  echo "1) Create new node"
  echo "2) Start node"
  echo "3) Stop node"
  echo "4) List nodes"
  echo "5) Exit"
  read -p "Choose an option: " opt

  case $opt in
    1) create_node ;;
    2) start_node ;;
    3) stop_node ;;
    4) list_nodes ;;
    5) exit ;;
    *) echo "Invalid option" ;;
  esac
}

while true; do
  menu
done
