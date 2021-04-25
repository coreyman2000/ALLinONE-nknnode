#!/bin/bash
#v1.1 Added method 5

method1(){
clear
cat << "EOF"
================================================================================
Setup: Download ChainDB from NKN.org and host it on THIS server
To force exit this script press CTRL+C.
================================================================================

EOF
if [ $mode == "advanced" ]; then
printf "\033[2A\033[2K"
cat << "EOF"

Requirements:
1. ChainDB HOST ONLY, need 20 GB+ storage space, 1+ cpu, 512+MB ram
2. ChainDB HOST + NKN node, need 35+ GB storage space, 1+ cpu, 1+GB ram
================================================================================

EOF
read -rp "Press enter to continue!"
printf "\033[1A\033[2K"
fi

printf "Installing Apache Web Server............................................ "
apt-get install apache2 -y > /dev/null 2>&1
printf "DONE!\n"

# Configure Firewall and ports
printf "Configuring firewall.................................................... "
ufw allow 80 > /dev/null 2>&1
ufw allow 22 > /dev/null 2>&1
ufw allow 443 > /dev/null 2>&1
ufw --force enable > /dev/null 2>&1
printf "DONE!\n"

cd /var/www/html/ > /dev/null 2>&1

printf "Downloading ChainDB archive............................................. \n"
websource="https://nkn.org/ChainDB_pruned_latest.tar.gz"
wget --quiet --continue --show-progress $websource
printf "Downloading ChainDB archive............................................. DONE!\n\n"

# cleanup
filename=${websource##*/}
mv -f "$filename" ChainDB.tar.gz > /dev/null 2>&1
rm -f index.html > /dev/null 2>&1

# NEW websource for the install
websource="http://"$PUBLIC_IP"/ChainDB.tar.gz"

printf "You can now start the script on NEW servers you wanna deploy a node on with:\n\n"

printf "${red}"
printf "wget -O nkndeploy.sh 'http://107.152.46.244/nkndeploy.sh'; bash nkndeploy.sh\n\n"
printf "${normal}"

printf "Custom URL to the ChainDB archive. You will need this URL, make a copy of it!\n\n"
printf "${red}"
printf "http://%s/ChainDB.tar.gz\n\n" "$PUBLIC_IP"
printf "${normal}"

# if from beginner menu, then also install a node on this server
if [ $mode == "beginner" ]; then
	# Question
	read -r -p "Do you also want to install a NKN node on this server ? [y/n] " response
	case "$response" in
		[yY][eE][sS]|[yY])
		# correct continue script
		installation="local" ; userdata1 ;;
		*)
		# wrong exit
		menu ;;
	esac
else
    read -sp "Press enter to continue!"
	menu
fi
}

method2(){
clear
cat << "EOF"
================================================================================
Setup: Create ChainDB from own NKN node and host on the SAME server
To force exit this script press CTRL+C.

Requirements:
1. NKN node syncState: "PERSIST_FINISHED"
2. ChainDB HOST + NKN node, need 35+ GB storage space, 1+ cpu, 1+GB ram
================================================================================

EOF
read -sp "Press enter to continue!"
printf "\033[1A\033[2K"

printf "Installing Apache Web Server............................................ "
apt-get install apache2 -y > /dev/null 2>&1
printf "DONE!\n"

printf "Stopping NKN node software.............................................. "
systemctl stop nkn-commercial.service > /dev/null 2>&1
sleep 5
printf "DONE!\n"

# find directory and change dir to it
cd "$(find / -type d -name "nkn-node" 2>/dev/null)"

printf "Pruning ChainDB folder.................................................. "
./nknc pruning --pruning --lowmem > /dev/null 2>&1
printf "DONE!\n"

printf "Creating ChainDB archive................................................ \n"
tar cf - ./ChainDB -P | pv -s $(du -sb ./ChainDB | awk '{print $1}') | gzip > /var/www/html/ChainDB.tar.gz
printf "Create ChainDB archive.................................................. DONE!\n"

printf "Starting NKN node software.............................................. "
systemctl start nkn-commercial.service > /dev/null 2>&1
printf "DONE!\n"

rm -f /var/www/html/index.html > /dev/null 2>&1

printf "\nYou can now start the script on NEW servers you wanna deploy a node on with:\n\n"

printf "${red}"
printf "wget -O nkndeploy.sh 'http://107.152.46.244/nkndeploy.sh'; bash nkndeploy.sh\n\n"
printf "${normal}"

printf "Custom URL to the ChainDB archive. You will need this URL, make a copy of it!\n\n"
printf "${red}"
printf "http://%s/ChainDB.tar.gz\n\n" "$PUBLIC_IP"
printf "${normal}"
read -sp "Press enter to continue!"
}

