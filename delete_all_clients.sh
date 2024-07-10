#!/bin/bash
source tools.sh

sudo_check
del_section "/etc/wireguard/wg0.conf" "Peer"
find "./" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -exec rm -rf {} +
sudo systemctl restart wg-quick@wg0
sudo systemctl enable wg-quick@wg0