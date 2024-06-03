#!/bin/bash

# color codes
RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
YELLOW="$(tput setaf 3)"
BLUE="$(tput setaf 4)"
NC="$(tput sgr0)" # No Color

# directories
HOME_DIR="/home/$USER"

# fungsi ubah permissions ke user yang berwenang saja
change_permissions() {
    local file="$1"
    chmod 700 "$file"
    echo "Changed permissions for $file to 700"
}

# cek semua file di home user
check_permissions() {
    echo "Checking file permissions in $HOME_DIR..."

find "$HOME_DIR" -type f | while read -r file; do
    current_permissions=$(stat -c "%a" "$file")
    if [ "$current_permissions" != "700" ]; then
        change_permissions "$file"
    else
        echo "Permissions for $file are already set to 700"
    fi
done

echo "Permission check and update complete."
}

# list ip yang diizinkan
ALLOWED_IPS=(
    "192.168.56.1/24"
    "192.168.1.64/24"
    "10.0.0.0/16"
)

# list ports
ALLOWED_PORTS=(
    "2222"  # NEW SSH
    "80"  # HTTP
    "443" # HTTPS
)

# konfigurasi firewall
configure_firewall() {
    # Flush existing rules to start fresh
    sudo iptables -F

    # Default policy to drop all incoming connections
    sudo iptables -P INPUT DROP

    # Allow established and related connections
    sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

    # Loop through allowed IPs and set rules for each
    for ip in "${ALLOWED_IPS[@]}"; do
        for port in "${ALLOWED_PORTS[@]}"; do
            sudo iptables -A INPUT -p tcp -s "$ip" --dport "$port" -j ACCEPT
        done
    done

    # Allow localhost to ensure local applications can function correctly
    sudo iptables -A INPUT -i lo -j ACCEPT

    # port opening
    # Open port 2222 for IPv4
    sudo iptables -I INPUT -p tcp -m tcp --dport 2222 -j ACCEPT

    echo "Ports 2222 is now open."

    # Port closing
    # Close port 22 (SSH) for IPv4
    sudo iptables -A INPUT -p tcp --dport 22 -j REJECT
    sudo iptables -A OUTPUT -p tcp --sport 22 -j REJECT

    echo "Ports 22 closed successfully."

    # Log dropped packets (optional, for debugging purposes)
    sudo iptables -A INPUT -j LOG --log-prefix "IPTABLES-DROP: " --log-level 4

    echo "Firewall rules updated successfully."
}

# fungsi untuk rubah port SSH default
change_ssh_port() {
    NEW_PORT=2222  # Set the desired new SSH port here
    SSH_CONFIG_FILE="/etc/ssh/sshd_config"

    # Backup the existing sshd_config file
    sudo cp "$SSH_CONFIG_FILE" "$SSH_CONFIG_FILE.bak"

    # Change the SSH port
    sudo sed -i "s/^#Port 22/Port $NEW_PORT/" "$SSH_CONFIG_FILE"

    # Restart SSH service to apply the changes
    sudo systemctl restart sshd

    echo "SSH port changed to $NEW_PORT and service restarted."
}

# Function to scan open ports using nmap
scan_open_ports() {
    SERVER_IP="192.168.56.10"  # Replace with your server's IP address

    echo "Scanning open ports on $SERVER_IP..."
    nmap -p 2222 "$SERVER_IP"
}

#check_permissions
configure_firewall
change_ssh_port
scan_open_ports