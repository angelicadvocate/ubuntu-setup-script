# ubuntu-setup-script
Script to automate Ubuntu updates and setup, including SSH, firewall, Docker, and useful tools. Includes templates for /etc/issue and MOTD customization. Ideal for fresh installs and headless systems.

## ⚠️ Note on Beta Builds
This project is currently in active development, and beta testing is ongoing. While it has been tested on multiple systems, please use with additional care—especially on production machines.
All versions are provided as-is with no warranty, and results may vary depending on your setup. Feedback and bug reports are always welcome to help improve future releases.

## 📦 Dependencies
- This script uses dialog for interactive menus. If it’s not already installed, the script will install it automatically.
- An active internet connection is required to install packages and updates.
- For best results, run the script from an SSH terminal (especially on headless systems).

## 🚀 Getting Started
This script is currently in beta and intended for testing and development use only.
If you'd like to try it out, please review the source code and run it manually to ensure it fits your environment.

## ✅ Tested Ubuntu Builds
- Ubuntu 24.04
- Ubuntu 24.04 Server
- Orange Pi Ubuntu 24.04
More OS versions coming soon

## 📝 Version History
### v1.0 beta – Initial Release
- Automated Ubuntu updates
- Set up SSH, firewall, Docker, and useful tools
- Created templates for /etc/issue and MOTD customization

### v1.1 beta – Bug Fixes
- Fixed issue where leaving the username blank would create a blank user profile
- Refactored various functions for easier maintenance
- Fixed formatting of ASCII art for /etc/issue screen
- Resolved issue with /etc/issue displaying on tty1 on Ubuntu 24.04 Server

### v1.2 beta - Various Changes
- Moved MOTD and issue files to dedicated directories
- Fixed bug in reboot function at end of script
- Made structural changes in preparation for roadmap features

## 🛠️ Roadmap
The project will remain in beta while core features and flexibility are being developed and tested.
Planned features for upcoming beta versions include:

- User Preset Support
  Allow users to predefine system setup values (hostname, username, MOTD, etc.) using a separate profile file.
  This will let users customize their configuration without editing the main script.
- Interactive Startup Menu
  Add a startup dialog menu for choosing optional packages and system tweaks before installation begins.
  This will help tailor the setup to different use cases (e.g., server vs. desktop, minimal vs. full setup).
- More OS Compatibility
  Expand testing and support for additional Ubuntu-based systems (e.g., Banana Pi, Pine64, Raspberry Pi).
- Improved Error Handling & Logging
  Add clearer error messages and optional logs for easier debugging and transparency during setup.

## License
This project is licensed under the GNU General Public License v3.0 (GPL-3.0).

## 🤝 Contributions Welcome
Pull requests and suggestions are welcome! Feel free to open an issue or submit a PR if you'd like to contribute.
