#!/bin/bash
source config.sh
source tools.sh


sudo_check

if [ -z "`sudo apt list --installed | grep wireguard`" ]; then
    sudo apt update
    sudo apt install wireguard -y
fi

pushd /etc/wireguard

umask 077
[ ! -f "server_privatekey" ] && wg genkey | tee server_privatekey | wg pubkey > server_publickey

default_if_name=$(ip route | grep '^default' | awk '{print $5}')
cat <<EOF > wg0.conf
[Interface]
Address = $IP
ListenPort = $PORT
PrivateKey = `cat server_privatekey`
PostUp   = echo 1 > /proc/sys/net/ipv4/ip_forward; iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -s $IP -o $default_if_name -j MASQUERADE
PostDown = echo 0 > /proc/sys/net/ipv4/ip_forward; iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -s $IP -o $default_if_name -j MASQUERADE
EOF

popd

iptables_input_policy=$(sudo iptables -S INPUT | grep '\-P INPUT' | awk '{print $3}')
if [ "$iptables_input_policy" != "ACCEPT" ]; then
    iptables -C INPUT -p udp --dport $PORT -j ACCEPT || iptables -I INPUT -p udp --dport $PORT -j ACCEPT
fi

sudo systemctl restart wg-quick@wg0
sudo systemctl enable wg-quick@wg0
