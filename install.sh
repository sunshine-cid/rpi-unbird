#!/bin/bash
# 02.27.23 
# Currently this file assumes a fresh and updated rasbaian install with appropriate networking configured.
#TODO: Correct permissions and use of sudo
#TODO: Add flag to customize listening type
#TODO: Add flag to customize Samba
#TODO: Add flag to customize schedule

#Read potential command line flags and set variables
#Current flags:
#-u username - set username to build setup under, if empty use current user. Username will end up in sudo and audio groups

while getopts u: flag
do
    case "${flag}" in
        u) username=${OPTARG};;
        esac
done
# if username is null set it to current user
if [ -z "$username" ]; then username="$USER"; fi

echo "Username set as: $username";

echo "Set permissions for sudo and audio for username"
sudo usermod -a -G audio,sudo $username

echo "Set hostname as $username-1 and set in /etc/hosts"
sudo hostnamectl set-hostname "$username-1" --pretty
sudo /bin/sh -c "echo '127.0.0.1       localhost' > /etc/hosts"
##echo file, sudo echo file in
sudo /bin/sh -c "echo '127.0.1.1       $username-1' >> /etc/hosts"

echo "Installing necessary software..."
sudo apt-get -y install mpg321
sudo apt-get -y install samba samba-common-bin

# Download and extract sounds
echo "Downloading sounds..."
cd /home/$username/
mkdir ./sounds
cd sounds
wget https://github.com/sunshine-cid/rpi-unbird/raw/master/hardcore.zip
wget https://github.com/sunshine-cid/rpi-unbird/raw/master/silence.zip
wget https://github.com/sunshine-cid/rpi-unbird/raw/master/z_listening.zip
echo "Extracting sounds..."
sudo unzip '*.zip'
sudo chmod 0777 /home/$username/sounds

#Scripts
echo "Building scripts..."
cd /home/$username
mkdir scripts
cd /home/$username/scripts
sudo /bin/sh -c "echo 'mpg321 -Z /home/$username/sounds/*.mp3' > weekday.sh"
sudo chmod uga+rwx weekday.sh
sudo /bin/sh -c "echo 'mpg321 -Z /home/$username/sounds/z_*.mp3' > weekend.sh"
sudo chmod uga+rwx weekend.sh
sudo /bin/sh -c "echo 'pkill mpg321' > clockout.sh"
sudo chmod uga+rwx clockout.sh

#Chron Jobs: Setup as root
echo "Setting cron jobs..."
sudo /bin/sh -c "echo '
0 9 * * 1,2,3,4,5 $username /home/$username/scripts/weekday.sh
' > /etc/cron.d/rpi-unbird-weekday"
sudo /bin/sh -c "echo '
0 9 * * 0,6 $username /home/$username/scripts/weekend.sh
' > /etc/cron.d/rpi-unbird-weekend"
sudo /bin/sh -c "echo '
0 17 * * * $username home/$username/scripts/clockout.sh
' > /etc/cron.d/rpi-unbird-clockout"

# Samba setup - help from: http://raspberrywebserver.com/serveradmin/share-your-raspberry-pis-files-and-folders-across-a-network.html
echo "Setting up Samba share..."
##echo file, sudo echo file in
sudo /bin/sh -c "echo '[$username/sounds]' >> /etc/samba/smb.conf"
sudo /bin/sh -c "echo '   comment= Where The rpi-unbird Sounds Are Kept' >> /etc/samba/smb.conf"
sudo /bin/sh -c "echo '   path=/home/$username/sounds' >> /etc/samba/smb.conf"
sudo /bin/sh -c "echo '   browseable=Yes' >> /etc/samba/smb.conf"
sudo /bin/sh -c "echo '   writeable=Yes' >> /etc/samba/smb.conf"
sudo /bin/sh -c "echo '   only guest=no' >> /etc/samba/smb.conf"
sudo /bin/sh -c "echo '   create mask=0777' >> /etc/samba/smb.conf"
sudo /bin/sh -c "echo '   directory mask=0777' >> /etc/samba/smb.conf"
sudo /bin/sh -c "echo '   public=no' >> /etc/samba/smb.conf"

sudo smbpasswd -a $username

echo "Done."
