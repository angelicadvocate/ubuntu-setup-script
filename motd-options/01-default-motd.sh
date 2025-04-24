#!/bin/bash
 
# This script sets the default message of the day (MOTD) for Ubuntu systems.

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