#!/bin/bash
source tools.sh


sudo_check
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <username>"
    exit 1
fi
username=$1
if [ ! -d "$username" ]; then
    echo "User '$username' doesn't exist"
    exit 1
fi

pushd $username
client_publickey=`cat client_publickey`
del_section_by_key_value "/etc/wireguard/wg0.conf" "PublicKey" "$client_publickey"
popd
rm -rf $username

sudo systemctl restart wg-quick@wg0
sudo systemctl enable wg-quick@wg0
