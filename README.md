# Kiosk installer for Debian based Linux distros
Small installer script to setup a minimal kiosk with Firefox for Debian based Linux distros. This installer is heavily based on [the script published by josfaber](https://github.com/josfaber/debian-kiosk-installer).

It's been modifed to use firefox-esr instead of chrome because the customisation options are better imo (and chrome keeps changing the console start-parameters that have been used in the original script)

## Usage
* Setup a minimal Debian (preferably get the 64bit netinst iso and set it up without any desktop env., do install standard system tools and maybe ssh server for remote access tho) [Download](https://www.debian.org/distrib/)
* Login as root or with root permissions
* Download this installer, make it executable and run it
  ```shell
  wget https://raw.githubusercontent.com/zango-me/debian-kiosk-installer/master/kiosk-installer.sh; chmod +x kiosk-installer.sh;
  ```
* Edit the KIOSK_URL at the beginning of the file to your liking
  ```shell
  #!/bin/bash

  # THE KIOSK URL
  KIOSK_URL="https://example.com"

  ...
  ```
* Run the script to install
  ```shell
  ./kiosk-installer.sh
  ```
 
* Wait for it to finish & reboot

## What will it do?
It will create a normal user `kiosk`, install software (check the script) and setup configs (it will backup existing) so that on reboot the kiosk user will login automaticaly and run firefox-esr in kiosk mode with one url. It will also hide the mouse and disable screen-blanking. 

## Change the url
Change the url at the top of the script, where it sais KIOSK_URL="https://example.com"

## Is it secure?
No. Although it will run as a normal user (and I suggest you don't leave a keyboard and mouse hanging around), there will be the possibility of plugin' in a mini keyboard, opening a terminal and opening some nasty things. Security is your thing ;-) 
