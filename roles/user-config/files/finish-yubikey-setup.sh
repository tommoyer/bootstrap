#!/bin/bash

read -p "Insert primary Yubikey and then press any key" -n1 -s
echo ""
pamu2fcfg | tee u2f_mappings               # Main YubiKey

echo ""
read -p "Remove primary Yubikey, insert backup Yubikey #1, and then press any key" -n1 -s
echo ""
pamu2fcfg -n | tee -a u2f_mappings   # Backup YubiKey

echo ""
read -p "Remove backup Yubikey #1, insert backup Yubikey #2, and then press any key" -n1 -s
echo ""
pamu2fcfg -n | tee -a u2f_mappings   # Backup YubiKey

echo >> u2f_mappings

echo ""
sudo mv u2f_mappings /etc
echo ""
read -p "Remove backup Yubikey #2, insert primary Yubikey, and then press any key" -n1 -s
echo ""

gpg-connect-agent "scd serialno" "learn --force" /bye

