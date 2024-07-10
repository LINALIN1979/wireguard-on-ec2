Bash scripts for run WireGuard VPN on AWS EC2 Ubuntu VM and manipulate clients. All the scripts must run by root or sudo.

## Configuration

Most of the time you just keep the default settings. But if you want to change VPN network configuration or the host port for VPN traffic, you can modify `config.sh`.

If you change `PORT` setting, please make sure you also change the inbound rule of AWS EC2 security group.

## Usage

- `install.sh`

    Install WireGuard VPN on AWS EC2 Ubuntu VM.

- `create_client.sh`: 

    To create client profile and generate its QR code (.png).

    Usage:
    ```
    sudo ./create_client.sh <username>
    ```

    It creates a folder named as `username` to keep client key pairs, profile, and QR code.

- `delete_client.sh`

    To delete client profile.

    Usage:
    ```
    sudo ./delete_client.sh <username>
    ```

- `delete_all_clients.sh`

    To delete all client profiles.

    Usage:
    ```
    sudo ./delete_all_clients.sh
    ```
