#!/bin/bash

# ---------------- CHECK ROOT ----------------
if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}[!] This script must be run as root.${NC}"
    echo -e "${YELLOW}[!] Please use 'sudo' or switch to root user.${NC}"
    exit 1
fi

# ---------------- DEPENDENCY CHECK ----------------
if ! command -v dialog &>/dev/null; then
    apt-get update -qq
    apt-get install -y dialog
fi

# ---------------- GLOBAL VARIABLES ----------------
VNI=88
VXLAN_IF="vxlan${VNI}"
PING_MONITOR_SCRIPT="/usr/local/bin/ping_monitor.sh"
BRIDGE_SCRIPT="/usr/local/bin/vxlan_bridge.sh"
HAPROXY_CFG="/etc/haproxy/haproxy.cfg"

# ---------------- INSTALL PING MONITOR ----------------
install_ping_monitor() {
    cat <<'EOF' > "$PING_MONITOR_SCRIPT"
#!/bin/bash

REMOTE_IP="$1"
LOG_FILE="/var/log/vxlan_ping.log"

if [[ -z "$REMOTE_IP" ]]; then
    echo "Usage: $0 <remote_ip>"
    exit 1
fi

while true; do
    ping -c 1 "$REMOTE_IP" > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $REMOTE_IP is reachable" >> "$LOG_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $REMOTE_IP is unreachable" >> "$LOG_FILE"
    fi
    sleep 30
done
EOF
    chmod +x "$PING_MONITOR_SCRIPT"
}

