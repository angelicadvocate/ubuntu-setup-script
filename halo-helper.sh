#!/bin/bash

# Version: 1.3 beta

# HaloHelper - Automates Ubuntu updates, SSH setup, firewall, Docker, and useful tools.
# Adds templates for /etc/issue and MOTD. Great for fresh installs and headless systems.
#
# This script is part of the HaloHelper project and is released under the GNU General Public License (GPL) v3.
# See the LICENSE file and the main script for more details.
#
# Copyright (C) 2025 AngelicAdvocate
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


# Wait for user input to display conditions or warranty
while true; do
    clear
    echo "This program comes with ABSOLUTELY NO WARRANTY; for details press 'w'."
    echo "This is free software, and you are welcome to redistribute it under "
    echo "certain conditions; press 'c' for details."
    echo "Press 's' to start the script, or press 'x' to cancel."
    read -n 1 -p "Press 'c', 'w', 'x', or 's' : " choice
    case "$choice" in
        [Cc])
            echo ""
            echo "Displaying the conditions..."
            echo "You should have received a copy of the GNU General Public License"
            echo "along with this program.  If not, see <https://www.gnu.org/licenses/>"
            echo "for a full list of the conditions. This script and all related assets"
            echo "are licensed under version 3 of the GNU GPL."
            echo "Copyright (C) 2025 AngelicAdvocate"
            read -p "Press any key to continue..." -n 1 -s
            ;;
        [Ww])
            echo ""
            echo "Displaying the warranty..."
            echo "  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY"
            echo "APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT"
            echo "HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM 'AS IS' WITHOUT WARRANTY"
            echo "OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,"
            echo "THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR"
            echo "PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM"
            echo "IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF"
            echo "ALL NECESSARY SERVICING, REPAIR OR CORRECTION."
            read -p "Press any key to continue..." -n 1 -s
            ;;
        [Ss])
            echo ""
            echo "Starting HaloHelper. Please wait..."
            sleep 1
            break
            ;;
        [Xx])
            echo ""
            echo "The script has been canceled."
            echo "Goodbye..."
            sleep 1
            exit 0
            ;;
    esac
done

################################################################################################

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

# Install necessary packages for the script
apt install -y dialog
apt install -y yq

###################DIALOG MENU#####################

# Future feature: Add a dialog menu for user interaction
# This is a placeholder for the dialog menu

###################################################


#############HOSTNAME AND USER SETUP###############

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

chmod +x ./main-installer/setup-quickstart.sh

./main-installer/setup-quickstart.sh
