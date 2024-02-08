#!/bin/bash

export GH_TOKEN={{ gh_token }}

setup_yubikey() {
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
}

init_lxd() {
	echo "Initializing LXD"
	cat lxd-init.yaml | lxd init --preseed
	echo "Adding aliases"
	lxc alias add list-all 'list --all-projects'
	echo "Need to add any remotes"
	rm -f lxd-init.yaml
}

setup_gh_token() {
	echo ${GH_TOKEN} > gh-token
	gh auth login --with-token < gh-token
	echo "export GH_TOKEN=${GH_TOKEN}" > ~/.local_profile
	rm -f gh-token
}

download_applications() {
	mkdir -p ~/Applications
	gh release download -R obsidianmd/obsidian-releases -p "Obsidian-$(gh release list -L 1 -R obsidianmd/obsidian-releases | awk '{print $1}').AppImage" -D ~/Applications
	gh release download -R probonopd/go-appimage -p 'appimaged-*x86_64.AppImage' continuous -D ~/Applications
	gh release download -R MuhammedKalkan/OpenLens -p "OpenLens-$(gh release list -R MuhammedKalkan/OpenLens -L 1 | awk '{print $1}' | sed 's/^v//').x86_64.AppImage" -D ~/Applications
	gh release download -R AppImageCommunity/AppImageUpdate -p 'AppImageUpdate-x86_64.AppImage' continuous -D ~/Applications
	chmod +x ~/Applications/*.AppImage
	/home/tmoyer/Applications/appimaged*	
}

finish_shell_setup() {
	git clone --recurse-submodules https://github.com/eendroroy/alien.git $HOME/.alien	
}

finish_gnome_terminal_setup() {
	dconf load /org/gnome/terminal/ < gnome_terminal_settings_backup.dconf	
	rm -f gnome_terminal_settings_backup.dconf
}

setup_default_lxd_profile() {
	lxc profile edit default < lxd-default-profile.yaml
	rm -f lxd-default-profile.yaml	
}

choices=$(dialog --stdout --backtitle 'Finish System Setup' --checklist 'Operations' 30 80 10 \
	setup_yubikey 'Setup Yubikey' 'off' \
	init_lxd 'Initialize LXD' 'off' \
	setup_gh_token 'Setup Github Token' 'off' \
	download_applications 'Download Applications' 'off' \
	finish_shell_setup 'Finish ZSH Setup' 'off' \
	finish_gnome_terminal_setup 'Finish Gnome Terminal Setup' 'off' \
	setup_default_lxd_profile 'Setup Default LXD Profile' 'off')

for choice in $choices
do
	$choice
done
