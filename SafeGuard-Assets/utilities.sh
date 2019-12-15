#! /bin/bash

# This is where all the utility functions reside for the SafeGuard Installer


export printGreen=$'\e[1;32m'
export printWhite=$'\e[0m'
export printRed=$'\e[1;31m'
export printCyan=$'\e[1;36m'
# Absolute path to this script
SCRIPT=$(readlink -f "$0")
# Absolute path to the script directory
BASEDIR=$(dirname "$SCRIPT")
HOME_DIR=$(eval echo ~"$(logname)")

firstIteration() {
	local token="$1"
	local repoPath=${HOME_DIR}/SafeGuard-Installer/

	echo "Token is:"
	echo -e "${printCyan}${token}${printWhite}"
	if [[ -z ${token} ]]; then 
	    echo
	    echo "You must provide a docker registry token!"
	    echo "Exiting..."
	    exit 1
	fi
	#dependencies and resources
	dpkg -a --configure # fixes issues with dpkg preventing the script from running...
	wget -O "${repoPath}/Teamviewer.deb https://download.teamviewer.com/download/linux/teamviewer_amd64.deb"
	wget -O "${HOME_DIR}/Desktop/SafeGuard.AppImage" https://github.com/ANVSupport/SafeGuard-Installer/releases/download/Appimage/FaceSearch-1.20.0-linux-x86_64.AppImage
	chmod +x "${HOME_DIR}/Desktop/SafeGuard.AppImage" && chown "$(logname)" "${HOME_DIR}/Desktop/SafeGuard.AppImage"
	apt install vlc curl vim htop net-tools expect parted -y -qq > /dev/null && successfulPrint "Utilities"
	chmod +x "${repoPath}"*
	apt install "${repoPath}/Teamviewer.deb" -y -qq > /dev/null && successfulPrint "TeamViewer" ## To test
	mv "${repoPath}/SafeGuard-Assets/secondIteration.sh" /opt/secondIteration.sh # prepare it to be run after reboot

	# Call storage mounting script
	if  bash "${BASEDIR}/mount.sh" ; then
		successfulPrint "mounting"
	else
		failedPrint "mounting"
		echo "Please mount manually and run this script again"
		exit 1
	fi

	##moxa set up
	moxadir=${HOME_DIR}/moxa-config/
	mkdir "${moxadir}"
	mv "${repoPath}/SafeGuard-Assets/moxa_e1214.sh" "${moxadir}"
	mv "${repoPath}/SafeGuard-Assets/cameraList.json ${moxadir}" && successfulPrint "Moxa setup"
	chmod +x "${moxadir}"* && chown user "${moxadir}"*

	cat << "EOF"
	 _____              _          _  _  _                    _____          __        _____                         _          
	|_   _|            | |        | || |(_)                  / ____|        / _|      / ____|                       | |         
	  | |   _ __   ___ | |_  __ _ | || | _  _ __    __ _    | (___    __ _ | |_  ___ | |  __  _   _   __ _  _ __  __| |         
	  | |  | '_ \ / __|| __|/ _` || || || || '_ \  / _` |    \___ \  / _` ||  _|/ _ \| | |_ || | | | / _` || '__|/ _` |         
	 _| |_ | | | |\__ \| |_| (_| || || || || | | || (_| |    ____) || (_| || | |  __/| |__| || |_| || (_| || |  | (_| | _  _  _ 
	|_____||_| |_||___/ \__|\__,_||_||_||_||_| |_| \__, |   |_____/  \__,_||_|  \___| \_____| \__,_| \__,_||_|   \__,_|(_)(_)(_)
	                                                __/ |                                                                       
	                                               |___/                                                                        
EOF
	bash -s "${HOME_DIR}/Downloads/SafeGuard-Installer/compose-oneliner/compose-oneliner.sh" -b 1.20.0 -k "${token}"
	ln -s "${HOME_DIR}/docker-compose/1.20.0/docker-compose-local-gpu.yml" "${HOME_DIR}/docker-compose/1.20.0/docker-compose.yml" && successfulPrint "Create Symbolic Link"
	echo "1" > /opt/sg.f ##flag if the script has been run 

	##make script auto run after login
	tee -a "${HOME_DIR}/.profile" <<EOF && successfulPrint "Startup added" # EOF without quotations or backslash evaluates variables
	xhost +
	gnome-terminal -- sh -c '${repoPath}/SafeGuard-Assets/launchAsRoot.sh'
EOF
}
clean(){
	cat << "EOF"

	  _____  _                      _                  _____              _                   
	 / ____|| |                    (_)                / ____|            | |                  
	| |     | |  ___   __ _  _ __   _  _ __    __ _  | (___   _   _  ___ | |_  ___  _ __ ___  
	| |     | | / _ \ / _` || '_ \ | || '_ \  / _` |  \___ \ | | | |/ __|| __|/ _ \| '_ ` _ \ 
	| |____ | ||  __/| (_| || | | || || | | || (_| |  ____) || |_| |\__ \| |_|  __/| | | | | |
	 \_____||_| \___| \__,_||_| |_||_||_| |_| \__, | |_____/  \__, ||___/ \__|\___||_| |_| |_|
	                                           __/ |           __/ |                          
	                                          |___/           |___/                           
EOF
	apt remove --purge ./*docker* docker-compose nvidia-container-runtime nvidia-container-toolkit nvidia-docker nvidia* > /dev/null && successfulPrint "Purge drivers and docker"
	rm -rfv "${HOME_DIR}"/docker-compose/*
	rm -rfv "${HOME_DIR}"/Downloads/*
	rm -rfv /opt/sg.f && successfulPrint "remove flag" ##clear iteration flag because everything has been cleaned
	rm -rfv /ssd/*
	rm -rfv /storage/*
	successfulPrint "System Clean"
}

successfulPrint(){
	echo -e "=================================================================="
	echo -e "                    $1 ....${green}Success${white}                  "
	echo -e "=================================================================="
}

failedPrint(){
	echo -e "=================================================================="
	echo -e "                    $1 ....${red}Failed!${white}                  "
	echo -e "=================================================================="
}