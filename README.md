rpi-unbird - <sub>With a Raspberry Pi and a speaker you too can discourage nesting and attract hawks!</sub>
----------
Birds often damage property and may pose a health hazard. They are often, rightly, protected and cannot be managed through barbaric means. They can however potentially be managed through their sensitivities and through encouraging their predators and competitors. rpi-unbird utilizes the portable nature of the Raspberry Pi, though any portable, linux device may be used, with an external speaker to play animal sounds which both discourage birds from congregating and encourage natural predators like hawks to patrol the area.

At it's most fundamental level an rpi-unbird device can be considered an electronic game call device/speaker combo. Hunting birds is illegal in many juristictions. Be sure you know the laws in your area.

Instructions for build - <sub>Difficulty: Semi-Moderate (requires experience building and configuring a raspberry pi)</sub>
----------
Items Required:

RaspberryPi (or any portable/small Single Board Computer running Linux)

Portable plug-in speaker

Power Source (a battery bank or appropriate wall plugs)

Appropriate cords

Install and configure your OS (Rasbian). I strongly recommend setting your time and time zone correctly so the scripts will execute at appropriate and intended times. 

// Instructions for installation

Download either via git or wget:

>git clone https://github.com/sunshine-cid/rpi-unbird.git

or

>wget https://github.com/sunshine-cid/rpi-unbird/raw/master/install.sh

then run:

>bash install.sh

Command line flags available:

-u username - set username to build setup under. Username will end up in sudo and audio groups. Default is current user ($USER)

-s starttime - set time of day to begin playing sounds (24-hour format). Default is 9am (9)

-e starttime - set time of day to end playing sounds (24-hour format). Default is 5pm (17)

-b sambaenable - d to diable samba setup, e to enable samba setup. Default is enable (e)

-n installnumber - used for setting the installation number in hostname and hosts. Default is 1


If you don't want to include any set of sounds in the install, just delete the zip file. Though I strongly recommend keeping the silence.zip as continual squaking and screaming for 8 hours a day is unrealistic and pretty disturbing. And also if you want to include additional sounds include a zip file of the MP3's. MP3's which have a 'z_' prefix will be included in weekday AND weekend e"z_"listening scripts.

// credits

Thank you to https://raspberrywebserver.com/serveradmin/share-your-raspberry-pis-files-and-folders-across-a-network.html for their invaluable help configuring SAMBA.
