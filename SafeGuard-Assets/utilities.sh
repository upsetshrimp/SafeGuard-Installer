#! /bin/bash

# This is where all the utility functions reside for the SafeGuard Installer


export printGreen=$'\e[1;32m'
export printWhite=$'\e[0m'
export printRed=$'\e[1;31m'
export printCyan=$'\e[1;36m'
# Absolute path to this script
SCRIPT=$(readlink -f "$0")
echo "SCRIPT  DIR:"
echo "${SCRIPT}"
# Absolute path to the script directory
BASEDIR=$(dirname "$SCRIPT")
echo "BASEDIR:"
echo "${BASEDIR}"
HOME_DIR=$(eval echo ~"$(logname)")
echo "HOME_DIR: "
echo "${HOME_DIR}"


firstIteration() {
	local token="$1"
	local repoPath="${HOME_DIR}"/SafeGuard-Installer
	echo "Repo Path:"
	echo "${printCyan}${repoPath}${printWhite}"
	echo "Token is:"
	echo -e "${printCyan}${token}${printWhite}"

	if [[ -z ${token} ]]; then 
	    echo
	    echo "You must provide a docker registry token!"
	    echo "Exiting...
"	    exit 1
	fi
	#dependencies and resources
	rm -rf /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend
	dpkg -a --configure # fixes issues with dpkg preventing the script from running...
	wget -q --show-progress -O "${repoPath}/Teamviewer.deb" "https://download.teamviewer.com/download/linux/teamviewer_amd64.deb"
	wget -q --show-progress -O "${HOME_DIR}/Desktop/SafeGuard.AppImage" https://github.com/ANVSupport/SafeGuard-Installer/releases/download/Appimage/FaceSearch-1.20.0-linux-x86_64.AppImage
	chmod +x "${HOME_DIR}/Desktop/SafeGuard.AppImage" && chown "$(logname)" "${HOME_DIR}/Desktop/SafeGuard.AppImage"
	echo "==========================================================="
	echo "                   ${printCyan}Installing Utilities...${printWhite}                "
	echo "==========================================================="
	apt-get install vlc curl vim htop net-tools expect parted -yqq --show-progress && successfulPrint "Utilities"
	chmod -R +x "${repoPath}"*
	cp "${repoPath}"/SafeGuard-Assets/SGLogo.jpg "${HOME_DIR}"/Desktop/SGLogo.jpg
	apt-get install "${repoPath}/Teamviewer.deb" -y -qq && successfulPrint "TeamViewer" ## To test
	mv "${repoPath}/SafeGuard-Assets/secondIteration.sh" /opt/secondIteration.sh # prepare it to be run after reboot

	# Call storage mounting script
	if  bash "${repoPath}/SafeGuard-Assets/mount.sh" ; then
		successfulPrint "mounting"
	else
		Error=$?
		failedPrint "mounting"
		echo "Please mount manually and run this script again"
		echo "Error: ""${Error}"
		exit 1
	fi

	##moxa set up
	moxadir=${HOME_DIR}/moxa-config
	mkdir "${moxadir}"
	mv "${repoPath}/SafeGuard-Assets/moxa_e1214.sh" "${moxadir}/moxa_e1214.sh"
	mv "${repoPath}/SafeGuard-Assets/cameraList.json ${moxadir}/cameraList.json" && successfulPrint "Moxa setup"
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
	bash "${repoPath}"/compose-oneliner/compose-oneliner.sh -b 1.20.0 -k "${token}" && successfulPrint "SafeGuard Installed"
	 	ln -s "${HOME_DIR}/docker-compose/1.20.0/docker-compose-local-gpu.yml" "${HOME_DIR}/docker-compose/1.20.0/docker-compose.yml" && successfulPrint "Create Symbolic Link"
	echo "1" > /opt/sg.f ##flag if the script has been run 

	##make script auto run after login
	local startupFile
	startupFile=etc/gdm3/PostLogin/Default
	echo "#! /bin/sh" > ${startupFile}
	tee -a ${startupFile} <<EOF && successfulPrint "Startup added" # EOF without quotations or backslash evaluates variables
gnome-terminal -- sh -c '${repoPath}/SafeGuard-Assets/launchAsRoot.sh'
EOF
chmod +x ${startupFile}
ln -s "${repoPath}"/SafeGuard-Assets/launchAsRoot.sh "${HOME_DIR}"/Desktop/RunThis.sh # right order? TO TEST
chmod +x "${HOME_DIR}"/Desktop/RunThis.sh
echo "xhost +" >> "${HOME_DIR}"/.profile
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
	apt-get remove --purge ./*docker* docker-compose nvidia-container-runtime nvidia-container-toolkit nvidia-docker nvidia* > /dev/null && successfulPrint "Purge drivers and docker"
	rm -rfv "${HOME_DIR}"/docker-compose/*
	rm -rfv "${HOME_DIR}"/Downloads/*
	rm -rfv /opt/sg.f && successfulPrint "remove flag" ##clear iteration flag because everything has been cleaned
	rm -rfv /ssd/*
	rm -rfv /storage/*
	successfulPrint "System Clean"
}

successfulPrint(){
	echo -e "=================================================================="
	echo -e "                    $1 ....${printGreen}Success${printWhite}                  "
	echo -e "=================================================================="
}

failedPrint(){
	echo -e "=================================================================="
	echo -e "                    $1 ....${printRed}Failed!${printWhite}                  "
	echo -e "=================================================================="
}