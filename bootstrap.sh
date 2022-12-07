#!/bin/bash

GNOME=""
KDE="syncthingtray-kde-plasma"
SYSTEM76=""
CMD=""

DRY_RUN=0

GUI_APT_PKGS="albert fprintd gnome-keyring gnuplot graphviz input-remapper texlive-full virt-manager virt-viewer yubikey-manager yubikey-personalization system76-wallpapers yubikey-manager syncthing"
GUI_SNAPS="authy bitwarden icloud-for-linux mattermost-desktop slack spotify telegram-desktop zotero-snap morgen mailspring"
GUI_SNAPS_CLASSIC="code"

CLI_APT_PKGS="bat build-essential flatpak htop libfuse2 myrepos ncdu pcsd podman python3-pip silversearcher-ag sshuttle stow tig tmux vim virtinst zsh-autosuggestions zsh-syntax-highlighting zsh scdaemon curl libpam-yubico libpam-u2f btop"
CLI_SNAPS="multipass"
CLI_ONLY=0

GITHUB_KEY=""

usage() {
  echo "Usage: $0 [ -n ] [ -g ] [ -k ] [ -s ] [ -d ] [ -c ]" 1>&2
  echo " -n : dry-run, just show what would be executed"
  echo " -k : install KDE packages"
  echo " -g : install Gnome packages"
  echo " -s : install System76 drivers"
  echo " -d : debug, show commands"
  echo " -c : command-line only stuff, skip the GUI"
}

exit_abnormal() {
  usage
  exit 1
}

if [[ "$EUID" == 0 ]] ; then
  echo "Please do not run as root. This script will use sudo when root privileges are needed"
  exit 1
fi

while getopts ":gksdnc" options; do
  case "${options}" in
    g)
      GNOME="gir1.2-gda-5.0 gir1.2-gsound-1.0 gir1.2-gtop-2.0 gnome-shell-extension-manager gnome-tweaks wl-clipboard"
      ;;
    k)
      KDE=""
      ;;
    s)
      SYSTEM76="system76-drivers"
      ;;
    d)
      set -x
      ;;
    c)
      GUI_APT_PKGS=""
      GUI_SNAPS=""
      CLI_ONLY=1
      ;;
    n)
      CMD='echo'
      DRY_RUN=1
      ;;
    :)
      echo "Error: -${OPTARG} requires an argument."
      exit_abnormal
      ;;
    *)
      exit_abnormal
      ;;
  esac
done

set -e

# Enable extra repositories
${CMD} sudo add-apt-repository -y universe multiverse

# Download .deb packages

if [[ ${CLI_ONLY} == 0 ]]; then
  mkdir -p ~/Downloads
  ## Dropbox
  [ ! -f ~/Downloads/dropbox_2020.03.04_amd64.deb ] && ${CMD} wget https://www.dropbox.com/download\?dl=packages/ubuntu/dropbox_2020.03.04_amd64.deb -O ~/Downloads/dropbox_2020.03.04_amd64.deb

  ## Minecraft
  [ ! -f ~/Downloads/Minecraft.deb ] && ${CMD} wget https://launcher.mojang.com/download/Minecraft.deb -O ~/Downloads/Minecraft.deb

  ## Moneydance
  [ ! -f ~/Downloads/moneydance_linux_amd64.deb ] && ${CMD} wget https://infinitekind.com/stabledl/current/moneydance_linux_amd64.deb -O ~/Downloads/moneydance_linux_amd64.deb

  ## Obsidian
  [ ! -f ~/Downloads/obsidian_1.0.0_amd64.deb ] && ${CMD} wget https://github.com/obsidianmd/obsidian-releases/releases/download/v1.0.0/obsidian_1.0.0_amd64.deb -O ~/Downloads/obsidian_1.0.0_amd64.deb

  ## Zoom
  [ ! -f ~/Downloads/zoom_amd64.deb ] && ${CMD} wget https://zoom.us/client/5.12.2.4816/zoom_amd64.deb -O ~/Downloads/zoom_amd64.deb

  ## Chrome
  [ ! -f ~/Downloads/google-chrome-stable_current_amd64.deb ] && ${CMD} wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O ~/Downloads/google-chrome-stable_current_amd64.deb

  ## Ticktick
  [ ! -f ~/Downloads/ticktick-1.0.40-amd64.deb ] && ${CMD} wget https://appest-public.s3.amazonaws.com/download/linux/linux_deb_x64/ticktick-1.0.40-amd64.deb -O ~/Downloads/ticktick-1.0.40-amd64.deb

  # Add apt repositories
  ## Albert
  if [[ ${DRY_RUN} == 0 ]] ; then
    [ ! -f /etc/apt/trusted.gpg.d/home_manuelschneid3r.gpg ] && wget -qO - https://download.opensuse.org/repositories/home:manuelschneid3r/xUbuntu_22.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_manuelschneid3r.gpg
    echo 'deb http://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_22.04/ /' | sudo tee /etc/apt/sources.list.d/home:manuelschneid3r.list
  else
    echo '[ ! -f /etc/apt/trusted.gpg.d/home_manuelschneid3r.gpg ] && wget -qO - https://download.opensuse.org/repositories/home:manuelschneid3r/xUbuntu_22.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_manuelschneid3r.gpg'
    echo "echo 'deb http://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_22.04/ /' | sudo tee /etc/apt/sources.list.d/home:manuelschneid3r.list"
  fi

