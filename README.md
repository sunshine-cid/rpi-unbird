rpi-unbird
----------

<strong>With a Raspberry Pi and a speaker you too can discourage nesting and attract hawks!</strong>

Birds often damage property and may pose a health hazard. They are often, rightly, protected and cannot be managed through barbaric means. They can however potentially be managed through their sensitivities and through encouraging their predators and competitors. rpi-unbird utilizes the portable nature of the Raspberry Pi, though any portable, linux device may be used, with an external speaker to play animal sounds which both discourage birds from congregating and encourage natural predators like hawks to patrol the area.

At it's most fundamental level an rpi-unbird device can be considered an electronic game call device/speaker combo. Hunting birds is illegal in many juristictions. Be sure you know the laws in your area.

Instructions for build
----------

<strong>Difficulty: Semi-Easy (must build and configure a raspberry pi)</strong>

Items Required:

* RaspberryPi (or any portable/small Single Board Computer running Linux)
* Portable plug-in speaker
* Power Source (a battery bank or wall plugs)
* Appropriate cords
* Install and configure your OS (Rasbian). I strongly recommend setting your time and time zone correctly so the scripts will execute at the intended times. 

Instructions for Installation
----------

<strong>Assumes correct timezone and networking configured</strong>

Download either via git or wget and install (installing user MUST have sudo privelages):

```sh
wget https://github.com/sunshine-cid/rpi-unbird/raw/master/Makefile
make
```

or

```sh
git clone https://github.com/sunshine-cid/rpi-unbird.git
cd ./rpi-unbird
make
```

Command-Line Variables:

```
username - set username to build setup under /home/username. This user must exist. Default is current user ($USER)
starttime - set time of day to begin playing sounds (24-hour format). Default is 9am (9)
endtime - set time of day to end playing sounds (24-hour format). Default is 5pm (17)
sambaenable - d to disable samba setup, e to enable samba setup. Default is disabled (d)
installnumber - used for setting the installation number in hostname and hosts. Default is 1
```

For example:
```
make username=root starttime=7 endtime=15 sambaenable=e installnumber=2
```
This will create all the files in /home/root, start playing sounds at 7:00am, stop playing sounds at 3:00pm, install Samba and set hostname to root-2

How the schedule works:

Weekdays (M-F) play all the sound packs. Weekends (Sa-Su) play only sounds beginning with a 'z_' prefix. You can use these guidelines to alter the behavior of what plays when. 

Changing what plays:

If you don't want to include any set of sounds in the install, download the files seperately by copying the download portion of the code, running it, and then delete the tar.gz file you do not want to include. Though I strongly recommend keeping the silence.tar.gz as continual squaking and screaming for 8 hours a day is unrealistic and pretty disturbing. The script is setup to not download if any of the default files exist.

Adding sounds:

If you want to include additional sounds pre-install include a tar.gz file of the MP3's in the same folder you execute the script in. MP3's which have a 'z_' prefix will be included in weekday AND weekend e"z_"listening cron-job scripts.

The option to use SAMBA for network sharing can be enabled on the command line by adding the flag 'sambaenable=e'

Alternatively, you can use SCP to transfer files easily and securely over SSH. Instruction for using SCP can be found at: https://linuxize.com/post/how-to-use-scp-command-to-securely-transfer-files/ 

Also, for windows users, WinSCP is a free utility which can be found at https://winscp.net/

Credits
----------

Thank you to https://chemicloud.com/kb/article/download-google-drive-files-using-wget/ for the detailed instructions regarding wget'ing files from Google Drive.

Thank you to https://raspberrywebserver.com/serveradmin/share-your-raspberry-pis-files-and-folders-across-a-network.html for their invaluable help configuring SAMBA.
