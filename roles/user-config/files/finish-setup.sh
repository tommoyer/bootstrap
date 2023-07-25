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

echo >> u2f_mappings
sudo mv u2f_mappings /etc
echo ""
gpg-connect-agent "scd serialno" "learn --force" /bye

echo ""
echo "Run fish and then execute the following commands:"
echo "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
echo "fisher install jethrokuan/z"

mkdir -p ~/.config/fish/functions/
echo fzf_key_bindings >> ~/.config/fish/functions/fish_user_key_bindings.fish
