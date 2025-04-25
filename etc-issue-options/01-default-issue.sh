#!/bin/bash

# ubuntu-quickstart - Automates Ubuntu updates, SSH setup, firewall, Docker, and useful tools.
# Adds templates for /etc/issue and MOTD. Great for fresh installs and headless systems.
#
# This script is part of the ubuntu-quickstart project and is released under the GNU General Public License (GPL) v3.
# See the LICENSE file and the main script for more details.


  sudo bash -c 'echo -e "\033[31m
    _    _  ___  ______ _   _ _____ _   _ _____
   | |  | |/ _ \ | ___ \ \ | |_   _| \ | |  __ \\
   | |  | / /_\ \| |_/ /  \| | | | |  \| | |  \/
   | |/\| |  _  ||    /| . \` | | | | . \` | | __
   \  /\  / | | || |\ \| |\  |_| |_| |\  | |_\ \\
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