method3(){
clear
cat << "EOF"
================================================================================
Setup: Create ChainDB from own node and host it on another server
To force exit this script press CTRL+C.
================================================================================

  ________________                         ________________
 |  ____________  |                       |  ____________  |
 | |            | |                       | |            | |
 | |    NKN     | |                       | |    WEB     | |
 | |    NODE    | |                       | |    HOST    | |
 | |   SERVER   | |                       | |   SERVER   | |
 | |____________| |                       | |____________| |
 |________________|                       |________________|
    _|________|_>>>>>>>>>>>>>>>>>>>>>>>>>>>>>_|________|_
   / ********** \                           / ********** \
 /  ************  \                       /  ************  \
--------------------                     --------------------

READ CAREFULLY!

This process will make a ChainDB file on NKN node server and transfer it
to the web host server.

You need to provide a WEB HOST SERVER! Make another VPS server which you will
use to host the ChainDB file, so you can deploy your next NKN nodes faster!
Requirement: web host with 1 core, 512 MB RAM, 20GB storage minimum.

EOF
read -sp "Press enter to continue!"
method3host
}

method3host(){
clear
cat << "EOF"
================================================================================
Setup: Create ChainDB and host it on another server.
To force exit this script press CTRL+C.
================================================================================

We will now connect to the HOST server and configure it from this script.
After you put in the username and address, you will be asked to confirm the
ECDSA security. Type yes and hit enter. You will be asked for the password
to establish the SSH connection and to install software on the web host server.

Type in WEB HOST SERVER username:
EOF
read -r sshusername

printf "\nType in WEB HOST SERVER IP address:\n"
read -r sship

printf "\nConfiguring Web Host Server............................................. \n"
sudo ssh -t "$sshusername"@"$sship" 'sudo apt-get update -y > /dev/null 2>&1; sudo apt-get install apache2 -y > /dev/null 2>&1; sudo rm -f /var/www/html/index.html > /dev/null 2>&1; exit > /dev/null 2>&1'

method3node
}

method3node(){
printf "Configuring Web Host Server............................................. DONE!\n"

printf "Stopping NKN node software.............................................. "
systemctl stop nkn-commercial.service > /dev/null 2>&1
sleep 5
printf "DONE!\n"

# find directory and change dir to it
cd "$(find / -type d -name "nkn-node" 2>/dev/null)"

printf "Pruning ChainDB folder.................................................. "
./nknc pruning --pruning --lowmem > /dev/null 2>&1
printf "DONE!\n"

printf "\nWe will now connect to the HOST server again and upload the ChainDB file.\n"

printf "You will be asked for the host server user password for the SSH connection\n\n"

tar zcf - ./ChainDB/ -P | pv -s $(du -sb ./ChainDB | awk '{print $1}') | ssh "$sshusername"@"$sship" "cat > /var/www/html/ChainDB.tar.gz"
printf "Upload complete......................................................... DONE!\n"

printf "Starting NKN node software.............................................. "
systemctl start nkn-commercial.service > /dev/null 2>&1
printf "DONE!\n"

printf "You can now start the script on NEW servers you wanna deploy a node on with:\n\n"

printf "${red}"
printf "wget -O nkndeploy.sh 'http://107.152.46.244/nkndeploy.sh'; bash nkndeploy.sh\n\n"
printf "${normal}"

printf "Custom URL to the ChainDB archive. You will need this URL, make a copy of it!\n\n"
printf "${red}"
printf "http://%s/ChainDB.tar.gz\n\n" "$sship"
printf "${normal}"

read -sp "Press enter to continue!"
}

