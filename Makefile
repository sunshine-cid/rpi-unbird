.PHONY: all info audiogroup update mpg321 homedir dlsounds nosilence exsounds scripts button samba done

username=$$USER
starttime=9
endtime=15
installnumber=1

define sambaconf
[rpi-unbird-1]\n   comment= Where The rpi-unbird Sounds Are Kept\n   path=/home/rpi-unbird\n   browseable=Yes\n   writeable=Yes\n   only guest=no\n   create mask=0777\n   directory mask=0777\n   public=no\n
endef

define buttonpy
\#!/bin/python3\nimport RPi.GPIO as GPIO\nimport os\nimport subprocess\nimport time\nprint(\"This program is intended to be run as a service. Ctrl-C to quit\")\ndef onButton(channel):\n    if channel == 16:\n        subprocess.Popen(\"/home/$(username)/scripts/button.sh\")\nGPIO.setmode(GPIO.BCM)\nGPIO.setup(16, GPIO.IN, pull_up_down=GPIO.PUD_UP)\nGPIO.add_event_detect(16, GPIO.FALLING, callback=onButton, bouncetime=10)\nwhile True:\n    time.sleep(1)\n
endef

define buttonsh
\#!/bin/bash\nif pgrep -x \"mpg321\" > /dev/null\nthen\n    pkill mpg321\nelse\n    mpg321 -Z /home/$(username)/sounds/*.mp3 &\nfi\n
endef

define buttonservice
[Unit]\nDescription=Button Detectin Py service\nAfter=network.target\n\n[Service]\nExecStart=/usr/bin/python /home/$(username)/scripts/button.py\nWorkingDirectory=/home/$(username)/scripts\nStandardOutput=inherit\nStandardError=inherit\nRestart=always\nUser=$(username)\n\n[Install]\nWantedBy=multi-user.target\n
endef

all: info audiogroup update mpg321 homedir dlsounds exsounds scripts done

info:
	@#Outputs command line option variable values
	@echo "-----"
	@echo "User for install set to: $(username)"
	@echo "Start time for cron jobs is set to $(starttime)00 daily"
	@echo "End time for cron jobs is set to $(endtime)00 daily"
	@echo "hostname will be set to $(username)-$(installnumber)"
	@echo "-----"

audiogroup:
	@#Adds $$username to the group which allows audio playing
	@echo "Set group to audio for $(username)..."
	@sudo usermod -a -G audio $(username)

update:
	@#Update apt database, also apt-get upgrade
	@echo "Run apt update and apt-get upgrade..."
	@sudo apt update
	@sudo apt-get -y upgrade

mpg321:
	@#Installs mpg321
	@echo "Installing mpg321 software..."
	@sudo apt-get -y install mpg321

homedir:
	@#Check if home directory exists, if not create it
	@echo "Verigying home directory exists..."
	@if [ ! -d "/home/$(username)/" ]; then \
	echo "user folder does not exist in /home/, creating it."; \
	sudo mkdir /home/$(username); \
	sudo chown $(username):$(username) /home/$(username); \
	sudo chmod 0774 /home/$(username); \
	fi

dlsounds:
	@#Dlsounds - make sounds directory, check if at least 1 archive file exists and extract it. If no zip files exist download and extract them all. Set proper file permissions.
	@echo "Setup sounds..."
	@sudo mkdir /home/$(username)/sounds
	@echo "Check for existing archives of sound files..."
	@if [ -f "hardcore.tar.gz" ] || [ -f "silence.tar.gz" ]  || [ -f "z_listening.tar.gz" ]; then \
	echo "At least one sound file exists. Skipping downloading..."; \
	else \
	echo "Downloading sounds..."; \
	#hardcore.tar.gz; \
	wget --no-check-certificate 'https://docs.google.com/uc?export=download&confirm=t&id=17utRjUQqxOFkhayf1sXZh-glHseM9hkY' -O hardcore.tar.gz; \
	#silence.tar.gz; \
	wget --no-check-certificate 'https://docs.google.com/uc?export=download&confirm=t&id=1Cj3GPME60wuc09MjoSRDZ7U7-jAp590t' -O silence.tar.gz; \
	#z_listening.tar.gz; \
	wget --no-check-certificate 'https://docs.google.com/uc?export=download&confirm=t&id=11xxkFh0JgG1EOiqHwyAQ0AFWD7mNa7sF' -O z_listening.tar.gz; \
	fi

nosilence:
	@#Removed the silence sound pack. Mainly used in conjuction with the button configuration
	@echo "Removing the silence.tar.gz soound pack..."
	@rm silence.tar.gz