# ---------------- INSTALL VXLAN TUNNEL ----------------
install_vxlan_tunnel() {
    exec 3>&1
    ROLE=$(dialog --clear --title "Select Server Role" --menu "Choose server role:" 10 40 2 \
        1 "Iran" 2 "Kharej" 2>&1 1>&3)
    exec 3>&-

    if [[ "$ROLE" != "1" && "$ROLE" != "2" ]]; then
        dialog --msgbox "Invalid role selected." 5 30
        return
    fi

    exec 3>&1
    IRAN_IP=$(dialog --inputbox "Enter IRAN IP (IPv4 or IPv6):" 8 60 2>&1 1>&3)
    exec 3>&-
    exec 3>&1
    KHAREJ_IP=$(dialog --inputbox "Enter Kharej IP (IPv4 or IPv6):" 8 60 2>&1 1>&3)
    exec 3>&-

    while true; do
        exec 3>&1
        DSTPORT=$(dialog --inputbox "Enter tunnel port (1-64435):" 8 40 2>&1 1>&3)
        exec 3>&-
        if [[ "$DSTPORT" =~ ^[0-9]+$ ]] && (( DSTPORT >= 1 && DSTPORT <= 64435 )); then
            break
        else
            dialog --msgbox "Invalid port. Please try again." 5 40
        fi
    done

    exec 3>&1
    HAPROXY_CHOICE=$(dialog --menu "Port forwarding via HAProxy?" 7 40 2 \
        1 "Yes" 2 "No" 2>&1 1>&3)
    exec 3>&-

    if [[ "$ROLE" == "1" ]]; then
        VXLAN_IP="30.0.0.1/24"
        REMOTE_IP="$KHAREJ_IP"
    else
        VXLAN_IP="30.0.0.2/24"
        REMOTE_IP="$IRAN_IP"
    fi

    INTERFACE=$(ip route get 1.1.1.1 | awk '{print $5}' | head -n1)

    if [[ "$VXLAN_IP" == *":"* ]]; then
        # IPv6 local IP
        LOCAL_IP=$(hostname -I | tr ' ' '\n' | grep ':.*' | head -n1)
    else
        # IPv4 local IP
        LOCAL_IP=$(hostname -I | awk '{print $1}')
    fi

    ip link del "$VXLAN_IF" 2>/dev/null || true

    ip link add "$VXLAN_IF" type vxlan id "$VNI" local "$LOCAL_IP" remote "$REMOTE_IP" dev "$INTERFACE" dstport "$DSTPORT" nolearning

    if [[ "$VXLAN_IP" == *":"* ]]; then
        ip -6 addr add "$VXLAN_IP" dev "$VXLAN_IF"
    else
        ip addr add "$VXLAN_IP" dev "$VXLAN_IF"
    fi

    ip link set "$VXLAN_IF" up

    if [[ "$VXLAN_IP" == *":"* ]]; then
        # IPv6 rules
        ip6tables -I INPUT 1 -p udp --dport "$DSTPORT" -j ACCEPT
        ip6tables -I INPUT 1 -s "$REMOTE_IP" -j ACCEPT
        ip6tables -I INPUT 1 -s "${VXLAN_IP%/*}" -j ACCEPT
    else
        # IPv4 rules
        iptables -I INPUT 1 -p udp --dport "$DSTPORT" -j ACCEPT
        iptables -I INPUT 1 -s "$REMOTE_IP" -j ACCEPT
        iptables -I INPUT 1 -s "${VXLAN_IP%/*}" -j ACCEPT
    fi

    # Write bridge script
    cat <<EOF > "$BRIDGE_SCRIPT"
#!/bin/bash
ip link add $VXLAN_IF type vxlan id $VNI local $LOCAL_IP remote $REMOTE_IP dev $INTERFACE dstport $DSTPORT nolearning
if [[ "$VXLAN_IP" == *":"* ]]; then
    ip -6 addr add "$VXLAN_IP" dev $VXLAN_IF
else
    ip addr add "$VXLAN_IP" dev $VXLAN_IF
fi
ip link set $VXLAN_IF up
if ! pgrep -f "ping_monitor.sh $REMOTE_IP" > /dev/null; then
    $PING_MONITOR_SCRIPT "$REMOTE_IP" &
fi
EOF
    chmod +x "$BRIDGE_SCRIPT"

    # Create systemd service and timer
    cat <<EOF > /etc/systemd/system/vxlan-tunnel.service
[Unit]
Description=VXLAN Tunnel Interface
After=network.target

[Service]
ExecStart=$BRIDGE_SCRIPT
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    cat <<EOF > /etc/systemd/system/vxlan-tunnel-restart.service
[Unit]
Description=Restart VXLAN tunnel service

[Service]
Type=oneshot
ExecStart=/bin/systemctl restart vxlan-tunnel.service
EOF

    cat <<EOF > /etc/systemd/system/vxlan-tunnel-restart.timer
[Unit]
Description=Timer to restart VXLAN tunnel service every 1 hour

[Timer]
OnBootSec=5min
OnUnitActiveSec=1h
Persistent=true

[Install]
WantedBy=timers.target
EOF

    systemctl daemon-reload
    systemctl enable vxlan-tunnel.service vxlan-tunnel-restart.timer
    systemctl start vxlan-tunnel.service vxlan-tunnel-restart.timer

    # If user chose HAProxy, install/configure it
    if [[ "$HAPROXY_CHOICE" == "1" ]]; then
        install_haproxy_and_configure "$DSTPORT"
    fi

    dialog --msgbox "VXLAN tunnel setup completed successfully." 6 40
    dialog --msgbox "\
    VXLAN tunnel setup completed successfully.
    
    Interface: $VXLAN_IF
    VXLAN IP: $VXLAN_IP
    Remote IP: $REMOTE_IP
    Port: $DSTPORT
    " 12 60
}

# ---------------- UNINSTALL VXLAN TUNNEL ----------------
uninstall_all_vxlan() {
    ip link show | grep -o 'vxlan[0-9]\+' | while read -r iface; do
        ip link del "$iface" 2>/dev/null
    done

    systemctl stop haproxy vxlan-tunnel vxlan-tunnel-restart.timer vxlan-tunnel-restart.service 2>/dev/null
    systemctl disable haproxy vxlan-tunnel vxlan-tunnel-restart.timer vxlan-tunnel-restart.service 2>/dev/null

    rm -f /usr/local/bin/vxlan_bridge.sh /usr/local/bin/ping_monitor.sh /etc/systemd/system/vxlan-tunnel.service /etc/systemd/system/vxlan-tunnel-restart.service /etc/systemd/system/vxlan-tunnel-restart.timer

    systemctl daemon-reload

    apt-get remove -y haproxy -qq
    apt-get purge -y haproxy -qq
    apt-get autoremove -y 2>/dev/null

    crontab -l 2>/dev/null | grep -v 'systemctl restart haproxy' | grep -v 'systemctl restart vxlan-tunnel' > /tmp/cron_tmp || true
    crontab /tmp/cron_tmp
    rm /tmp/cron_tmp

    dialog --msgbox "All VXLAN tunnels and related services removed." 6 50
}