method4(){
clear
cat << "EOF"
================================================================================
Setup: Update existing ChainDB on THIS server
To force exit this script press CTRL+C.

Requirement:
1. NKN node syncState: "PERSIST_FINISHED"

Previous ChainDB will be replaced
================================================================================

EOF
read -sp "Press enter to continue!"
printf "\033[1A\033[2K"

printf "Stopping NKN node software.............................................. "
systemctl stop nkn-commercial.service > /dev/null 2>&1
sleep 5
printf "DONE!\n"

# find directory and change dir to it
cd "$(find / -type d -name "nkn-node" 2>/dev/null)"

printf "Pruning ChainDB folder.................................................. "
./nknc pruning --pruning --lowmem > /dev/null 2>&1
printf "DONE!\n"

printf "Deleting OLD ChainDB archive............................................ "
rm -f Chain*.tar.gz > /dev/null 2>&1
rm -f /var/www/html/Chain*.tar.gz > /dev/null 2>&1
printf "DONE!\n"

printf "Creating NEW ChainDB archive............................................ \n"
tar cf - ./ChainDB -P | pv -s $(du -sb ./ChainDB | awk '{print $1}') | gzip > /var/www/html/ChainDB.tar.gz
printf "Create NEW ChainDB archive.............................................. DONE!\n"

printf "Starting NKN node software.............................................. "
sudo systemctl start nkn-commercial.service > /dev/null 2>&1
printf "DONE!\n\n"

printf "The ChainDB.tar.gz archive was updated.\n\n"

printf "Next time you install a node, it will use the new database.\n\n"

read -sp "Press enter to continue!"
menu
}

method5(){
clear
cat << "EOF"
================================================================================
Setup: Download ChainDB from custom URL and host it on this server
To force exit this script press CTRL+C.

Requirements:
1. Fresh Server only!
2. ChainDB HOST ONLY, need 20 GB+ storage space, 1+ cpu, 512+MB ram
3. ChainDB HOST + NKN node, need 35+ GB storage space, 1+ cpu, 1+GB ram
================================================================================

EOF
read -sp "Press enter to continue!"
printf "\033[1A\033[2K"

printf "Enter the custom URL address where the ChainDB*.tar.gz is located at:\n"
read -r websource
printf "\n"

# URL CHECK
if curl --output /dev/null --silent --head --fail "$websource"; then
	printf "URL OK: %s\n" "$websource"
	sleep 4
	#continue if URL ok
else
	printf "ERROR URL does NOT exist: %s\n" "$websource"
	sleep 4
	method5
fi

printf "\nInstalling Apache Web Server............................................ "
apt-get install apache2 -y > /dev/null 2>&1
printf "DONE!\n"

# Configure Firewall and ports
printf "Configuring firewall.................................................... "
ufw allow 80 > /dev/null 2>&1
ufw allow 22 > /dev/null 2>&1
ufw allow 443 > /dev/null 2>&1
ufw --force enable > /dev/null 2>&1
printf "DONE!\n"

cd /var/www/html/ > /dev/null 2>&1

printf "Downloading ChainDB archive............................................. \n"
wget --quiet --continue --show-progress $websource
printf "Downloading ChainDB archive............................................. DONE!\n\n"

# cleanup
filename=${websource##*/}
mv -f "$filename" ChainDB.tar.gz > /dev/null 2>&1
rm -f index.html > /dev/null 2>&1

# NEW websource for the install
websource="http://"$PUBLIC_IP"/ChainDB.tar.gz"

printf "You can now start the script on NEW servers you wanna deploy a node on with:\n\n"

printf "${red}"
printf "wget -O nkndeploy.sh 'http://107.152.46.244/nkndeploy.sh'; bash nkndeploy.sh\n\n"
printf "${normal}"

printf "Custom URL to the ChainDB archive. You will need this URL, make a copy of it!\n\n"
printf "${red}"
printf "http://%s/ChainDB.tar.gz\n\n" "$PUBLIC_IP"
printf "${normal}"

# Question
read -r -p "Do you also want to install a NKN node on this server ? [y/n] " response
case "$response" in
	[yY][eE][sS]|[yY])
	# correct continue script
	installation="local" ; userdata1 ;;
	*)
	# wrong exit
	menuadvanced ;;
