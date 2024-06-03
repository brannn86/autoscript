#!/bin/bash

# color codes
RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
YELLOW="$(tput setaf 3)"
BLUE="$(tput setaf 4)"
NC="$(tput sgr0)" # No Color

# CONFIG
ALLOWED_IP="172.17.0.2"
SSH_PORT=2222

wait_and_clear() {
    read -r
    clear
}

cat << "EOF"
  _____           _           _      _____                _                             _     
 |  __ \         (_)         | |    / ____|              | |                           | |    
 | |__) | __ ___  _  ___  ___| |_  | |     __ _ _ __  ___| |_ ___  _ __   ___       ___| |__  
 |  ___/ '__/ _ \| |/ _ \/ __| __| | |    / _` | '_ \/ __| __/ _ \| '_ \ / _ \     / __| '_ \ 
 | |   | | | (_) | |  __/ (__| |_  | |___| (_| | |_) \__ \ || (_) | | | |  __/  _  \__ \ | | |
 |_|   |_|  \___/| |\___|\___|\__|  \_____\__,_| .__/|___/\__\___/|_| |_|\___| (_) |___/_| |_|
                _/ |                           | |                                            
               |__/                            |_|                        

                                Kelompok Stuxnet
                                    Linux Security

                                        Siti Yunisa
                                            Farhan Siddiq Al Farisi
                                                Randi Hisyam Dzikroo
                                                    Gibran Ismail Hattami

EOF

wait_and_clear


# 1. ############ PERMISSIONS ##############

set_file_permissions(){
    sudo chown -R root:root /etc/ssh
    sudo chmod -R go-rwx /etc/ssh
    echo "${BLUE}Izin file direktori telah diubah.${NC}"
}

# 2. ############## FIREWALL ##############

set_firewall() {
    # terima dri ip yg sudah di tentukan
    sudo iptables -A INPUT -p tcp -s $ALLOWED_IP --dport $SSH_PORT -j ACCEPT
    echo "${BLUE}Terima koneksi dari ${NC}$ALLOWED_IP${BLUE}.${NC}"

    # tolak selain diatas
    sudo iptables -A INPUT -p tcp --dport $SSH_PORT -j REJECT
    echo "${BLUE}Tolak semua koneksi yang ingin terhubung ke port ${NC}$SSH_PORT${BLUE}, kecuali ${NC}$ALLOWED_IP${BLUE}."
}



# 3.############ SSH PART #################

change_ssh_port() {
    # Backup sshd conf
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

    sudo chmod +w /etc/ssh/sshd_config

    # ganti port
    sed -i "s/^#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
    sed -i "s/^Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config

    # Restart ssh
    sudo service sshd restart
    sudo service ssh restart

    sudo chmod -w /etc/ssh/sshd_config

    # Verify
    if grep -q "^Port $SSH_PORT" /etc/ssh/sshd_config; then
        echo "${BLUE}SSH port cdiubah ke ${NC}$SSH_PORT${BLUE}.${NC}"
    else
        echo "${RED}Gagal merubah SSH port.${NC}"
    fi

}

disable_root_login() {
    sudo chmod +w /etc/ssh/sshd_config
    sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo chmod -w /etc/ssh/sshd_config
    sudo service sshd reload
    echo "${BLUE}Root login telah dinonaktifkan.${NC}"
}





####### EXEC #######



#set_firewall           ----- done

read -p "${YELLOW}Apakah ingin konfigurasi firewall? (y/n): ${NC}" answer

case ${answer:0:1} in
    y|Y )
        # set_firewall
    ;;
    * )
        echo "${RED}Skipped.${NC}"
    ;;
esac



#change_ssh_port        ----- done

read -p "${YELLOW}Apakah ingin merubah port SSH? (y/n): ${NC}" answer

case ${answer:0:1} in
    y|Y )
        # change_ssh_port
    ;;
    * )
        echo "${RED}Skipped.${NC}"
    ;;
esac



#disable_root_login     ----- done

read -p "${YELLOW}Apakah ingin menonaktifkan root login SSH? (y/n): ${NC}" answer

case ${answer:0:1} in
    y|Y )
        # disable_root_login
    ;;
    * )
        echo "${RED}Skipped.${NC}"
    ;;
esac



#set_file_permissions   ----- done

read -p "${YELLOW}Apakah ingin merubah izin file ke root? (y/n): ${NC}" answer

case ${answer:0:1} in
    y|Y )
        # set_file_permissions
    ;;
    * )
        echo "${RED}Skipped.${NC}"
    ;;
esac