exsounds:
	@#Exsounds - extract present sound packs, set ownership to $(username) and permissions to ug+rwx, o+r
	@echo "Extracting sounds..."
	@for file in ./*.tar.gz; do \
	sudo tar -xjvf $${file} -C /home/$(username)/sounds/; \
	done 
	@sudo chown $(username):$(username) /home/$(username)/sounds/*.*
	@sudo chown $(username):$(username) /home/$(username)/sounds
	@sudo chmod 0774chmod 0774 /home/$(username)/sounds

scripts:
	@#Scripts - Create scripts which will be used by cron. Set proper file permissions and owner.
	@echo "Building scripts..."
	@sudo mkdir /home/$(username)/scripts
	@sudo /bin/sh -c "echo 'mpg321 -Z /home/$(username)/sounds/*.mp3' > /home/$(username)/scripts/weekday.sh"
	@sudo /bin/sh -c "echo 'mpg321 -Z /home/$(username)/sounds/z_*.mp3' > /home/$(username)/scripts/weekend.sh"
	@sudo /bin/sh -c "echo 'pkill mpg321' > /home/$(username)/scripts/clockout.sh"
	@sudo chown $(username):$(username) /home/$(username)/scripts/*.sh
	@sudo chown $(username):$(username) /home/$(username)/scripts
	@sudo chmod 0774 /home/$(username)/scripts/*.sh

button:
	@#Button - If enabled installs python, pip, and GPIO. Adds user to GPIO group. Builds related scripts and installs python script service 
	@#Thanks for Py script to: https://raspberrypi.stackexchange.com/questions/76342/run-a-shell-script-from-a-python-script-when-a-button-is-pressed
	@#And thanks for shell script to: https://askubuntu.com/questions/157779/how-to-determine-whether-a-process-is-running-or-not-and-make-use-it-to-make-a-c 
	@#And thanks to systemd service info from: https://stackoverflow.com/questions/67745554/autostarting-python-scripts-on-boot-using-crontab-on-rasbian
	@echo "Push-button to play or kill option enabled..."
	@sudo apt install python3 python3-pip
	@pip3 install RPi.GPIO
	@sudo usermod -a -G gpio $(username)
	@sudo /bin/sh -c "echo '$(buttonpy)' > /home/$(username)/scripts/button.py"
	@sudo /bin/sh -c "echo '$(buttonsh)' > /home/$(username)/scripts/button.sh"
	@sudo chmod ug+x /home/$(username)/scripts/button.sh
	@sudo /bin/sh -c "echo '$(buttonservice)' > /etc/systemd/system/buttonpy.service"
	@sudo systemctl enable buttonpy.service

cron:
	@#Chron Jobs - Setup cron jobs according to schedule. Must be written as root.
	@echo "Setting cron jobs..."
	@sudo /bin/sh -c "echo '0 $(starttime) * * 1,2,3,4,5 $(username) /home/$(username)/scripts/weekday.sh' > /etc/cron.d/rpi-unbird-weekday"
	@sudo /bin/sh -c "echo '0 $(starttime) * * 0,6 $(username) /home/$(username)/scripts/weekend.sh' > /etc/cron.d/rpi-unbird-weekend"
	@sudo /bin/sh -c "echo '0 $(endtime) * * * $(username) /home/$(username)/scripts/clockout.sh' > /etc/cron.d/rpi-unbird-clockout"

samba:
	#SAMBA - If enabled set hosts and hostname according to $$username-$$installnumber convention, install SAMBA, append configuration for a fileshare, set SAMBA password for $$username. 
	@echo "Samba enabled..."
	@#Set unique hostname
	@echo "Set hostname as $(username)-$(installnumber) and set in /etc/hosts and hostname..."
	@sudo /bin/sh -c "echo '$(username)-$(installnumber)' > /etc/hostname"
	@sudo hostnamectl set-hostname "$(username)-$(installnumber)"
	@sudo /bin/sh -c "echo '127.0.0.1       localhost' > /etc/hosts"
	@sudo /bin/sh -c "echo '127.0.1.1       $(username)-$(installnumber)' >> /etc/hosts"
	@sudo systemctl restart systemd-hostnamed
	@echo "Installing Samba..."
	@sudo apt-get -y install samba samba-common-bin
	@echo "Setting up Samba sharing..."
	@sudo /bin/sh -c "echo '$(sambaconf)' >> /etc/samba/smb.conf"
	@echo "Set Samba password..."
	@sudo smbpasswd -a $(username)

done:
	@echo "Done. Please reboot."