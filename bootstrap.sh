#!/bin/bash

set -e
set -x

# Enable extra repositories
sudo add-apt-repository -y universe multiverse

# Download .deb packages
## Dropbox
[ ! -f ~/Downloads/dropbox_2020.03.04_amd64.deb ] && wget https://www.dropbox.com/download\?dl=packages/ubuntu/dropbox_2020.03.04_amd64.deb -O ~/Downloads/dropbox_2020.03.04_amd64.deb

## Minecraft
[ ! -f ~/Downloads/Minecraft.deb ] && wget https://launcher.mojang.com/download/Minecraft.deb -O ~/Downloads/Minecraft.deb

## Moneydance
[ ! -f ~/Downloads/moneydance_linux_amd64.deb ] && wget https://infinitekind.com/stabledl/current/moneydance_linux_amd64.deb -O ~/Downloads/moneydance_linux_amd64.deb

## Obsidian
[ ! -f ~/Downloads/obsidian_1.0.0_amd64.deb ] && wget https://github.com/obsidianmd/obsidian-releases/releases/download/v1.0.0/obsidian_1.0.0_amd64.deb -O ~/Downloads/obsidian_1.0.0_amd64.deb

## Zoom
[ ! -f ~/Downloads/zoom_amd64.deb ] && wget https://zoom.us/client/5.12.2.4816/zoom_amd64.deb -O ~/Downloads/zoom_amd64.deb

## Chrome
[ ! -f ~/Downloads/google-chrome-stable_current_amd64.deb ] && wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O ~/Downloads/google-chrome-stable_current_amd64.deb

# Add apt repositories
## Albert
[ ! -f /etc/apt/trusted.gpg.d/home_manuelschneid3r.gpg ] && wget -qO - https://download.opensuse.org/repositories/home:manuelschneid3r/xUbuntu_22.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_manuelschneid3r.gpg
echo 'deb http://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_22.04/ /' | sudo tee /etc/apt/sources.list.d/home:manuelschneid3r.list

## Ticktick
[ ! -f ~/Downloads/ticktick-1.0.40-amd64.deb ] && wget https://appest-public.s3.amazonaws.com/download/linux/linux_deb_x64/ticktick-1.0.40-amd64.deb -O ~/Downloads/ticktick-1.0.40-amd64.deb

## Yubikey software
sudo add-apt-repository -y ppa:yubico/stable

## System76 PPA
sudo OUT=/etc/apt/preferences.d/system76-apt-preferences sh -c 'cat << EOF >> ${OUT}
Package: *
Pin: release o=LP-PPA-system76-dev-stable
Pin-Priority: 1001

Package: *
Pin: release o=LP-PPA-system76-dev-pre-stable
Pin-Priority: 1001

EOF'

sudo apt-add-repository -y ppa:system76-dev/stable

# Update package index files
sudo apt update

# Install apt packages
sudo apt install -y albert bat build-essential flatpak fprintd gir1.2-gda-5.0 gir1.2-gsound-1.0 gir1.2-gtop-2.0 gnome-keyring gnome-shell-extension-manager gnome-tweaks gnuplot graphviz htop input-remapper libaio1 libdebconfclient0 libdevmapper-event1.02.1 libfido2-1 libfuse2 libgtop2-dev login lvm2 mokutil myrepos ncdu pcscd podman python3-pip silversearcher-ag sshuttle stow texlive-full tig tmux vim virt-manager virt-viewer virtinst wl-clipboard yubikey-manager yubikey-personalization zsh-autosuggestions zsh-syntax-highlighting zsh system76-driver scdaemon curl yubikey-manager libpam-yubico libpam-u2f btop

# Install snaps
sudo snap install authy bitwarden icloud-for-linux mattermost-desktop multipass slack spotify telegram-desktop zotero-snap morgen mailspring code

# Install tailscale
wget -qO - https://tailscale.com/install.sh | sh

# Install podman-compose
sudo pip install podman-compose

# Setup Flathub
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install Junction
flatpak install -y Junction

# Install the downloaded .deb files
for x in ~/Downloads/*.deb
do
    sudo apt install -y ${x}
done

# Download zimfw
wget -qO - https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh

# Set default shell to zsh
sudo chsh -s /usr/bin/zsh tmoyer

# Busylight
python3 -m pip install busylight-for-humans

busylight udev-rules -o 99-busylights.rules
sudo cp 99-busylights.rules /etc/udev/rules.d
sudo udevadm control -R

# Useful commands to run depending on the desktop
echo "Need to run Stow to setup symlinks"
echo "To turn off Evolution alarm pop-ups: gsettings set org.gnome.evolution-data-server.calendar notify-with-tray true"
echo "To set Juntion as the default browser: xdg-settings set default-web-browser re.sonny.Junction.desktop"
echo "To ensure that the Chrome profile options are in the menu: update-desktop-database ~/.local/share/applications"
echo "Center windows in Gnome: gsettings set org.gnome.mutter center-new-windows true"
echo "To have Junction find Chrome profiles: update-desktop-database ~/.local/share/flatpak/exports/share/applications"
echo "Gnome Shell Extensions to install: Extension Sync"

echo << EOF
sudo apt install libpam-u2f
pamu2fcfg | sudo tee -a /etc/u2f_mappings

# (At this point, press the button. You should see a long string of numbers.
# If you don't, make sure you have `udev` setup correctly.)

sudo -i
echo >> /etc/u2f_mappings
cd /etc/pam.d

echo 'auth sufficient pam_u2f.so authfile=/etc/u2f_mappings cue' > common-u2f

for f in $(grep -l "@include common-auth" *); do
  if [[ $f == *~ ]]; then continue; fi
  if grep -q "@include common-u2f" $f; then continue; fi
  mv $f $f~
  awk '/@include common-auth/ {print "@include common-u2f"}; {print}' $f~ > $f
done

exit
EOF

echo "Bootstrap complete, please check output carefully"
