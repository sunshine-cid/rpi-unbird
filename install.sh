#!/bin/bash
# 03.12.23 
# Currently this file assumes a fresh and updated rasbaian install with appropriate networking configured.
#TODO: Add flag to customize listening type

#Read potential command line flags and set variables
#Current flags:
#-u username - set username to build setup under. Username will end up in sudo and audio groups. Default is current user ($USER)
#-s starttime - set time of day to begin playing sounds (24-hour format). Default is 9am (9)
#-e starttime - set time of day to end playing sounds (24-hour format). Default is 5pm (17)
#-b sambaenable - e to enable samba setup, d to diable samba setup. Default is enable (e)
#-n installnumber - used for setting the installation number in hostname and hosts. Default is 1
while getopts u:s:e:b:n: flag
do
    case "${flag}" in
        u) username=${OPTARG};;
        s) starttime=${OPTARG};;
        e) endtime=${OPTARG};;
        b) sambaenable=${OPTARG};;
        n) installnumber=${OPTARG};;
        esac
done
# if username is null set it to current user
if [ -z "$username" ]; then username="$USER"; fi
# if starttime is null set it to 9am
if [ -z "$starttime" ]; then starttime="9"; fi
#if endtime is null set it to 5pm
if [ -z "$endtime" ]; then endtime="17"; fi
#if sambaenable is null then set it to enabled
if [ -z "$sambaenable" ]; then sambaenable="e"; fi
#if installnumber is null then set it to 1
if [ -z "$installnumber" ]; then installnumber="1"; fi

echo
echo "User for install set to: $username"
echo "Start time for cron jobs is set to $starttime 00 daily"
echo "End time for cron jobs is set to $endtime 00 daily"
echo "Samba enabled is set to $sambaenable"
echo "hostname will be set to $username-$installnumber"
echo

echo "Set group to audio for username..."
sudo usermod -a -G audio $username

echo "Installing mpg321 software..."
sudo apt-get -y install mpg321

#Check if user directory exists in home, if not create it
if [ ! -d "/home/$username/" ]; then
  echo "user folder does not exist in /home/, creating it."
  sudo mkdir /home/$username
  sudo chown $username:$username /home/$username
  sudo chmod 0774 /home/$username
fi

#Sounds
echo "Setup sounds..."
sudo mkdir /home/$username/sounds
echo "Check for zips of sound files..."
if [ -f "hardcore.zip" ] || [ -f "silence.zip" ]  || [ -f "z_listening.zip" ]; then
echo "At least one sound file exists. Skipping downloading..."
else
echo "Downloading sounds..."
wget https://github.com/sunshine-cid/rpi-unbird/raw/master/hardcore.zip
wget https://github.com/sunshine-cid/rpi-unbird/raw/master/silence.zip
wget https://github.com/sunshine-cid/rpi-unbird/raw/master/z_listening.zip
fi
echo "Extracting sounds..."
sudo unzip '*.zip' -d /home/$username/sounds
sudo chown $username:$username /home/$username/sounds/*.*
sudo chown $username:$username /home/$username/sounds
sudo chmod 0774 /home/$username/sounds


#Scripts
echo "Building scripts..."
sudo mkdir /home/$username/scripts
sudo /bin/sh -c "echo 'mpg321 -Z /home/$username/sounds/*.mp3' > /home/$username/scripts/weekday.sh"
sudo /bin/sh -c "echo 'mpg321 -Z /home/$username/sounds/z_*.mp3' > /home/$username/scripts/weekend.sh"
sudo /bin/sh -c "echo 'pkill mpg321' > /home/$username/scripts/clockout.sh"
sudo chown $username:$username /home/$username/scripts/*.sh
sudo chown $username:$username /home/$username/scripts
sudo chmod 0774 /home/$username/scripts/*.sh

#Chron Jobs: Setup as root
echo "Setting cron jobs..."
sudo /bin/sh -c "echo '
0 $starttime * * 1,2,3,4,5 $username /home/$username/scripts/weekday.sh
' > /etc/cron.d/rpi-unbird-weekday"
sudo /bin/sh -c "echo '
0 $starttime * * 0,6 $username /home/$username/scripts/weekend.sh
' > /etc/cron.d/rpi-unbird-weekend"
sudo /bin/sh -c "echo '
0 $endtime * * * $username /home/$username/scripts/clockout.sh
' > /etc/cron.d/rpi-unbird-clockout"

if [ "$sambaenable" = "d" ]; then
echo "Samba disabled..."
else
# Samba setup - help from: http://raspberrywebserver.com/serveradmin/share-your-raspberry-pis-files-and-folders-across-a-network.html
echo "Samba enabled..."
echo "Set hostname as $username-$installnumber and set in /etc/hosts and hostname..."
sudo /bin/sh -c "echo '$username-$installnumber' > /etc/hostname"
sudo hostnamectl set-hostname "$username-$installnumber"
sudo /bin/sh -c "echo '127.0.0.1       localhost' > /etc/hosts"
sudo /bin/sh -c "echo '127.0.1.1       $username-$installnumber' >> /etc/hosts"
sudo systemctl restart systemd-hostnamed
echo "Installing Samba..."
sudo apt-get -y install samba samba-common-bin
echo "Setting up Samba sharing..."
sudo /bin/sh -c "echo '[$username-$installnumber/sounds]' >> /etc/samba/smb.conf"
sudo /bin/sh -c "echo '   comment= Where The rpi-unbird Sounds Are Kept' >> /etc/samba/smb.conf"
sudo /bin/sh -c "echo '   path=/home/$username/sounds' >> /etc/samba/smb.conf"
sudo /bin/sh -c "echo '   browseable=Yes' >> /etc/samba/smb.conf"
sudo /bin/sh -c "echo '   writeable=Yes' >> /etc/samba/smb.conf"
sudo /bin/sh -c "echo '   only guest=no' >> /etc/samba/smb.conf"
sudo /bin/sh -c "echo '   create mask=0777' >> /etc/samba/smb.conf"
sudo /bin/sh -c "echo '   directory mask=0777' >> /etc/samba/smb.conf"
sudo /bin/sh -c "echo '   public=no' >> /etc/samba/smb.conf"
echo "Set Samba password..."
sudo smbpasswd -a $username
fi

echo "Done. Please reboot."
