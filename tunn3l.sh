#!/bin/bash

BASE_DIR="$HOME/tunn3l"
NODES_DIR="$BASE_DIR/nodes"
BINARY="$BASE_DIR/psiphon-tunnel-core"

mkdir -p "$NODES_DIR"
chmod +x "$BINARY"

create_node() {
  read -p "Enter node name: " name
  read -p "Enter LocalHttpProxyPort (e.g. 8081): " http_port
  read -p "Enter LocalSocksProxyPort (e.g. 1081): " socks_port

  DIR="$NODES_DIR/$name"
  mkdir -p "$DIR"

  cat > "$DIR/config.json" <<EOF
{
  "LocalHttpProxyPort": $http_port,
  "LocalSocksProxyPort": $socks_port,
  "EgressRegion": "US",
  "PropagationChannelId": "FFFFFFFFFFFFFFFF",
  "RemoteServerListDownloadFilename": "remote_server_list",
  "RemoteServerListSignaturePublicKey": "MIICIDANBgkqhkiG9w0BAQEFAAOCAg0AMIICCAKCAgEAt7Ls+/39r+T6zNW7GiVpJfzq/xvL9SBH5rIFnk0RXYEYavax3WS6HOD35eTAqn8AniOwiH+DOkvgSKF2caqk/y1dfq47Pdymtwzp9ikpB1C5OfAysXzBiwVJlCdajBKvBZDerV1cMvRzCKvKwRmvDmHgphQQ7WfXIGbRbmmk6opMBh3roE42KcotLFtqp0RRwLtcBRNtCdsrVsjiI1Lqz/lH+T61sGjSjQ3CHMuZYSQJZo/KrvzgQXpkaCTdbObxHqb6/+i1qaVOfEsvjoiyzTxJADvSytVtcTjijhPEV6XskJVHE1Zgl+7rATr/pDQkw6DPCNBS1+Y6fy7GstZALQXwEDN/qhQI9kWkHijT8ns+i1vGg00Mk/6J75arLhqcodWsdeG/M/moWgqQAnlZAGVtJI1OgeF5fsPpXu4kctOfuZlGjVZXQNW34aOzm8r8S0eVZitPlbhcPiR4gT/aSMz/wd8lZlzZYsje/Jr8u/YtlwjjreZrGRmG8KMOzukV3lLmMppXFMvl4bxv6YFEmIuTsOhbLTwFgh7KYNjodLj/LsqRVfwz31PgWQFTEPICV7GCvgVlPRxnofqKSjgTWI4mxDhBpVcATvaoBl1L/6WLbFvBsoAUBItWwctO2xalKxF5szhGm8lccoc5MZr8kfE0uxMgsxz4er68iCID+rsCAQM=",
  "RemoteServerListUrl": "https://s3.amazonaws.com//psiphon/web/mjr4-p23r-puwl/server_list_compressed",
  "SponsorId": "FFFFFFFFFFFFFFFF",
  "UseIndistinguishableTLS": true
}
EOF

  echo "[+] Node '$name' created with HTTP port $http_port and SOCKS port $socks_port"
}

start_node() {
  read -p "Enter node name to start: " name
  DIR="$NODES_DIR/$name"

  if [[ -f "$DIR/config.json" ]]; then
    nohup "$BINARY" -config "$DIR/config.json" > "$DIR/log.txt" 2>&1 &
    echo $! > "$DIR/pid.txt"
    echo "[+] Node '$name' started."
  else
    echo "[-] Node '$name' not found!"
  fi
}

stop_node() {
  read -p "Enter node name to stop: " name
  DIR="$NODES_DIR/$name"

  if [[ -f "$DIR/pid.txt" ]]; then
    kill "$(cat "$DIR/pid.txt")"
    rm "$DIR/pid.txt"
    echo "[+] Node '$name' stopped."
  else
    echo "[-] PID file not found for node '$name'"
  fi
}

list_nodes() {
  echo "[*] Available nodes:"
  ls "$NODES_DIR"
}

menu() {
  echo
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
