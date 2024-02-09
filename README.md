![backupchi-abi](https://github.com/masoudgb/Backupchi/assets/87688187/8012c870-331f-43ad-b526-c595f0b81212)


# Backupchi Script

[English](README.md) | [فارسی](README-fa.md)

<!-- The rest of your README content goes here -->

**

- This Bash script provides a simple backup solution for both local and backup server setups. It includestrong texts options for installing and configuring Nginx, scheduling backups, and sending backup files to Telegram. The script also allows for uninstallation.

**

## Install & Upgrade

**

```bash
bash <(curl -Ls https://github.com/masoudgb/Backupchi/raw/main/backupchi.sh)
```
**

## Screenshot 

![Screenshot 2024-02-09 031449](https://github.com/masoudgb/Backupchi/assets/87688187/0a14de1f-a171-431d-80ea-794851885baf)


**

## Prerequisites

**

- The script should be executed with root privileges.
Supported package managers: apt-get, dnf, yum.

**

## Main Menu Options

**

 **1. Local server**

Configures a local server with Nginx, scheduling backups, and sending them to Telegram if desired.

 **2. Backup server**
  
Setsup a backup server, allowing users to schedule periodic downloads of backup files.

**3. Uninstall**
 
Removes the script and optionally deletes the backup directory.

**4. Exit**
 
Exits the script.

**

## Note

**


- Ensure to provide necessary inputs as prompted during the execution.
Special Thanks
**This script is created by Masoud Gb** with special thanks to Hamid Router

**

## Disclaimer

**


- Use this script at your own risk. The author is not responsible for any data loss or system issues.


- Feel free to contribute and provide feedback.
