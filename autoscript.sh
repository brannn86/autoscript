#!/bin/bash
python /home/student/Code/app.py

# Define color codes
RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
YELLOW="$(tput setaf 3)"
BLUE="$(tput setaf 4)"
NC="$(tput sgr0)" # No Color

# logging & kirim email
LOGFILE="/var/log/security_audit.log"
NMAP_REPORT="var/log/nmap_report.log"

# intro
cat << "EOF"
   ___       __                   _      __            __ 
  / _ |__ __/ /____  ___ ________(_)__  / /_      ___ / / 
 / __ / // / __/ _ \(_-</ __/ __/ / _ \/ __/ _   (_-</ _ \
/_/ |_\_,_/\__/\___/___/\__/_/ /_/ .__/\__/ (_) /___/_//_/
                                /_/                       
EOF

# update pkg
update_packages() {
    echo -e "${BLUE}Updating package lists...${NC}"
    sudo apt update
    echo -e "${BLUE}Upgrading installed packages...${NC}"
    sudo apt upgrade -y
    echo -e "${BLUE}Autoremove unnecessary packages...${NC}"
    sudo apt autoremove -y
    echo -e "${GREEN}Package update complete.${NC}"
}

read -p "${YELLOW}Do you want to update the system packages? (y/n): ${NC}" answer

case ${answer:0:1} in
    y|Y )
        update_packages
    ;;
    * )
        echo "${RED}Update canceled.${NC}"
    ;;
esac

# run unattended-upgrades
{
    echo "${BLUE}Running unattended-upgrades...${NC}"
    sudo unattended-upgrades -d
} 2>&1 | tee -a "$LOGFILE"

# install lynis check
if ! command -v lynis &> /dev/null;
    then 
    {
    echo "${BLUE}Lynis not installed. Installing Lynis...${NC}"
    sudo apt-get install -y lynis
    } 2>&1 | tee -a "$LOGFILE"
fi

# run lynis
{
    echo "${BLUE}Running Lynis audit...${NC}"
    sudo lynis audit system >> $LYNIS_REPORT 2>&1
} 2>&1 | tee -a "$LOGFILE"

read -p "${YELLOW}Do you want to apply fixes according to Lynis report? (y/n): ${NC}" answer

case ${answer:0:1} in
    y|Y )
        python3 app.py
    ;;
    * )
        echo "${RED}Autofix skipped.${NC}"
    ;;
esac

# # Parse Lynis report and apply automatic fixes (example)
# LYNIS_REPORT="/var/log/lynis-report.dat"

# # Parse Lynis report and apply automatic fixes
# if [ -f "$LYNIS_REPORT" ]; then
#     echo "Parsing Lynis report and applying fixes..." | tee -a $LOGFILE

#     # Example: Fix SSH root login if reported
#     if grep -q "SSH-7412" "$LYNIS_REPORT"; then
#         echo "Disabling SSH root login..." | tee -a $LOGFILE
#         sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
#         sudo systemctl restart sshd
#     fi

#     # Example: Configure firewall if suggested
#     if grep -q "FIRE-4590" "$LYNIS_REPORT"; then
#         echo "Configuring firewall..." | tee -a $LOGFILE
#         sudo apt-get install -y ufw
#         sudo ufw enable
#         sudo ufw default deny incoming
#         sudo ufw default allow outgoing
#         sudo ufw allow ssh
#         sudo ufw reload
#     fi

#     # Example: Set secure permissions for /tmp if suggested
#     if grep -q "FILE-6310" "$LYNIS_REPORT"; then
#         echo "Setting secure permissions for /tmp..." | tee -a $LOGFILE
#         sudo mount -o remount,noexec,nosuid,nodev /tmp
#     fi

#     # Add more fixes based on Lynis report findings
#     # ...

# fi

# # Network scanning with Nmap (Example, can be expanded)
# {
#     echo "Running network scan with Nmap..."
#     nmap -sP 192.168.1.0/24 >> $NMAP_REPORT 2>&1
# }  2>&1 | tee -a "$LOGFILE"

# # Monitor logs for suspicious activities using Fail2ban
# echo "Monitoring logs for suspicious activities..." | tee -a $LOGFILE
# sudo systemctl start fail2ban

# end
echo "${BLUE}Scanning completed.${NC}"