# ---------------- EDIT VXLAN TUNNEL ----------------
edit_vxlan_tunnel() {
    if [[ ! -f "$BRIDGE_SCRIPT" ]]; then
        dialog --msgbox "No existing tunnel configuration found." 6 40
        return
    fi

    CUR_REMOTE=$(grep -oP 'remote \K[^ ]+' "$BRIDGE_SCRIPT")
    CUR_LOCAL=$(grep -oP 'addr add \K[^ ]+' "$BRIDGE_SCRIPT")
    CUR_PORT=$(grep -oP 'dstport \K[^ ]+' "$BRIDGE_SCRIPT")
    VXLAN_IF=$(grep -oP 'dev \K[^ ]+' "$BRIDGE_SCRIPT" | head -n1)
    VNI=$(grep -oP 'vxlan id \K[^ ]+' "$BRIDGE_SCRIPT")

    exec 3>&1
    NEW_REMOTE=$(dialog --inputbox "Remote IP:" 8 40 "$CUR_REMOTE" 2>&1 1>&3)
    exec 3>&-
    exec 3>&1
    NEW_LOCAL=$(dialog --inputbox "Local VXLAN IP:" 8 40 "$CUR_LOCAL" 2>&1 1>&3)
    exec 3>&-
    exec 3>&1
    NEW_PORT=$(dialog --inputbox "VXLAN Port:" 8 40 "$CUR_PORT" 2>&1 1>&3)
    exec 3>&-

    if [[ -z "$NEW_REMOTE" || -z "$NEW_LOCAL" || -z "$NEW_PORT" ]]; then
        dialog --msgbox "Error: All fields are required." 5 40
        return
    fi

    # Delete existing interface
    if ip link show "$VXLAN_IF" &>/dev/null; then
        ip link del "$VXLAN_IF"
    fi

    IFACE=$(ip route get 1.1.1.1 | awk '{print $5}' | head -n1)
    HOST_IP=$(hostname -I | awk '{print $1}')

    ip link add "$VXLAN_IF" type vxlan id "$VNI" local "$HOST_IP" remote "$NEW_REMOTE" dev "$IFACE" dstport "$NEW_PORT" nolearning

    if [[ "$NEW_LOCAL" == *":"* ]]; then
        ip -6 addr add "$NEW_LOCAL" dev "$VXLAN_IF"
    else
        ip addr add "$NEW_LOCAL" dev "$VXLAN_IF"
    fi

    ip link set "$VXLAN_IF" up

    # Update bridge script
    sed -i "s|remote [^ ]\+|remote $NEW_REMOTE|" "$BRIDGE_SCRIPT"
    sed -i "s|ip addr add [^ ]\+|ip addr add $NEW_LOCAL|" "$BRIDGE_SCRIPT"
    sed -i "s|dstport [^ ]\+|dstport $NEW_PORT|" "$BRIDGE_SCRIPT"

    # Update HAProxy if exists
    if [[ -f "$HAPROXY_CFG" ]]; then
        OLD_IP="${CUR_LOCAL%%/*}"
        NEW_IP="${NEW_LOCAL%%/*}"
        if [[ "$OLD_IP" != "$NEW_IP" ]]; then
            sed -i "s/$OLD_IP/$NEW_IP/g" "$HAPROXY_CFG"
            systemctl restart haproxy
        fi
    fi

    systemctl restart vxlan-tunnel.service

    # Start ping monitor if not running
    if ! pgrep -f "ping_monitor.sh $NEW_REMOTE" > /dev/null; then
        "$PING_MONITOR_SCRIPT" "$NEW_REMOTE" &
    fi

    dialog --msgbox "VXLAN tunnel updated successfully." 6 40
}

# ---------------- INSTALL BBR ----------------
install_bbr() {
    curl -fsSLk https://raw.githubusercontent.com/MrAminiDev/NetOptix/main/scripts/bbr.sh | bash
    dialog --msgbox "BBR installation script executed." 6 40
}