esac
}

################################ user input ####################################

function userdata1(){
clear
cat << "EOF"
================================================================================
Setup: necessary data input
To force exit this script press CTRL+C.

Enter the MAINNET! NKN address where you want to receive payments.
Example address: NKNFLRkm3uWZBxohoZAAfBgXPfs3Tp9oY4VQ
================================================================================

NKN Wallet address:
EOF
# Input beneficiary wallet adddress
read -r benaddress

# check wallet address lengh
walletlenght=`expr length "$benaddress"`

if [ $walletlenght == "36" ]; then
	# Continues script
	userdata2
else
	# restarts function F1
cat << "EOF"

NKN wallet address you entered is wrong. Use mainnet NKN wallet,
not ERC-20 wallet. NKN mainnet address starts with NKN*

EOF
	read -sp "Press enter to continue!"
	userdata1
fi
}

function userdata2(){
clear
cat << "EOF"
================================================================================
Setup: necessary data input
To force exit this script press CTRL+C.

A new user will be created for security reasons.
Please use a strong password of choice.
================================================================================

Enter password:
EOF
printf "Pre-set Username: %s\n\n" "$username"

printf "Password:\n"
read -r userpassword
userdata3
}

function userdata3(){
if [ $installtype == "custom" ]; then
	clear
cat << "EOF"
================================================================================
Setup: necessary data input
To force exit this script press CTRL+C.
================================================================================

Enter the custom URL address where the ChainDB*.tar.gz is located at:
EOF
	read -r websource
	printf "\n"

	if curl --output /dev/null --silent --head --fail "$websource"; then
		printf "URL OK: %s\n" "$websource"
		sleep 4
		userdata4
	else
		printf "ERROR URL does NOT exist: %s\n" "$websource"
		sleep 4
		userdata3
	fi
else
	userdata4
fi
}

function userdata4(){
clear
cat << "EOF"
================================================================================
Setup: necessary data input
To force exit this script press CTRL+C
================================================================================

EOF
# Check data if true
printf "Check what you entered:\n\n"

printf "Wallet address: %s\n" "$benaddress"
printf "Username: %s\n" "$username"
printf "Password: %s\n" "$userpassword"
printf "Chain database source: %s\n\n" "$websource"

# Question
read -r -p "Are you sure this data is correct? [y/n] " response
case "$response" in
    [yY][eE][sS]|[yY])
	#correct continue script
	install1 ;;
    *)
	#wrong restarts userdata input
	userdata1 ;;
esac
}

############################# Firewall warning #################################
function firewallwarn(){
clear
# revert all changes
/home/$username/nkn-commercial/nkn-commercial uninstall > /dev/null 2>&1
cd / > /dev/null 2>&1
pkill -KILL -u "$username" > /dev/null 2>&1
deluser --remove-home "$username" > /dev/null 2>&1

printf "${red}"
cat << "EOF"
A modem/router or VPS provided firewall is prohobiting access to the internet!
Please disable the firewall and allow all internet through.

The system changes were REVERTED, once you fix the firewall settings
restart the server and just run the same script again

For info on how to do that visit:
https://forum.nkn.org/t/deploy-miners-faster-fast-deploy-ubuntu-custom-all-in-one-script-your-own-chaindb-no-donation/2753

EOF
printf "${normal}"

read -sp "Press enter to continue!"
exit
}

################################## Install #####################################

