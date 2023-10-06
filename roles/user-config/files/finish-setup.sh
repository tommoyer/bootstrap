#!/bin/bash

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

echo "Setting up LXD-systemd DNS integration"
sudo mv lxd-dns-lxdbr0.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now lxd-dns-lxdbr0
