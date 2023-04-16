#!/bin/bash
# 03.25.23 
# Currently this file assumes a fresh and preferrably updated rasbaian install with appropriate networking and timezone configured.
#TODO: Add flag to customize listening type

#rpi-unbird/install.sh - an Anti-Nesting/Pro-Predatory Bird project. Installs mpg321, downloads MP3's, creates scripts, configures them into cron, and installs/configures SAMBA.

#Read potential command line flags and set variables.
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
#If username is null set it to current user
if [ -z "$username" ]; then username="$USER"; fi
#If starttime is null set it to 9am
if [ -z "$starttime" ]; then starttime="9"; fi
#If endtime is null set it to 5pm
if [ -z "$endtime" ]; then endtime="17"; fi
#If sambaenable is null then set it to enabled
if [ -z "$sambaenable" ]; then sambaenable="e"; fi
#If installnumber is null then set it to 1
if [ -z "$installnumber" ]; then installnumber="1"; fi

#Output command line option settings
echo
echo "User for install set to: $username"
echo "Start time for cron jobs is set to $starttime 00 daily"
echo "End time for cron jobs is set to $endtime 00 daily"
echo "Samba enabled is set to $sambaenable"
echo "hostname will be set to $username-$installnumber"
echo

#Adds $username to the group which allows audio playing
echo "Set group to audio for username..."
sudo usermod -a -G audio $username

#Update apt database, also apt-get upgrade
echo "Run apt update and apt-get upgrade..."
sudo apt update
sudo apt-get -y upgrade

#Install mpg321
echo "Installing mpg321 software..."
sudo apt-get -y install mpg321

#Check if user directory exists in home, if not create it. Set proper file permissions and owner.
if [ ! -d "/home/$username/" ]; then
  echo "user folder does not exist in /home/, creating it."
  sudo mkdir /home/$username
  sudo chown $username:$username /home/$username
  sudo chmod 0774 /home/$username
fi

#Sounds - make sounds directory, check if at least 1 archive file exists and extract it. If no zip files exist download and extract them all. Set proper file permissions.
echo "Setup sounds..."
sudo mkdir /home/$username/sounds
echo "Check for existing archives of sound files..."
if [ -f "hardcore.tar.gz" ] || [ -f "silence.tar.gz" ]  || [ -f "z_listening.tar.gz" ]; then
echo "At least one sound file exists. Skipping downloading..."
else
echo "Downloading sounds..."
#hardcore.tar.gz
wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=17utRjUQqxOFkhayf1sXZh-glHseM9hkY' -O hardcore.tar.gz
#silence.tar.gz
wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=1Cj3GPME60wuc09MjoSRDZ7U7-jAp590t' -O silence.tar.gz
#z_listening.tar.gz
wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=11xxkFh0JgG1EOiqHwyAQ0AFWD7mNa7sF' -O z_listening.tar.gz
fi
echo "Extracting sounds..."
for filename in ./*.tar.gz; do sudo tar -xjvf $filename -C /home/$username/sounds/; done 
sudo chown $username:$username /home/$username/sounds/*.*
sudo chown $username:$username /home/$username/sounds
sudo chmod 0774 /home/$username/sounds


#Scripts - Create scripts which will be used by cron. Set proper file permissions and owner.
echo "Building scripts..."
sudo mkdir /home/$username/scripts
sudo /bin/sh -c "echo 'mpg321 -Z /home/$username/sounds/*.mp3' > /home/$username/scripts/weekday.sh"
sudo /bin/sh -c "echo 'mpg321 -Z /home/$username/sounds/z_*.mp3' > /home/$username/scripts/weekend.sh"
sudo /bin/sh -c "echo 'pkill mpg321' > /home/$username/scripts/clockout.sh"
sudo chown $username:$username /home/$username/scripts/*.sh
sudo chown $username:$username /home/$username/scripts
sudo chmod 0774 /home/$username/scripts/*.sh

#Chron Jobs - Setup cron jobs according to schedule. Must be written as root.
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

#SAMBA - If enabled set hosts and hostname according to $username-$installnumber convention, install SAMBA, append configuration for a fileshare, set SAMBA password for $username. 
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
#Utilizes Heredoc to append the SMABA config to /etc/samba/smb.conf
sudo cat << SAMBA >> /etc/samba/smb.conf

[$username-$installnumber-sounds]
   comment= Where The rpi-unbird Sounds Are Kept
   path=/home/$username/sounds
   browseable=Yes
   writeable=Yes
   only guest=no
   create mask=0777
   directory mask=0777
   public=no
SAMBA
echo "Set Samba password..."
sudo smbpasswd -a $username
fi

echo "Done. Please reboot."