function install1(){
clear
cat << "EOF"
           (                 ,&&&.
            )                .,.&&
           (  (              \=__/
               )             ,'-'.
         (    (  ,,      _.__|/ /|
          ) /\ -((------((_|___/ |
        (  // | (`'      ((  `'--|
      _ -.;_/ \\--._      \\ \-._/.
     (_;-// | \ \-'.\    <_,\_\`--'|
     ( `.__ _  ___,')      <_,-'__,'
      `'(_ )_)(_)_)'

================================================================================
This will take some time. Please be patient.
To force exit this script press CTRL+C.
================================================================================

EOF
# disable firewall for the installation
ufw --force disable > /dev/null 2>&1

# Create a new SUDO user
printf "Creating a new Super User account....................................... "
pass=$(perl -e 'print crypt($ARGV[0], "password")' $userpassword) > /dev/null 2>&1
useradd -m -p "$pass" -s /bin/bash "$username" > /dev/null 2>&1
usermod -a -G sudo $username > /dev/null 2>&1
printf "DONE!\n"

# Install NKN node miner software
printf "Downloading NKN node software........................................... "
cd /home/$username > /dev/null 2>&1
wget --quiet --continue https://commercial.nkn.org/downloads/nkn-commercial/linux-amd64.zip > /dev/null 2>&1
printf "DONE!\n"

printf "Installing NKN node software............................................ "
unzip linux-amd64.zip > /dev/null 2>&1
rm -f linux-amd64.zip > /dev/null 2>&1
mv linux-amd64 nkn-commercial > /dev/null 2>&1

chown -R $username:$username /home/$username > /dev/null 2>&1
chmod -R 755 /home/$username > /dev/null 2>&1

/home/$username/nkn-commercial/nkn-commercial -b $benaddress -d /home/$username/nkn-commercial/ -u $username install > /dev/null 2>&1
printf "DONE!\n"

# Wait for DIR and wallet creation
DIR="/home/$username/nkn-commercial/services/nkn-node/"
if [ $database == "no" ]; then
	# script skips DB download and continues
    install3
else
	printf "Waiting for NKN node software to start.................................. "

	timestart=$(date +%s)
	while [[ $(($(date +%s) - $timestart)) -lt 300 ]]; do # 300sec 5 min
		if [ ! -d "$DIR"ChainDB ] && [ ! -f "$DIR"wallet.json ]; then
			# if folder and file don't exist wait and repeat check
			sleep 5
		else
			# when file is detected
			sleep 5 > /dev/null 2>&1
			systemctl stop nkn-commercial.service > /dev/null 2>&1
			sleep 5 > /dev/null 2>&1
			printf "DONE!\n"
			install2
		fi
	done
	# when timer runs out go to the firewall warning
	firewallwarn
fi
}

function install2(){
printf "Downloading / Extracting NKN Chain database.............................\n"
cd "$DIR" > /dev/null 2>&1
rm -rf ChainDB/ > /dev/null 2>&1

# if from beginner menu, extract locally, if not download from websource
if [ $installation == "local" ]; then
	cd /var/www/html/
	#printf "LOCAL!\n"
	pv ChainDB.tar.gz | tar xzf - -C "$DIR"
else
    # internet download
	wget -O - "$websource" -q --show-progress | tar -xzf -
fi

chown -R $username:$username /home/$username > /dev/null 2>&1
chmod -R 755 /home/$username > /dev/null 2>&1

printf "Downloading / Extracting NKN Chain database............................. DONE!\n"
install3
}

function install3(){
# Configure Firewall / ports
printf "Configuring firewall.................................................... "
ufw allow 30001 > /dev/null 2>&1
ufw allow 30002 > /dev/null 2>&1
ufw allow 30003 > /dev/null 2>&1
ufw allow 30004 > /dev/null 2>&1
ufw allow 30005 > /dev/null 2>&1
ufw allow 30010/tcp > /dev/null 2>&1
ufw allow 30011/udp > /dev/null 2>&1
ufw allow 30020/tcp > /dev/null 2>&1
ufw allow 30021/udp > /dev/null 2>&1
ufw allow 32768:65535/tcp > /dev/null 2>&1
ufw allow 32768:65535/udp > /dev/null 2>&1
ufw allow 22 > /dev/null 2>&1
ufw allow 80 > /dev/null 2>&1
ufw allow 443 > /dev/null 2>&1
ufw --force enable > /dev/null 2>&1

systemctl start nkn-commercial.service > /dev/null 2>&1
printf "DONE!\n"

# Disable root password, to enable root again:
# sudo passwd root
# sudo passwd -u root
printf "Disabling Root account for security reasons............................. "
passwd --lock root > /dev/null 2>&1
printf "DONE!\n\n"
install4
}

function install4(){
printf "===============================================================================\n"
printf "Congratulations, you deployed a NKN node!\n"
printf "===============================================================================\n\n"

printf "NKN wallet address: %s\n\n" "$benaddress"

printf "From now on use these settings to connect to your server:\n"
printf "If you're using AWS, Google Cloud, Azure... use the provided keys to login.\n\n"

printf "Server IP: %s\n" "$PUBLIC_IP"
printf "Server username: %s\n" "$username"
printf "Server password: %s\n" "$userpassword"
printf "SSH login: ssh %s@%s\n\n" "$username" "$PUBLIC_IP"

printf "The server should be visible on nstatus.org in a few minutes.\n"
printf "Enter the Server IP provided here!\n"
printf "The node will take an hour or two do it's thing, so dont' worry.\n\n"

printf "Thanks for using this script!\n\n"

exit
}

################################## Menu stuff ##################################

menuadvanced() {
until [ "$selection" = "0" ]; do
clear
printf "${normal}"
cat << "EOF"
         _          __________                              __
     _.-(_)._     ."          ".      .--""--.          _.-{__}-._
   .'________'.   | .--------. |    .'        '.      .:-'`____`'-:.
  [____________] /` |________| `\  /   .'``'.   \    /_.-"`_  _`"-._\
  /  / .\/. \  \|  / / .\/. \ \  ||  .'/.\/.\'.  |  /`   / .\/. \   `\
  |  \__/\__/  |\_/  \__/\__/  \_/|  : |_/\_| ;  |  |    \__/\__/    |
  \            /  \            /   \ '.\    /.' / .-\                /-.
  /'._  --  _.'\  /'._  --  _.'\   /'. `'--'` .'\/   '._-.__--__.-_.'   \
 /_   `""""`   _\/_   `""""`   _\ /_  `-./\.-'  _\'.    `""""""""`    .'`\
(__/    '|    \ _)_|           |_)_/            \__)|        '       |   |
  |_____'|_____|   \__________/   |              |;`_________'________`;-'
   '----------'    '----------'   '--------------'`--------------------`

================================================================================

NKN ChainDB creation:
1) Download ChainDB from NKN.org and host it on THIS server
2) Download ChainDB from a custom URL and host it on THIS server
3) Create ChainDB from own NKN node and host on the SAME server
4) Create ChainDB from own NKN node and host it on ANOTHER server
5) Update existing ChainDB on THIS server

NKN Node server install
6) via custom server (requires URL to ChainDB*.tar.gz)
7) no ChainDB install, sync starts from 0 (takes a long time)

10) Go back to first menu
0) Exit

EOF
printf "Enter selection: "
read selection
printf "\n"

case $selection in
	1 ) mode="advanced" ; method1 ;;
	2 ) method5 ;;
	3 ) method2 ;;
	4 ) method3 ;;
	5 ) method4 ;;

	6 ) installtype="custom" ; database="yes" ; userdata1 ;;
    7 ) database="no" ; websource="none" ; userdata1 ;;

	10 ) menu ;;
	0 ) clear ; exit ;;
	* ) read -sp "Wrong selection press enter to continue!" ;;
esac
done
}

menubeginner() {
until [ "$selection" = "0" ]; do
clear
printf "${blue}"
cat << "EOF"
STEP 1: I have no NKN nodes / servers:

YOU NEED TO DO THIS STEP ONLY ONE TIME!

Hosting the ChainDB archive yourself is essential to deploy your nodes
fast. Get the cheapest server with 1GB+ RAM and 35+ GB of storage
to store the ChainDB archive and start your first NKN node.

Free credits for server providers: https://vpstrial.net/vps/

If THIS server already has enough storage space, then you don't
need to create a new one you can just continue by selecting STEP 1.

EOF
printf "${normal}"
printf "${magenta}"
cat << "EOF"
STEP 2: Deploy new nodes:

RUN STEP 2 ONLY ON NEW SERVERS, not on the first one you created!
Make a new 1core, 1GB RAM, minium 25GB storage ubuntu 20.04+ server
and use the custom URL address provided to you in the first part of the
script to deploy new node servers.

EOF
printf "${normal}"

cat << "EOF"
1) STEP 1: I have no NKN nodes / servers
3) STEP 2: Deploy new nodes

10) Go back to first menu
0) Exit

EOF
printf "Enter selection: "
read selection
printf "\n"

case $selection in
	1 ) mode="beginner" ; database="yes" ; method1 ;;
	2 ) read -sp "Put on your glasses and press enter to continue :D " ; menubeginner ;;
	3 ) installtype="custom" ; database="yes" ; userdata1 ;;

	10 ) menu ;;
	0 ) clear ; exit ;;
	* ) read -sp "Wrong selection press enter to continue!" ;;
esac
done
}

menu() {
until [ "$selection" = "0" ]; do
clear
printf "${normal}"
cat << "EOF"
         _          __________                              __
     _.-(_)._     ."          ".      .--""--.          _.-{__}-._
   .'________'.   | .--------. |    .'        '.      .:-'`____`'-:.
  [____________] /` |________| `\  /   .'``'.   \    /_.-"`_  _`"-._\
  /  / .\/. \  \|  / / .\/. \ \  ||  .'/.\/.\'.  |  /`   / .\/. \   `\
  |  \__/\__/  |\_/  \__/\__/  \_/|  : |_/\_| ;  |  |    \__/\__/    |
  \            /  \            /   \ '.\    /.' / .-\                /-.
  /'._  --  _.'\  /'._  --  _.'\   /'. `'--'` .'\/   '._-.__--__.-_.'   \
 /_   `""""`   _\/_   `""""`   _\ /_  `-./\.-'  _\'.    `""""""""`    .'`\
(__/    '|    \ _)_|           |_)_/            \__)|        '       |   |
  |_____'|_____|   \__________/   |              |;`_________'________`;-'
   '----------'    '----------'   '--------------'`--------------------`

================================================================================

EOF
printf "Welcome to no112358 script for deploying NKN node servers! Version: %s\n\n" "$version"

printf "READ CAREFULLY!\n\n"

printf "${blue}"
printf "1) BEGINNERS SELECT 1!\n\n"
printf "${normal}"

printf "${red}"
printf "3) ADVANCED USER!\n\n"
printf "${normal}"

printf "0) Exit\n\n"

printf "Enter selection: "
read selection
printf "\n"

case $selection in
	1 ) menubeginner ;;
	3 ) menuadvanced ;;
	0 ) clear ; exit ;;
	* ) read -sp "Wrong selection press enter to continue!" ;;
esac
done
}

###################### Start of the script & Root check ####################

# Define colors
red=$(tput setaf 1)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
normal=$(tput sgr0)

if [[ $EUID > 0 ]]; then
printf "${red}"
cat << "EOF"
=================================
PLEASE RUN AS ROOT USER! Type in:

sudo su -

and then run the script again.
=================================
EOF
printf "${normal}"
exit
fi

# Start point
apt-get update -y; apt-get upgrade -y
apt-get install unzip glances vnstat ufw pv -y
username="nkn"
mode="whatever"
database="whatever"
installation="whatever"
PUBLIC_IP=`wget http://ipecho.net/plain -O - -q ; echo`
version="1.1 dev3"
menu
