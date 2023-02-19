# 02.19.23 
# Currently this file lacks the links to download the sounds
# Currnetly this install script should be used to copy/paste the necessary commands
# Currently this file assumes a completely fresh rasbaian install.

# Root Password Change
passwd root
# Add User
adduser unbird
#adduser unbird sudo,audio
usermod -a -G audio,sudo unbird

sudo /bin/sh -c 'echo "rpi-unbird-1" > /etc/hostname'
sudo /bin/sh -c 'echo "127.0.0.1       localhost" > /etc/hosts'
sudo /bin/sh -c 'echo "127.0.1.1       rpi-unbird-1" >> /etc/hosts'

dpkg-reconfigure tzdata

apt-get -y install raspi-config
raspi-config

apt-get update
apt-get -y install sudo

# Configure a way to persist commands after a reboot
reboot

sudo apt-get -y install wireless-tools
sudo apt-get -y install wpasupplicant
sudo apt-get -y install nano

#Wifi Setup

sudo /bin/sh -c 'echo "network={
ssid="AircrackThis"
key_mgmt=NONE
wep_key0="0000000000"
}" >> /etc/wpa_supplicant/wpa_supplicant.conf'

 
sudo /bin/sh -c 'echo "
# The wifi (wireless) network interface
auto wlan0
allow-hotplug wlan0
iface wlan0 inet dhcp
       wireless-essid AircrackThis
       wireless-key 0000000000" >> /etc/network/interfaces'

#Fix WiFi 'Sleep" - Find a universal command?
sudo /bin/sh -c 'echo "# Disable power management
options 8192cu rtw_power_mgnt=0" >> /etc/modprobe.d/8192cu.conf'


sudo apt-get -y install mpg321
sudo apt-get -y install samba samba-common-bin


# Download and extract sounds
mkdir /home/unbird/sounds
sudo chmod 0777 /home/unbird/sounds

#Scripts
cd /home/unbird
mkdir scripts
cd /home/unbird/scripts
sudo /bin/sh -c 'echo "mpg321 -Z /home/unbird/sounds/*.mp3" > weekday.sh'
chmod uga+rwx weekday.sh
sudo /bin/sh -c 'echo "mpg321 -Z /home/unbird/sounds/z_*.mp3" > weekend.sh'
chmod uga+rwx weekend.sh
sudo /bin/sh -c 'echo "pkill mpg321" > clockout.sh'
chmod uga+rwx clockout.sh

#Chron Jobs: Setup as root
sudo /bin/sh -c 'echo "
0 9 * * 1,2,3,4,5 unbird /home/unbird/scripts/weekday.sh
" > /etc/cron.d/weekday'
sudo /bin/sh -c 'echo "
0 9 * * 0,6 admin /home/unbird/scripts/weekend.sh
" > /etc/cron.d/weekend'
sudo /bin/sh -c 'echo "
0 17 * * * root home/unbird/scripts/clockout.sh
" > /etc/cron.d/clockout'

# Samba setup - help from: http://raspberrywebserver.com/serveradmin/share-your-raspberry-pis-files-and-folders-across-a-network.html

sudo /bin/sh -c 'echo "[unbird/sounds]" >> /etc/samba/smb.conf'
sudo /bin/sh -c 'echo "   comment= Where The Sounds Are Kept" >> /etc/samba/smb.conf'
sudo /bin/sh -c 'echo "   path=/home/unbird/sounds" >> /etc/samba/smb.conf'
sudo /bin/sh -c 'echo "   browseable=Yes" >> /etc/samba/smb.conf'
sudo /bin/sh -c 'echo "   writeable=Yes" >> /etc/samba/smb.conf'
sudo /bin/sh -c 'echo "   only guest=no" >> /etc/samba/smb.conf'
sudo /bin/sh -c 'echo "   create sudo /bin/sh -c 'mask=0777" >> /etc/samba/smb.conf''
sudo /bin/sh -c 'echo "   directory mask=0777" >> /etc/samba/smb.conf'
sudo /bin/sh -c 'echo "   public=no" >> /etc/samba/smb.conf'

sudo smbpasswd -a unbird