fi 

## Yubikey software
${CMD} sudo add-apt-repository -y ppa:yubico/stable

## System76 PPA
${CMD} sudo OUT=/etc/apt/preferences.d/system76-apt-preferences sh -c 'cat << EOF >> ${OUT}
Package: *
Pin: release o=LP-PPA-system76-dev-stable
Pin-Priority: 1001

Package: *
Pin: release o=LP-PPA-system76-dev-pre-stable
Pin-Priority: 1001

EOF'

${CMD} sudo apt-add-repository -y ppa:system76-dev/stable

# Update package index files
${CMD} sudo apt update

${CMD} sudo apt install -y ${CLI_APT_PKGS} ${GUI_APT_PKGS} ${GNOME} ${KDE} ${SYSTEM76}

# Install snaps
${CMD} sudo snap install ${GUI_SNAPS} ${CLI_SNAPS}
if [[ ${CLI_ONLY} == 0 ]]; then
  ${CMD} sudo snap install ${GUI_SNAPS_CLASSIC} --classic
fi

# Install tailscale
if [[ ${DRY_RUN} == 0 ]] ; then
  wget -qO - https://tailscale.com/install.sh | sh
else
  echo "wget -qO - https://tailscale.com/install.sh | sh"
fi

# Install podman-compose
${CMD} sudo pip install podman-compose

# Setup Flathub
${CMD} flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

if [[ ${CLI_ONLY} == 0 ]]; then
  # Install Junction
  ${CMD} flatpak install -y Junction

  # Install the downloaded .deb files
  for x in ~/Downloads/*.deb
  do
      ${CMD} sudo apt install -y ${x}
  done
  rm -vf ~/Downloads/*.deb
fi

# Download zimfw
if [[ ${DRY_RUN} == 0 ]] ; then
  wget -qO - https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
else
  echo "wget -qO - https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh"
fi

# Set default shell to zsh
${CMD} sudo chsh -s /usr/bin/zsh tmoyer

# Busylight
${CMD} python3 -m pip install busylight-for-humans

${CMD} busylight udev-rules -o 99-busylights.rules
${CMD} sudo cp 99-busylights.rules /etc/udev/rules.d
${CMD} sudo udevadm control -R
${CMD} sudo rm -v 99-busylights.rules

# Dotfiles
${CMD} git clone https://github.com/tommoyer/dotfiles.git ~/.dotfiles
pushd ~/.dotfiles
${CMD} git remote set-url origin git@github.com:tommoyer/dotfiles.git
popd # ~/.dotfiles

# Useful commands to run depending on the desktop
echo "Need to run Stow to setup symlinks"
echo ""
echo "To set Juntion as the default browser: xdg-settings set default-web-browser re.sonny.Junction.desktop"
echo ""
echo "To ensure that the Chrome profile options are in the menu: update-desktop-database ~/.local/share/applications"
echo ""
echo "To have Junction find Chrome profiles: update-desktop-database ~/.local/share/flatpak/exports/share/applications"
echo ""

if [[ ${GNOME} == 1 ]]; then
  echo "To turn off Evolution alarm pop-ups: gsettings set org.gnome.evolution-data-server.calendar notify-with-tray true"
  echo ""
  echo "Center windows in Gnome: gsettings set org.gnome.mutter center-new-windows true"
  echo ""
  echo "Gnome Shell Extensions to install: Extension Sync"
  echo ""
fi

echo "Run the below snippet for setting up YubiKeys"
cat <<'EOF'
pamu2fcfg | tee u2fmappings               # Main YubiKey
pamu2fcfg -n | tee -a u2f_mappings   # Backup YubiKey
echo >> u2fmappings
sudo mv u2fmappings /etc

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

echo "To fetch public key: gpg --keyserver keyserver.ubuntu.com --search-keys tom.moyer@canonical.com"
echo ""
echo "Look at this URL for shared folders in LXD:"
echo "https://www.cyberciti.biz/faq/how-to-add-or-mount-directory-in-lxd-linux-container/"
echo ""
echo "To rebuild GPG keyring: gpg-connect-agent \"scd serialno\" \"learn --force\" /bye"
echo ""
echo "Bootstrap complete, please check output carefully"
