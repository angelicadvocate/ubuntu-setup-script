#!/bin/bash

# Version: 1.0 beta

# ubuntu-quickstart - Automates Ubuntu updates, SSH setup, firewall, Docker, and useful tools.
# Adds templates for /etc/issue and MOTD. Great for fresh installs and headless systems.
#
# Copyright (C) 2025 [angelicadvocate]
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Check if we are running with root or sudo
if [[ $EUID -ne 0 ]]; then
  echo "❌ This script must be run with sudo or as the root user."
  echo "💡 Tip: Try running it again with 'sudo'"
  sleep 5
  echo "Exiting..."
  sleep 1
  exit 1
else
  echo "✅ Script is running with root or sudo access. Proceeding with setup..."
fi

# Function to check if it's Orange Pi or Ubuntu
check_os() {
  if [ -f /etc/default/orangepi-motd ] || [ -f /etc/armbian-release ] || grep -qi "Orange" /proc/device-tree/model 2>/dev/null; then
    echo "🍊 Detected Orange Pi OS (Ubuntu-based)"
    sleep 1
    os_type="orangepi"
  elif grep -q "Ubuntu" /etc/os-release; then
    echo "🐧 Detected Ubuntu or Ubuntu-based OS"
    sleep 1
    os_type="ubuntu"
  else
    echo "❌ Unknown OS. This script is intended for Ubuntu or Orange Pi only. Exiting..."
    sleep 5
    exit 1
  fi
}

# Call the check_os function to set the os_type variable
check_os

# ================= Initial Setup Script =================

# Step 1: Updates system packages (Ubuntu/Debian)
echo "Starting system update and upgrade..."
echo "Please wait. This may take a few minutes..."
sleep 2

# Install necessary packages for the script
apt install -y dialog

# Update and upgrade
apt update && apt upgrade -y

echo "System update complete."
echo

# Step 2: Set hostname
echo "⚠️ Make sure your hostname does not contain any special characters."
echo "🔤 The hostname should only contain letters, numbers, and hyphens."
echo "❌ Spaces are not allowed in hostnames."
read -rp "Enter a hostname for this device: " NEW_HOSTNAME

if [[ -n "$NEW_HOSTNAME" ]]; then
  # Check if hostname is valid (alphanumeric and hyphens only)
  if [[ ! "$NEW_HOSTNAME" =~ ^[a-zA-Z0-9-]+$ ]]; then
    echo "❌ Invalid hostname. Only alphanumeric characters and hyphens are allowed."
    exit 1
  fi
  
  hostnamectl set-hostname "$NEW_HOSTNAME"
  echo "127.0.1.1 $NEW_HOSTNAME" >> /etc/hosts
  echo "✅ Hostname set to $NEW_HOSTNAME"
else
  echo "❌ No hostname entered, skipping."
fi
echo

# Step 3: Create user with prompted password
echo "🔐 User creation process: Please provide a username and a strong password."
read -rp "Enter a new username to create: " NEW_USER

# Check if the user already exists
if id "$NEW_USER" &>/dev/null; then
  echo "❌ User '$NEW_USER' already exists, skipping user creation."
else
  # Prompt for password and confirmation
  read -s -rp "Enter password for $NEW_USER: " USER_PASS
  echo
  read -s -rp "Confirm password: " USER_PASS_CONFIRM
  echo

  # Check if passwords match
  if [[ -z "$USER_PASS" || -z "$USER_PASS_CONFIRM" ]]; then
    echo "❌ Password cannot be empty. User creation aborted."
  elif [[ "$USER_PASS" == "$USER_PASS_CONFIRM" ]]; then
    # Create user and set password
    useradd -m -s /bin/bash "$NEW_USER"
    echo "$NEW_USER:$USER_PASS" | chpasswd

    # Add user to sudo group
    usermod -aG sudo "$NEW_USER"
    echo "✅ User '$NEW_USER' created and added to sudo group."
  else
    echo "❌ Passwords do not match. User creation failed."
  fi
