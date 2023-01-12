#!/bin/bash

invocation="$(printf %q "$BASH_SOURCE")$((($#)) && printf ' %q' "$@")"

SYSTEM76=""
CMD=""

DRY_RUN=0

GUI_APT_PKGS="fprintd gnome-keyring gnuplot graphviz input-remapper texlive-full virt-manager virt-viewer yubikey-manager yubikey-personalization system76-wallpapers yubikey-manager syncthing syncthingtray-kde-plasma kio-gdrive network-manager-openvpn xclip yakuake ulauncher"
GUI_SNAPS="authy bitwarden icloud-for-linux mattermost-desktop slack spotify telegram-desktop zotero-snap morgen mailspring ticktick zoom-client jabref"
GUI_SNAPS_CLASSIC="code"

CLI_APT_PKGS="bat build-essential flatpak libfuse2 myrepos ncdu pcscd podman python3-pip silversearcher-ag sshuttle stow tig tmux vim virtinst zsh-autosuggestions zsh-syntax-highlighting zsh scdaemon curl libpam-yubico libpam-u2f btop openssh-server openvpn apt-file"
CLI_SNAPS="multipass lxd"
CLI_ONLY=0

usage() {
  echo "Usage: $0 [ -n ] [ -s ] [ -d ] [ -c ]" 1>&2
  echo " -n : dry-run, just show what would be executed"
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

while getopts ":nsdc" options; do
  case "${options}" in
    s)
      SYSTEM76="system76-driver"
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
${CMD} sudo add-apt-repository -n -y universe multiverse

# Install tailscale and bring up
if [[ ${DRY_RUN} == 0 ]] ; then
  wget -qO - https://tailscale.com/install.sh | sh
else
  echo "wget -qO - https://tailscale.com/install.sh | sh"
fi
${CMD} sudo tailscale up

# Download .deb packages

if [[ ${CLI_ONLY} == 0 ]]; then
  mkdir -p ~/Downloads
  ## Dropbox
  [ ! -f ~/Downloads/dropbox_2020.03.04_amd64.deb ] && ${CMD} wget https://linux.dropbox.com/packages/ubuntu/dropbox_2020.03.04_amd64.deb -O ~/Downloads/dropbox_2020.03.04_amd64.deb

  ## Minecraft
  [ ! -f ~/Downloads/Minecraft.deb ] && ${CMD} wget https://launcher.mojang.com/download/Minecraft.deb -O ~/Downloads/Minecraft.deb

  ## Moneydance
  [ ! -f ~/Downloads/moneydance_linux_amd64.deb ] && ${CMD} wget https://infinitekind.com/stabledl/current/moneydance_linux_amd64.deb -O ~/Downloads/moneydance_linux_amd64.deb

  ## Chrome
  [ ! -f ~/Downloads/google-chrome-stable_current_amd64.deb ] && ${CMD} wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O ~/Downloads/google-chrome-stable_current_amd64.deb

  ## Steam
  [ ! -f ~/Downloads/steam_latest.deb ] && ${CMD} wget https://repo.steampowered.com/steam/archive/stable/steam_latest.deb -O ~/Downloads/steam_latest.deb
  
fi 

## Yubikey software
${CMD} sudo add-apt-repository -n -y ppa:yubico/stable

## System76 PPA
if [[ ! -e /etc/apt/preferences.d/system76-apt-preferences ]]; then
  ${CMD} sudo OUT=/etc/apt/preferences.d/system76-apt-preferences sh -c 'cat << EOF >> ${OUT}
Package: *
Pin: release o=LP-PPA-system76-dev-stable
Pin-Priority: 1001

Package: *
Pin: release o=LP-PPA-system76-dev-pre-stable
Pin-Priority: 1001

EOF'
fi

${CMD} sudo apt-add-repository -n -y ppa:system76-dev/stable

${CMD} sudo add-apt-repository -n -y ppa:agornostal/ulauncher

# Update package index files
${CMD} sudo apt update

${CMD} sudo apt install -y ${CLI_APT_PKGS} ${GUI_APT_PKGS} ${SYSTEM76}

# Install snaps
${CMD} sudo snap install ${GUI_SNAPS} ${CLI_SNAPS}
if [[ ${CLI_ONLY} == 0 ]]; then
  ${CMD} sudo snap install ${GUI_SNAPS_CLASSIC} --classic
fi

# Install podman-compose
${CMD} sudo pip install podman-compose

# Setup Flathub
${CMD} flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

if [[ ${CLI_ONLY} == 0 ]]; then
  # Install Junction
  ${CMD} flatpak install -y re.sonny.Junction

  # Install PDF app
  ${CMD} flatpak install -y flathub net.codeindustry.MasterPDFEditor

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

# Dotfiles
${CMD} git clone https://github.com/tommoyer/dotfiles.git ~/.dotfiles
pushd ~/.dotfiles
${CMD} git remote set-url origin git@github.com:tommoyer/dotfiles.git
${CMD} stow apps
${CMD} stow chrome
${CMD} stow gpg
${CMD} stow latex
${CMD} stow misc
${CMD} stow pics
${CMD} stow ssh
${CMD} stow tmux
${CMD} stow vcs
${CMD} rm ~/.zshrc ~/.zimrc
${CMD} stow zsh
popd # ~/.dotfiles

mkdir -p ~/Repos/home-server/

${CMD} chmod go-rwx ~/.gnupg ~/.ssh

${CMD} xdg-settings set default-web-browser re.sonny.Junction.desktop

${CMD} update-desktop-database ~/.local/share/applications
${CMD} update-desktop-database ~/.local/share/flatpak/exports/share/applications

${CMD} echo "emulate sh -c 'source /etc/profile'" >> /etc/zsh/zprofile

${CMD} gpg --keyserver keyserver.ubuntu.com --search-keys tom.moyer@canonical.com

${CMD} sudo snap connect multipass:libvirt
${CMD} multipass set local.driver=libvirt

${CMD} apt-file update

echo "Run the below snippet for setting up YubiKeys"
cat <<'EOF'
pamu2fcfg | tee u2f_mappings               # Main YubiKey
pamu2fcfg -n | tee -a u2f_mappings   # Backup YubiKey
echo >> u2f_mappings
sudo mv u2f_mappings /etc

sudo -i

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

echo "To rebuild GPG keyring: gpg-connect-agent \"scd serialno\" \"learn --force\" /bye"
echo ""
echo "Check the following for a Tailscale tray icon"
echo "https://github.com/mattn/tailscale-systray"
echo ""
echo "Bootstrap complete, please check output carefully"
echo "Check ~/.bootstrap_status for details on the execution"

${CMD} echo "Command: ${invocation}" > ~/.bootstrap_status
${CMD} echo -n "Git commit: " >> ~/.bootstrap_status
${CMD} wget http://100.88.5.29:8888/latest -O- >> ~/.bootstrap_status
${CMD} echo >> ~/.bootstrap_status
${CMD} echo "Date: $(date)" >> ~/.bootstrap_status
