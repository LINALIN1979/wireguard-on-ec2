#!/bin/bash
source config.sh
source tools.sh


get_max_peer_ip() {
    # Find max peer IP in /etc/wireguard/wg0.conf
    max_ip=""
    max_num=0
    ip_list=( $(find_section_key "/etc/wireguard/wg0.conf" "Peer" "AllowedIPs") )
    for ip in "${ip_list[@]}"; do
        ip=$(echo $ip | awk -F"/" '{print $1}')
        num=$(ip_to_number "$ip")
        if [ "$num" -gt "$max_num" ]; then
            max_num=$num
            max_ip=$ip
        fi
    done
    echo $max_ip
}


sudo_check
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <username>"
    exit 1
fi
username=$1
if [ -d "$username" ]; then
    echo "User '$username' was created"
    exit 1
fi
file_prefix=client_${username}

mkdir -p $username
pushd $username

wg genkey | tee client_privatekey | wg pubkey > client_publickey

server_config="/etc/wireguard/wg0.conf"
IP_SERVER=$(echo $IP | awk -F"/" '{print $1}')
IP_MASK=$(echo $IP | awk -F"/" '{print $2}')
max_client_ip=$(get_max_peer_ip)
[ -z "$max_client_ip" ] && max_client_ip=$IP_SERVER
max_client_ip_number=$(ip_to_number "$max_client_ip")
new_client_ip_number=$(( max_client_ip_number + 1 ))
new_client_ip=$(number_to_ip $new_client_ip_number)

# Create client.conf
cat <<EOF > ${file_prefix}.conf 
[Interface]
PrivateKey = `cat client_privatekey`
Address = $new_client_ip/$IP_MASK
DNS = $DNS

[Peer]
PublicKey = `cat /etc/wireguard/server_publickey`
Endpoint = `curl -s http://checkip.amazonaws.com`:$PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepAlive = 15
EOF

# Generate QR code of client.conf
[ -z "`sudo apt list --installed | grep qrencode`" ] && sudo apt install qrencode -y
qrencode -t png -o ${file_prefix}_qrcode.png < ${file_prefix}.conf

# Add client to /etc/wireguard/wg0.conf
content="PublicKey = `cat client_publickey`
AllowedIPs = $new_client_ip/32"
add_section "$server_config" "Peer" "$content"

popd


sudo systemctl restart wg-quick@wg0
sudo systemctl enable wg-quick@wg0
