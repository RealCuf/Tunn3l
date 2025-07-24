#!/bin/bash

read -p "Are you sure you want to delete ALL nodes? (yes/no): " answer
if [[ "$answer" == "yes" ]]; then
  rm -rf ~/tunn3l/nodes/*
  echo "[+] All nodes deleted."
else
  echo "[-] Aborted."
fi
