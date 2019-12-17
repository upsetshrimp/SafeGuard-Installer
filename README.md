# SafeGuard-Installer
This is a SafeGuard Installer written by Gilad Ben-Nun.
Pre-requisits: 

-A Machine with a clean installation of Ubuntu 18.04.1/2
-SSD as boot drive
-HDD to be used as storage drive (Will be deleted completly)

## here to get the Token
In AnVision's Jenkins theres a job called "docker_registery_generate_token"
when it complete copy the "Password" as the token
Run this as root with the generated token (lasts for 1 hour)

```bash
wget -qO- https://raw.githubusercontent.com/ANVSupport/SafeGuard-Installer/master/main.sh | bash -s -- [TOKEN]
```

## Errors:
If after the reboot A terminal window doesnt open and run the second part of the script, There is a script on the desktop to run that will continue deployment (RUN AS ROOT).
