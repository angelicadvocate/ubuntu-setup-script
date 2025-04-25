#!/bin/bash

# Version: 1.2 beta

# ubuntu-quickstart - Automates Ubuntu updates, SSH setup, firewall, Docker, and useful tools.
# Adds templates for /etc/issue and MOTD. Great for fresh installs and headless systems.
#
# This program and its associated scripts are released under the GNU General Public License (GPL) v3.
# See the LICENSE file for more details.
#
# Copyright (C) 2025 [angelicadvocate]
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.

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

# Check if the username is empty
if [ -z "$NEW_USER" ]; then
  echo "⚠️ No username provided. Skipping user creation."
else
  # Check if the user already exists
  if id "$NEW_USER" &>/dev/null; then
    echo "❌ User '$NEW_USER' already exists, skipping user creation."
  else
    # Prompt for password and confirmation
    read -s -rp "Enter password for $NEW_USER: " USER_PASS
    echo
    read -s -rp "Confirm password: " USER_PASS_CONFIRM
    echo

    # Check if passwords are empty
    if [[ -z "$USER_PASS" || -z "$USER_PASS_CONFIRM" ]]; then
      echo "⚠️ No password entered. Skipping password setup."
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

# Make sure all scripts in the motd-options folder are executable
chmod +x ./motd-options/*.sh

# Call motd script
./motd-options/01-default-motd.sh

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

# Make sure all scripts in the motd-options folder are executable
chmod +x ./motd-options/*.sh

# Call motd script
./motd-options/01-default-motd.sh

 echo "Custom MOTD files created and permissions set."

else
  echo "Not a recognized Ubuntu system. Skipping...."
fi
##############################################################################################

# Step 7.0: Setup custom /etc/issue file for Orange Pi (if applicable)
if [ "$os_type" == "orangepi" ]; then
  echo "Creating custom /etc/issue file for Orange Pi..."

# Make sure all scripts in the etc-issue-options folder are executable
chmod +x ./etc-issue-options/*.sh

# Call etc/issue script
./etc-issue-options/01-default-issue.sh

echo "Custom /etc/issue file created."

else
  echo "Can not detect Orange Pi. Trying next..."
fi
##############################################################################################

# Step 7.1: Setup custom /etc/issue file for Ubuntu (if applicable)
if [ "$os_type" == "ubuntu" ]; then
  echo "Creating custom /etc/issue file for Ubuntu OS..."

# Make sure all scripts in the etc-issue-options folder are executable
chmod +x ./etc-issue-options/*.sh

# Call etc/issue script
./etc-issue-options/01-default-issue.sh

sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
sudo bash -c 'echo -e "[Service]\nExecStart=\nExecStart=-/sbin/agetty --noclear --noissue %I \$TERM" > /etc/systemd/system/getty@tty1.service.d/hide-banner.conf'
sudo systemctl daemon-reexec
sudo systemctl restart getty@tty1

else
  echo "Not a full Ubuntu OS system. Skipping..."
fi
###############################################################################################

# Step 7.2: Configure SSH to display /etc/issue on login
SSHD_CONFIG="/etc/ssh/sshd_config"
if [[ -f "$SSHD_CONFIG" && -f "/usr/sbin/sshd" ]]; then
  echo "Configuring SSH to display /etc/issue..."
  sudo sed -i 's/^#Banner none/Banner \/etc\/issue/' "$SSHD_CONFIG"
  sudo systemctl restart ssh.service
  echo "✅ SSH banner set to /etc/issue."
else
  echo "⚠️ Unable to set /etc/issue in SSH."
  echo "To enable it manually:"
  echo "- Make sure OpenSSH server is installed (sudo apt install openssh-server)."
  echo "- Edit /etc/ssh/sshd_config and set: Banner /etc/issue"
  echo "- Restart SSH: sudo systemctl restart sshd"
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
sudo systemctl restart ssh.service
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
export DEBIAN_FRONTEND=noninteractive
apt install -y unattended-upgrades
echo "unattended-upgrades installed."
# Reconfigure unattended-upgrades to allow security updates
echo "Configuring unattended-upgrades..."
sudo DEBIAN_FRONTEND=noninteractive dpkg-reconfigure --priority=low unattended-upgrades
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
export DEBIAN_FRONTEND=noninteractive
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
sudo ufw --force enable
# Check the status of the firewall
sudo ufw reload
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
echo "You have 5 minutes to choose whether to reboot."

read -t 300 -p "Would you like to reboot the system now? (y/n): " reboot_choice
if [[ $? -ne 0 ]]; then
    echo -e "\nNo input received. Defaulting to 'no reboot'."
    reboot_choice="n"
fi

if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
    echo "Rebooting in 15 seconds..."
    echo "Press any key to cancel."

    # Save current terminal settings
    old_stty=$(stty -g)

    # Set terminal to raw mode to detect any keypress including Enter
    stty -icanon -echo min 1 time 100

    # Wait for 15 seconds for any keypress
    if read -t 15 -n 1 cancel_key; then
        # Restore terminal settings
        stty "$old_stty"
        echo -e "\nReboot cancelled. Please reboot manually when ready to apply changes."
    else
        # Restore terminal settings
        stty "$old_stty"
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
