#!/bin/bash

read -p "Insert primary Yubikey and then press any key" -n1 -s
pamu2fcfg | tee u2f_mappings               # Main YubiKey

read -p "Remove primary Yubikey insert backup Yubikey and then press any key" -n1 -s
pamu2fcfg -n | tee -a u2f_mappings   # Backup YubiKey

echo >> u2f_mappings

sudo mv u2f_mappings /etc

read -p "Remove backup Yubikey insert primary Yubikey and then press any key" -n1 -s

gpg-connect-agent "scd serialno" "learn --force" /bye