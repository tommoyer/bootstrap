#!/bin/bash

export GH_TOKEN={{ gh_token }}

setup_yubikey() {
	if [[ ! -e /etc/u2f_mappings ]]
	then
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
	else
		echo "Yubikeys already setup"
	fi
}

init_lxd() {
	if ! id | grep lxd &> /dev/null
	then
		echo "You need to add yourself to the LXD group before doing this"
		echo "Once you logout and back in, try running this again"
		sudo adduser tmoyer lxd
		return
	else
		if [[ -e lxd-init.yaml ]]
		then
			echo "Initializing LXD"
			cat lxd-init.yaml | lxd init --preseed
			echo "Adding aliases"
			lxc alias add list-all 'list --all-projects'
			echo "Need to add any remotes"
			rm -f lxd-init.yaml
		else
			echo "LXD already initialized"
		fi
	fi
}

setup_gh_token() {
	if ! grep GH_TOKEN ~/.local_profile &>/dev/null
	then
		echo ${GH_TOKEN} > gh-token
		gh auth login --with-token < gh-token
		echo "export GH_TOKEN=${GH_TOKEN}" > ~/.local_profile
		rm -f gh-token
	else
		echo "Github token already configured"
	fi
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
	if [[ ! -e ~/.alien ]]
	then
		git clone --recurse-submodules https://github.com/eendroroy/alien.git $HOME/.alien	
	else
		echo "Shell setup completed"
	fi
}

finish_gnome_terminal_setup() {
	if [[ -e gnome_terminal_settings_backup.dconf ]]
	then
		dconf load /org/gnome/terminal/ < gnome_terminal_settings_backup.dconf	
		rm -f gnome_terminal_settings_backup.dconf
	else
		echo "Gnome settings already updated"
	fi
}

setup_default_lxd_profile() {
	if ! id | grep lxd &> /dev/null
	then
		echo "You need to add yourself to the LXD group before doing this"
		echo "Once you logout and back in, try running this again"
	else
		if [[ -e lxd-default-profile.yaml ]]
		then
			lxc profile edit default < lxd-default-profile.yaml
			rm -f lxd-default-profile.yaml	
		else
			echo "LXD default profile already installed"
		fi
	fi
}

setup_lxd_dns() {
	if ! id | grep lxd &> /dev/null
	then
		echo "You need to add yourself to the LXD group before doing this"
		echo "Once you logout and back in, try running this again"
	else
		if [[ -e /etc/systemd/system/lxd-dns-lxdbr0.service ]]
		then
			sudo systemctl daemon-reload
			sudo systemctl enable --now lxd-dns-lxdbr0	
		else
			echo "LXD DNS not configured"
		fi
	fi
}

import_gpg_key() {
	if ! gpg --list-keys | grep "0x6B0A28C4075F6051"
	then
		gpg --batch --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0x6B0A28C4075F6051
	else
		echo "GPG public key already imported"
	fi
}

choices=$(dialog --stdout --backtitle 'Finish System Setup' --checklist 'Operations' 30 80 10 \
	setup_yubikey 'Setup Yubikey' 'off' \
	init_lxd 'Initialize LXD' 'off' \
	setup_gh_token 'Setup Github Token' 'off' \
	download_applications 'Download Applications' 'off' \
	finish_shell_setup 'Finish ZSH Setup' 'off' \
	finish_gnome_terminal_setup 'Finish Gnome Terminal Setup' 'off' \
	setup_default_lxd_profile 'Setup Default LXD Profile' 'off' \
	setup_lxd_dns 'Configure LXD DNS' 'off' \
	minimal_workstation 'Command-line only stuff' 'off' \
	all 'Do everything' 'off')

if [[ $choices == 'minimal_workstation' ]]
then
	setup_gh_token
	finish_shell_setup
	import_gpg_key
	if command -v lxd &> /dev/null
	then
		init_lxd
		setup_default_lxd_profile
		setup_lxd_dns
	fi
elif [[ $choices == 'all' ]]
then
	setup_yubikey
	init_lxd
	setup_gh_token
	download_applications
	finish_shell_setup
	finish_gnome_terminal_setup
	setup_default_lxd_profile
	setup_lxd_dns
else
	for choice in $choices
	do
		$choice
	done
fi