# ---------------- INSTALL HAPROXY AND CONFIGURE ----------------
install_haproxy_and_configure() {
    local PORTS=$1
    if ! command -v haproxy >/dev/null 2>&1; then
        apt-get update -qq
        apt-get install -y haproxy -qq
    fi

    mkdir -p /etc/haproxy

    BACKUP_FILE="/etc/haproxy/haproxy.cfg.bak"
    [[ -f "$HAPROXY_CFG" ]] && cp "$HAPROXY_CFG" "$BACKUP_FILE"

    cat <<EOL > "$HAPROXY_CFG"
global
    daemon
    maxconn 4096
    user haproxy
    group haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s

defaults
    mode tcp
    option dontlognull
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms
    retries 3
    option tcpka
EOL

    local LOCAL_IP=$(hostname -I | awk '{print $1}')
    IFS=',' read -ra PORT_ARR <<< "$PORTS"

    for port in "${PORT_ARR[@]}"; do
        cat <<EOL >> "$HAPROXY_CFG"

frontend frontend_$port
    bind *:$port
    default_backend backend_$port
    option tcpka

backend backend_$port
    option tcpka
    server server1 $LOCAL_IP:$port check maxconn 2048
EOL
    done

    if haproxy -c -f "$HAPROXY_CFG"; then
        systemctl enable haproxy
        systemctl restart haproxy
        dialog --msgbox "HAProxy configured and restarted successfully." 6 50
    else
        dialog --msgbox "Warning: HAProxy configuration invalid!" 6 40
    fi
}

# ---------------- CRONJOB SETTINGS ----------------
cronjob_settings() {
    while true; do
        exec 3>&1
        choice=$(dialog --clear --title "Cronjob Settings" --menu "Select an option:" 10 40 4 \
            1 "Install cronjob" \
            2 "Delete cronjob" \
            3 "Back to main menu" 2>&1 1>&3)
        exec 3>&-

        case $choice in
            1)
                while true; do
                    exec 3>&1
                    cron_hours=$(dialog --inputbox "Hours between restart? (1-24):" 8 40 2>&1 1>&3)
                    exec 3>&-
                    if [[ "$cron_hours" =~ ^[0-9]+$ ]] && (( cron_hours >=1 && cron_hours <=24 )); then
                        crontab -l 2>/dev/null | grep -v -E 'systemctl restart haproxy|systemctl restart vxlan-tunnel' > /tmp/cron_tmp || true
                        echo "0 */$cron_hours * * * systemctl restart vxlan-tunnel.service" >> /tmp/cron_tmp
                        echo "0 */$cron_hours * * * systemctl restart haproxy" >> /tmp/cron_tmp
                        crontab /tmp/cron_tmp
                        rm /tmp/cron_tmp
                        dialog --msgbox "Cronjob installed." 5 30
                        break
                    else
                        dialog --msgbox "Invalid input." 5 30
                    fi
                done
                ;;
            2)
                crontab -l 2>/dev/null | grep -v -E 'systemctl restart haproxy|systemctl restart vxlan-tunnel' > /tmp/cron_tmp || true
                crontab /tmp/cron_tmp
                rm /tmp/cron_tmp
                dialog --msgbox "Cronjob deleted." 5 30
                ;;
            3)
                break
                ;;
            *)
                dialog --msgbox "Invalid choice." 5 30
                ;;
        esac
    done
}

# ---------------- UPDATE SCRIPT ----------------
update_script() {
    TMP_DIR="/tmp/tunn3l_update"
    REPO_URL="https://github.com/RealCuf/Tunn3l.git"

    if [[ ! -d "$TMP_DIR" ]]; then
        git clone "$REPO_URL" "$TMP_DIR"
    else
        cd "$TMP_DIR" && git pull
    fi

    if [[ -f "$TMP_DIR/install.sh" ]]; then
        cp "$TMP_DIR/install.sh" /usr/local/bin/install.sh
        chmod +x /usr/local/bin/install.sh
        dialog --msgbox "Script updated successfully." 6 40
    else
        dialog --msgbox "Update failed: script file not found." 6 50
    fi
}

# ---------------- MAIN MENU ----------------
main_menu() {
    install_ping_monitor
    while true; do
        exec 3>&1
        CHOICE=$(dialog --clear --title "Tunn3l Menu" --menu "Select option:" 15 50 7 \
            1 "Install new tunnel" \
            2 "Uninstall tunnel(s)" \
            3 "Edit tunnel" \
            4 "Install BBR" \
            5 "Cronjob settings" \
            6 "Update script" \
            0 "Exit" 2>&1 1>&3)
        exec 3>&-

        case $CHOICE in
            1) install_vxlan_tunnel ;;
            2) uninstall_all_vxlan ;;
            3) edit_vxlan_tunnel ;;
            4) install_bbr ;;
            5) cronjob_settings ;;
            6) update_script ;;
            0) clear; exit 0 ;;
            *) dialog --msgbox "Invalid option." 5 30 ;;
        esac
    done
}

# ---------------- START ----------------
main_menu
