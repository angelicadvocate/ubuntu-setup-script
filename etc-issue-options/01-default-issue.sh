#!/bin/bash

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
#
###############################################################################

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