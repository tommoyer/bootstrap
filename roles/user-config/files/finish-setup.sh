#!/bin/bash

export GH_TOKEN={{ gh_token }}

echo ""
read -p "Insert backup Yubikey #1, and then press any key" -n1 -s
echo ""
pamu2fcfg -n | tee -a u2f_mappings   # Backup YubiKey

echo ""
read -p "Remove backup Yubikey #1, insert backup Yubikey #2, and then press any key" -n1 -s
echo ""
pamu2fcfg -n | tee -a u2f_mappings   # Backup YubiKey

echo  ""
read -p "Rem0ove backup Yubikey #2, insert primary Yubikey, and then press any key" -n1 -s
echo ""
pamu2fcfg | tee u2f_mappings               # Main YubiKey

echo ""
echo >> u2f_mappings
sudo mv u2f_mappings /etc
echo ""
gpg-connect-agent "scd serialno" "learn --force" /bye

echo "Initializing LXD"
cat lxd-init.yaml | lxd init --preseed
echo "Adding aliases"
lxc alias add list-all 'list --all-projects'
echo "Need to add any remotes"

lxc profile edit default < lxd-default-profile.yaml

echo ${GH_TOKEN} > gh-token
gh auth login --with-token < gh-token
echo "export GH_TOKEN=${GH_TOKEN}" > ~/.local_profile
rm gh-token

mkdir -p ~/Applications
gh release download -R obsidianmd/obsidian-releases -p "Obsidian-$(gh release list -L 1 -R obsidianmd/obsidian-releases | awk '{print $1}').AppImage" -D ~/Applications
gh release download -R probonopd/go-appimage -p 'appimaged-*x86_64.AppImage' continuous -D ~/Applications
gh release download -R MuhammedKalkan/OpenLens -p "OpenLens-$(gh release list -R MuhammedKalkan/OpenLens -L 1 | awk '{print $1}' | sed 's/^v//').x86_64.AppImage" -D ~/Applications
chmod +x ~/Applications/*.AppImage
/home/tmoyer/Applications/appimaged*

git clone --recurse-submodules https://github.com/eendroroy/alien.git $HOME/.alien

dconf load /org/gnome/terminal/ < gnome_terminal_settings_backup.dconf

echo "Cleaning up..."
rm lxd-default-profile.yaml
rm gnome_terminal_settings_backup.dconf
rm lxd-init.yaml
