#!/usr/bin/bash

# Note that values here are hardcoded right now

# sudo pkill hostapd
# sudo pkill dnsmasq
# sudo sysctl -w net.ipv4.ip_forward=0

# Stop services
sudo pkill dnsmasq
sudo killall -9 hostapd

# Disable forwarding
sudo sysctl -w net.ipv4.ip_forward=0

# Flush iptables
sudo iptables -F
sudo iptables -t nat -F

# Remove AP interface
sudo ip link set wlan0_ap down
sudo iw dev wlan0_ap del