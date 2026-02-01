#!/usr/bin/bash

set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# TODO: Check if required packages are installed

# Loads .env
ENV="$DIR/../.env"
if [ -f "$ENV" ]; then
    source "$ENV"
fi

# Finds prerequisites
MODES=$(iw list | awk '/Supported interface modes:/{f=1} /Band/{exit} f{print}')

SUPPORT_AP=$(echo "$MODES" | grep -i 'AP')
if [ -z "$SUPPORT_AP" ]; then
    echo "AP mode not supported!"
    exit
fi

SUPPORT_STA=$(echo "$MODES" | grep -i 'managed')
if [ -z "$SUPPORT_STA" ]; then
    echo "STA not supported!"
    exit
fi

# NOTE: Should also check supported interfaces per channel or something
COMBINATIONS=$(iw list | grep -i -A 5 'valid')
# echo "$COMBINATIONS"

echo "Required interfaces (AP && STA) found!" # Prerequisites are good!!

# Finds uplink interface (Should normally return only one)
UPLINK=$(ip route | awk '/default/ {
    for(i=1;i<NF;i++) {
        if($i=="dev") {
            print $(i+1); exit
        }
    }
}')

# TODO: Allow user to enter one
if [ -z "$UPLINK" ]; then 
    echo "No UPLINK interface found! Exiting..."
    exit
fi

echo "$UPLINK"

# Find router's channel
CHANNEL=$(iw dev "$UPLINK" info | awk '{
    for(i=1;i<NF;i++) {
        if($i=="channel") {
            print $(i+1); exit
        }
    }
}')

if [ -z "$CHANNEL" ]; then
    echo "Cannot detect uplink channel. Exiting..."
    exit
fi

echo "$CHANNEL"

# Checks if a virtual access point already exists
VAP_NAME="${UPLINK}_ap"
if iw dev "$VAP_NAME" info &>/dev/null; then
    echo "A virtual interface for $UPLINK (named $VAP_NAME) already exists! Deleting..."
    sudo iw dev "$VAP_NAME" del
fi 

# Creates the virtual access point and its config
sudo iw dev "$UPLINK" interface add "$UPLINK"_ap type __ap

# Creates hostapd config
TEMP_DIR="$DIR/../temp"
mkdir -p "$TEMP_DIR"

CONF="$TEMP_DIR/hostapd.conf"
cat > "$CONF" <<EOF
interface=$VAP_NAME
driver=nl80211
ssid=$SSID
hw_mode=g
channel=$CHANNEL
wpa=2
wpa_passphrase=$PSWD
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
EOF

chmod 600 "$CONF"

# Assign IP address to Virtual AP and enables it
sudo ip addr flush dev "$VAP_NAME" || true # Flushes first for sanity
sudo ip addr add 192.168.50.1/24 dev "$VAP_NAME"

# Starts hostapd in background
# NOTE: hostapd takes care of bringing the interface up
#       so no need to do `sudo ip link set "$VAP_NAME" up`

sudo hostapd "$CONF" &

# Starts DHCP Server in background (Assigns an IP to connected devices)
sudo dnsmasq \
    --interface="$VAP_NAME" \
    --bind-interfaces \
    --dhcp-range=192.168.50.10,192.168.50.100,12h \
    --no-resolv &

# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Sets up NAT while ensuring that rules are not duplicated
sudo iptables -t nat -C POSTROUTING -o "$UPLINK" -j MASQUERADE 2>/dev/null || \
sudo iptables -t nat -A POSTROUTING -o "$UPLINK" -j MASQUERADE

sudo iptables -C FORWARD -i "$VAP_NAME" -o "$UPLINK" -j ACCEPT 2>/dev/null || \
sudo iptables -A FORWARD -i "$VAP_NAME" -o "$UPLINK" -j ACCEPT

sudo iptables -C FORWARD -i "$UPLINK" -o "$VAP_NAME" -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || \
sudo iptables -A FORWARD -i "$UPLINK" -o "$VAP_NAME" -m state --state ESTABLISHED,RELATED -j ACCEPT

# Should be all good by this point!
# Starts virtual access point