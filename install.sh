#!/bin/bash

die() {
    (($#)) && printf >&2 '%s\n' "$@"
    exit 1
}

sudo apt install git pipx -y

pipx install --include-deps ansible

export PATH=${PATH}:${HOME}/.local/bin

ansible-galaxy collection install community.general

echo "Please choose system type:"
echo "1 - Virtual machine/command-line only system"
echo "2 - Desktop system or VM"

read -ep 'Select type: ' number
[[ $number =~ ^[[:digit:]]+$ ]] ||
    die '*** Error: you should have entered a number'
(( ( (number=(10#$number)) <= 2 ) && number >= 0 )) ||
    die '*** Error, number not in range 1..2'

case $number in

  1)
    ansible-playbook minimal-workstation.yml -i inventory --ask-become-pass
    ;;

  2)
    ansible-playbook workstation.yml -i inventory --ask-become-pass
    ;;

  *)
    die '*** Invalid selection'
    ;;
esac

while true; do
    read -p "Do you wish to install the System76 PPA? [y/n] " yn
    case $yn in
        [Yy]* )
          ansible-playbook system76.yml -i inventory --ask-become-pass
          break
          ;;
        [Nn]* )
          echo "Skipping..."
          break
          ;;
        * )
          echo "Please answer yes or no.";;
    esac
done