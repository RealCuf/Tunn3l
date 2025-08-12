[توضیحات فارسی](/README-fa.md)

<p align="center">
  <img width="600px" src="https://i.postimg.cc/L8mBhMP5/Chat-GPT-Image-Aug-11-2025-01-00-36-AM.png" alt="Tunn3l Logo">

**Advanced VXLAN Tunnel Management Script for Linux Servers**  
**Based on Lena Tunnel — This project is a fork of Lena Tunnel**


[![](https://img.shields.io/github/v/release/RealCuf/Tunn3l.svg)](https://github.com/RealCuf/Tunn3l/releases)
[![Downloads](https://img.shields.io/github/downloads/RealCuf/Tunn3l/total.svg)](#)
![Languages](https://img.shields.io/github/languages/top/RealCuf/Tunn3l.svg?color=green)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?color=lightgrey)](https://opensource.org/licenses/MIT)


> **Disclaimer:** This project is only for personal learning and communication, please do not use it for illegal
> purposes, please do not use it in a production environment

**If this project is helpful to you, you may wish to give it a** :star2:

---

## **What is Tunn3l?**

> Tunn3l is a fast, lightweight, and intelligent tunneling solution built on the powerful VXLAN technology, combined with automated traffic management through HAProxy. It is designed to automatically create and manage secure network tunnels without complex > configurations, delivering traffic with minimal latency and maximum efficiency. Tunn3l is an ideal choice for professionals seeking a reliable, low-resource, and high-performance networking solution.


## **Key Features of Tunn3l (New Version):**

🚀 **VXLAN-Based Tunneling:** Utilizes advanced network virtualization to create secure, stable, and high-speed tunnels between servers.

🌐 **IPv4 & IPv6 Support:** Seamless tunneling even under IPv6 restrictions or in dual-stack environments.

⚙️ **Easy Setup with HAProxy:** Automatically creates and manages tunnels using the powerful HAProxy load balancer.

💡 **Minimal Resource Usage:** Designed for optimal performance while consuming minimal CPU and memory.

📊 **Interactive Dialog UI:** Full tunnel configuration, role selection, IP setup, and service management in a user-friendly terminal-based interface.

🔄 **Automated Service Management with systemd:** Creates smart systemd services and timers for periodic tunnel restarts to maintain stable connections.

📡 **Intelligent Tunnel Monitoring:** Continuously checks VXLAN connectivity using a ping monitoring script and logs the results.

🛠 **Advanced Management:** Edit, delete, or update the script directly from GitHub with just a few clicks.

⚡ **BBR Support:** One-click installation of the BBR congestion control algorithm for improved speed and reduced latency.

---

## **Installation**

```bash
bash <(curl -Ls https://raw.githubusercontent.com/RealCuf/Tunn3l/refs/heads/main/install.sh)
```

## Tunnel Monitoring
> This script installs a helper utility named ping_monitor.sh which periodically (every 30 seconds) pings the tunnel’s remote IP and logs the results to:

```
/var/log/vxlan_ping.log
```

To view logs in real-time:

```bash
tail -f /var/log/vxlan_ping.log
```

To manually run the monitoring script:
```bash
/usr/local/bin/ping_monitor.sh <remote_ip>
```

---

## Thanks To

- [@MrAminiDev](https://github.com/MrAminiDev) for the core project

## Stargazers over Time

[![Stargazers over time](https://starchart.cc/RealCuf/tunn3l.svg?variant=adaptive)](https://starchart.cc/RealCuf/tunn3l)