fi
echo

# Step 4: Disable default MOTD (for Orange Pi or Ubuntu)
if [ "$os_type" == "orangepi" ]; then
    echo "Disabling Orange Pi MOTD..."
    # Disable the default Orange Pi MOTD
    sudo sed -i 's/^ENABLE_MOTD=1/ENABLE_MOTD=0/' /etc/default/orangepi-motd

    # Disable the Orange Pi MOTD components
    sudo sed -i 's/^MOTD_DISABLE=".*"/MOTD_DISABLE="header sysinfo config"/' /etc/default/orangepi-motd

    # Disable the "Last login" message for Orange Pi
    sudo sed -i 's/^session    optional   pam_lastlog.so/# session    optional   pam_lastlog.so/' /etc/pam.d/sshd
    sudo sed -i 's/^session    optional   pam_lastlog.so/# session    optional   pam_lastlog.so/' /etc/pam.d/login
elif [ "$os_type" == "ubuntu" ]; then
    echo "Disabling Ubuntu MOTD..."
    # Disable the default Ubuntu MOTD
    sudo sed -i 's/^ENABLED=1/ENABLED=0/' /etc/default/motd-news
    sudo sed -i 's/^ENABLED=1/ENABLED=0/' /etc/default/motd
    echo "Disabling Ubuntu MOTD dynamic scripts..."
    # Disable all dynamic MOTD scripts
    sudo chmod -x /etc/update-motd.d/*

    # Clear the /etc/motd file to prevent any static messages
    echo "" | sudo tee /etc/motd > /dev/null

    # Disable the "Last login" message in PAM
    sudo sed -i 's/^session    optional   pam_lastlog.so/# session    optional   pam_lastlog.so/' /etc/pam.d/sshd
    sudo sed -i 's/^session    optional   pam_lastlog.so/# session    optional   pam_lastlog.so/' /etc/pam.d/login
else
    echo "Not an Orange Pi or Ubuntu system. Exiting..."
    exit 1
fi
echo "MOTD disabled."
############################################################################################

# Step 5: Create custom MOTD files for Orange Pi (if applicable)
# Check if the system is Orange Pi
if [ "$os_type" == "orangepi" ]; then
  echo "Creating custom MOTD files for Orange Pi..."

 # 29-custom-stats template
 cat << 'EOF' | sudo tee /etc/update-motd.d/29-custom-stats > /dev/null
#!/bin/bash

export TERM=xterm-256color

# Colors
green=$(tput setaf 2)
blue=$(tput setaf 4)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

# Uptime
uptime=$(uptime -p | sed 's/up //')

# Load average
read one five fifteen rest < /proc/loadavg

# Memory usage
mem_total=$(free -m | awk '/^Mem:/ {print $2}')
mem_used=$(free -m | awk '/^Mem:/ {print $3}')
mem_percent=$(( 100 * mem_used / mem_total ))

# Disk usage
disk_usage=$(df -h / | awk 'END{print $5 " used of " $2}')

# Additional storage mount (if used, optional)
if mountpoint -q /media/usb; then
    storage_usage=$(df -h /media/usb | awk 'END{print $5 " used of " $2}')
else
    storage_usage="Not mounted"
fi

# IP address (only showing first IPv4 address, excluding Docker and other interfaces)
ip_addr=$(hostname -I | awk '{print $1}')

# CPU Temp (Raspberry Pi/Orange Pi compatible)
cpu_temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
if [ -n "$cpu_temp_raw" ]; then
    cpu_temp=$(awk "BEGIN {printf \"%.1f°C\", $cpu_temp_raw/1000}")
else
    cpu_temp="Unavailable"
fi

# Logged in users
user_count=$(who | wc -l)

# Last Login
last_login=$(last -n 1 -R -F -w $USER | head -n 1 | awk '{print $4, $5, $7, $6}')

# Current Login Status
#current_login_status=$(last -n 1 -R -F -w $USER | head -n 1 | awk '{print $8, $9, $10}')
#if [[ "$current_login_status" == "logged" ]]; then
#  echo "User is still logged in."
#else
#  echo "User has logged out."
#fi



#printf "%*s\n" $(( (COLUMNS + ${#last_login} + 13) / 2 )) "Last login: $last_login"

# Output
echo "${blue}-----------------------------------------------------------------${reset}"
echo "         ${yellow}Load Average:${reset}${one}, ${five}, ${fifteen} (1, 5, 15 min)"
echo "       ${yellow}Memory Usage:${reset}${mem_percent}% of ${mem_total}MB"   "   ${yellow}Users Logged In:${reset} ${user_count}"
echo "   ${yellow}Disk Usage:${reset} ${disk_usage}"   "  ${yellow}USB Storage:${reset} ${storage_usage}"
echo "        ${yellow}IP Address:${reset} ${ip_addr}"   "   ${yellow}CPU Temp:${reset} ${cpu_temp}"
echo "               ${yellow}Last Login:${reset} ${last_login}"
echo "${blue}-----------------------------------------------------------------${reset}"

EOF

 # Make the file executable
 sudo chmod +x /etc/update-motd.d/29-custom-stats

 # 09-custom-header template
 cat << 'EOF' | sudo tee /etc/update-motd.d/09-custom-header > /dev/null
#!/bin/sh

export TERM=xterm-256color

USER_NAME=${USER:-$(id -un)}
UPTIME=$(uptime -p)
read one five fifteen _ < /proc/loadavg

echo "$(tput setaf 6)
                              _             _
                             | |           | |
      ___   _ __ ___   _ __  | |__    __ _ | |  ___   ___
     / _ \ | '_ \` _ \ | '_ \ | '_ \  / _\` || | / _ \ / __|
    | (_) || | | | | || |_) || | | || (_| || || (_) |\__ \\
     \___/ |_| |_| |_|| .__/ |_| |_| \__,_||_| \___/ |___/
    ================= | | =================================
$(tput setaf 3)      Welcome:$USER_NAME $(tput setaf 6)   | | $(tput setaf 3)  Uptime: $UPTIME
$(tput setaf 4)You have reached the center. Ask, and the knowledge shall answer. $(tput sgr0)"
EOF

 # Make the file executable
 sudo chmod +x /etc/update-motd.d/09-custom-header

 echo "Custom MOTD files created and permissions set."

else
  # If not an Orange Pi, skip this step
  echo "Not a Orange Pi system. Trying next..."
fi
#############################################################################################

# Step 6: Custom MOTD for full Ubuntu installs
# Check if the system is Ubuntu
if [ "$os_type" == "ubuntu" ]; then
  echo "Creating custom MOTD header for Ubuntu OS..."

   # Create 09-custom-header for Ubuntu
   cat << 'EOF' | sudo tee /etc/update-motd.d/29-custom-stats > /dev/null
#!/bin/bash

export TERM=xterm-256color

# Colors
green=$(tput setaf 2)
blue=$(tput setaf 4)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

# Uptime
uptime=$(uptime -p | sed 's/up //')

# Load average
read one five fifteen rest < /proc/loadavg

# Memory usage
mem_total=$(free -m | awk '/^Mem:/ {print $2}')
mem_used=$(free -m | awk '/^Mem:/ {print $3}')
mem_percent=$(( 100 * mem_used / mem_total ))

# Disk usage
disk_usage=$(df -h / | awk 'END{print $5 " used of " $2}')

# Additional storage mount (if used, optional)
if mountpoint -q /media/usb; then
    storage_usage=$(df -h /media/usb | awk 'END{print $5 " used of " $2}')
else
    storage_usage="Not mounted"
fi

# IP address (only showing first IPv4 address, excluding Docker and other interfaces)
ip_addr=$(hostname -I | awk '{print $1}')

# CPU Temp (Raspberry Pi/Orange Pi compatible)
cpu_temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
if [ -n "$cpu_temp_raw" ]; then
    cpu_temp=$(awk "BEGIN {printf \"%.1f°C\", $cpu_temp_raw/1000}")
else
    cpu_temp="Unavailable"
fi

# Logged in users
user_count=$(who | wc -l)

# Last Login
last_login=$(last -n 1 -R -F -w $USER | head -n 1 | awk '{print $4, $5, $7, $6}')

# Current Login Status
#current_login_status=$(last -n 1 -R -F -w $USER | head -n 1 | awk '{print $8, $9, $10}')
#if [[ "$current_login_status" == "logged" ]]; then
#  echo "User is still logged in."
#else
#  echo "User has logged out."
#fi



#printf "%*s\n" $(( (COLUMNS + ${#last_login} + 13) / 2 )) "Last login: $last_login"

# Output
echo "${blue}-----------------------------------------------------------------${reset}"
echo "         ${yellow}Load Average:${reset}${one}, ${five}, ${fifteen} (1, 5, 15 min)"
echo "       ${yellow}Memory Usage:${reset}${mem_percent}% of ${mem_total}MB"   "   ${yellow}Users Logged In:${reset} ${user_count}"
echo "   ${yellow}Disk Usage:${reset} ${disk_usage}"   "  ${yellow}USB Storage:${reset} ${storage_usage}"
echo "        ${yellow}IP Address:${reset} ${ip_addr}"   "   ${yellow}CPU Temp:${reset} ${cpu_temp}"
echo "               ${yellow}Last Login:${reset} ${last_login}"
echo "${blue}-----------------------------------------------------------------${reset}"

EOF

   # Make the file executable
   sudo chmod +x /etc/update-motd.d/29-custom-stats

   # Create 09-custom-header for Ubuntu
   cat << 'EOF' | sudo tee /etc/update-motd.d/09-custom-header > /dev/null
#!/bin/sh

export TERM=xterm-256color

USER_NAME=${USER:-$(id -un)}
UPTIME=$(uptime -p)
read one five fifteen _ < /proc/loadavg

echo "$(tput setaf 6)
                              _             _
                             | |           | |
      ___   _ __ ___   _ __  | |__    __ _ | |  ___   ___
     / _ \ | '_ \` _ \ | '_ \ | '_ \  / _\` || | / _ \ / __|
    | (_) || | | | | || |_) || | | || (_| || || (_) |\__ \\
     \___/ |_| |_| |_|| .__/ |_| |_| \__,_||_| \___/ |___/
    ================= | | =================================
$(tput setaf 3)      Welcome:$USER_NAME $(tput setaf 6)   | | $(tput setaf 3)  Uptime: $UPTIME
$(tput setaf 4)You have reached the center. Ask, and the knowledge shall answer. $(tput sgr0)"
EOF
 
 # Make the file executable
 sudo chmod +x /etc/update-motd.d/09-custom-header

 echo "Custom MOTD header created for Ubuntu."

else
  echo "Not a full Ubuntu OS system. Skipping...."
fi
##############################################################################################

# Step 7.0: Setup custom /etc/issue file for Orange Pi (if applicable)
if [ "$os_type" == "orangepi" ]; then
  echo "Creating custom /etc/issue file for Orange Pi..."

  # Create the custom /etc/issue file with colors and message
  sudo bash -c 'echo -e "\033[31m
    _    _  ___  ______ _   _ _____ _   _ _____
   | |  | |/ _ \ | ___ \ \ | |_   _| \ | |  __ \
   | |  | / /_\ \| |_/ /  \| | | | |  \| | |  \/
   | |/\| |  _  ||    /| . \` | | | | . \` | | __
   \  /\  / | | || |\ \| |\  |_| |_| |\  | |_\ \
    \/  \/\_| |_/\_| \_\_| \_/\___/\_| \_/\____/
\033[0m
====================================================
This system is for the use of authorized users only.
Individuals using this system without authority, or
in excess of their authority, are subject to having
all of their activities monitored and recorded. If
monitoring reveals evidence of criminal activity,
all evidence will be provided to law enforcement.
====================================================" > /etc/issue'

echo "Custom /etc/issue file created."

else
  echo "Can not detect Orange Pi. Trying next..."
fi
##############################################################################################

# Step 7.1: Setup custom /etc/issue file for Ubuntu (if applicable)
if [ "$os_type" == "ubuntu" ]; then
  echo "Creating custom /etc/issue file for Ubuntu OS..."

  # Create the custom /etc/issue file with colors and message
  sudo bash -c 'echo -e "\033[31m
    _    _  ___  ______ _   _ _____ _   _ _____
   | |  | |/ _ \ | ___ \ \ | |_   _| \ | |  __ \
   | |  | / /_\ \| |_/ /  \| | | | |  \| | |  \/
   | |/\| |  _  ||    /| . \` | | | | . \` | | __
   \  /\  / | | || |\ \| |\  |_| |_| |\  | |_\ \
    \/  \/\_| |_/\_| \_\_| \_/\___/\_| \_/\____/
\033[0m
====================================================
This system is for the use of authorized users only.
Individuals using this system without authority, or
in excess of their authority, are subject to having
all of their activities monitored and recorded. If
monitoring reveals evidence of criminal activity,
all evidence will be provided to law enforcement.
====================================================" > /etc/issue'

else
  echo "Not a full Ubuntu OS system. Skipping..."
fi
###############################################################################################

# Step 8: Install SSH server
echo "Installing SSH server..."
apt install -y openssh-server
echo "SSH server installed."

# Step 9: Enable password authentication in SSH
echo "Enabling password authentication for SSH..."
# Modify /etc/ssh/sshd_config to enable password authentication
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
# Restart SSH service to apply the changes
sudo systemctl restart sshd
echo "Password authentication for SSH enabled."

# Step 10: Install and configure fail2ban
echo "Installing fail2ban..."
apt install -y fail2ban
echo "fail2ban installed."
echo "Configuring fail2ban..."
# Create a local copy of the default configuration
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
# Enable SSH protection
sudo sed -i 's/^enabled = false/enabled = true/' /etc/fail2ban/jail.local
# Set the ban time to 1 hour (3600 seconds)
sudo sed -i 's/^bantime = 10m/bantime = 3600/' /etc/fail2ban/jail.local
# Set the find time to 1 hour (3600 seconds)
sudo sed -i 's/^findtime = 10m/findtime = 3600/' /etc/fail2ban/jail.local
# Set the max retry to 5
sudo sed -i 's/^maxretry = 5/maxretry = 5/' /etc/fail2ban/jail.local
# Restart fail2ban to apply the changes
sudo systemctl restart fail2ban
echo "fail2ban configured and restarted."

# Step 11: Install and configure unattended-upgrades
echo "Installing unattended-upgrades..."
apt install -y unattended-upgrades
echo "unattended-upgrades installed."
# Reconfigure unattended-upgrades to allow security updates
echo "Configuring unattended-upgrades..."
sudo dpkg-reconfigure --priority=low unattended-upgrades
# Enable automatic updates for security packages only (make sure it's uncommented)
sudo sed -i 's/^\/\/\s*\("Unattended-Upgrade::Allowed-Origins::" .*\)/\1/' /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's/^\/\/\s*\("Unattended-Upgrade::Allowed-Origins:: .*\)/\1/' /etc/apt/apt.conf.d/50unattended-upgrades
# Optionally: Enable automatic updates for all packages (comment out if you only want security updates)
# sudo sed -i 's/^\/\/\s*\("Unattended-Upgrade::Allowed-Origins::" .*\)/\1/' /etc/apt/apt.conf.d/50unattended-upgrades
# Exclude specific packages like Docker and Kernel updates (optional)
echo "Excluding kernel and Docker updates..."
sudo sed -i '/Unattended-Upgrade::Package-Blacklist/ a \    "linux-*";\n    "docker*";' /etc/apt/apt.conf.d/50unattended-upgrades
# Enable automatic reboot if kernel updates require it (optional)
#echo "Enabling automatic reboot after kernel updates..."
#echo 'Unattended-Upgrade::Automatic-Reboot "true";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades
#echo 'Unattended-Upgrade::Automatic-Reboot-Time "02:00";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades
echo "unattended-upgrades configured."

# Step 12: Install and configure ufw (Uncomplicated Firewall)
echo "Installing ufw..."
apt install -y ufw
echo "ufw installed."
echo "Configuring ufw..."
# Allow SSH connections
sudo ufw allow ssh
# Allow HTTP (port 80) for web traffic
sudo ufw allow http
# Allow HTTPS (port 443) for secure web traffic
sudo ufw allow https
# Enable the firewall
sudo ufw enable
# Check the status of the firewall
sudo ufw status
echo "ufw configured and enabled."

# Step 13: Install and configure NTP (Network Time Protocol)
echo "Installing NTP..."
apt install -y ntpsec
echo "NTP installed."
# Configure NTP to use the default Ubuntu servers (update ntpsec.conf instead)
echo "Configuring NTP..."
sudo sed -i 's/^server 0.ubuntu.pool.ntp.org iburst/server 0.ubuntu.pool.ntp.org iburst\nserver 1.ubuntu.pool.ntp.org iburst\nserver 2.ubuntu.pool.ntp.org iburst\nserver 3.ubuntu.pool.ntp.org iburst/' /etc/ntpsec/ntp.conf
# Restart NTP service to apply changes
sudo systemctl restart ntpsec
echo "NTP configured and restarted."

# Step 14: Install and configure rsync
echo "Installing rsync..."
apt install -y rsync
echo "rsync installed."

# Step 15: Install and configure htop
echo "Installing htop..."
apt install -y htop
echo "htop installed."

# Step 16: Install lsof
echo "Installing lsof..."
apt install -y lsof
echo "lsof installed."

# Step 17: Install and configure curl
echo "Installing curl..."
apt install -y curl
echo "curl installed."

# Step 18: Install and configure wget
echo "Installing wget..."
apt install -y wget
echo "wget installed."

# Step 19: Install and configure git
echo "Installing git..."
apt install -y git
echo "git installed."

# Step 20: Install docker
echo "Installing Docker..."
apt install -y docker.io
echo "Docker installed."

# Step 21: Install docker-compose
echo "Installing Docker Compose..."
apt install -y docker-compose
echo "Docker Compose installed."

# Step 22: Install byobu
echo "Installing byobu..."
apt install -y byobu
echo "byobu installed."

# Step 23: Install nano
echo "Installing nano..."
apt install -y nano
echo "nano installed."

# Step 24: Install zip utilities
echo "Installing zip utilities..."
apt install -y zip unzip
echo "zip utilities installed."

######### End of script reboot #########
echo "The script has completed all setup steps."

# Ask the user if they want to reboot, with a 5-minute timeout
echo "You have 5 minutes to choose whether to reboot."
read -t 300 -p "Would you like to reboot the system now? (y/n): " reboot_choice

if [[ "$reboot_choice" == "y" ]]; then
    echo "Rebooting now..."
    echo "To cancel the reboot, press any key within 10 seconds."
    echo "Thank you for using this setup script!"
    echo "If you have any questions or issues, please refer to the documentation or support."

    # Wait for 10 seconds, and if a key is pressed, cancel the reboot
    read -t 10 -n 1 -s cancel_key

    if [[ -n "$cancel_key" ]]; then
        echo "Reboot cancelled. Please reboot manually when ready to apply changes."
    else
        echo "No key pressed. Rebooting now..."
        reboot
    fi
else
    echo "System will not reboot. Please reboot manually when ready to apply changes."
fi

# Common farewell messages
echo "You can now log in with the new user account and SSH."
echo "Thank you for using this setup script!"
echo "If you have any questions or issues, please refer to the documentation or support."
echo "Goodbye!"
sleep 2
echo "Exiting script..."
sleep 1
exit 0
# End of script
