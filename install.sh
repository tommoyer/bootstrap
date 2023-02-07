#!/bin/bash

die() {
    (($#)) && printf >&2 '%s\n' "$@"
    exit 1
}

sudo apt install git python3-pip -y

pip install ansible

export PATH=${PATH}:${HOME}/.local/bin

ansible-galaxy collection install community.general

echo "Please choose system type:"
echo "1 - Virtual machine/command-line only system"
echo "2 - System76-based server"
echo "3 - Desktop system or VM"
echo "4 - System76-based desktop system"

read -ep 'Select type: ' number
[[ $number =~ ^[[:digit:]]+$ ]] ||
    die '*** Error: you should have entered a number'
(( ( (number=(10#$number)) <= 4 ) && number >= 0 )) ||
    die '*** Error, number not in range 1..4'
# Here I'm sure that number is a valid number in the range 0..9999

case $number in

  1)
    ansible-playbook minimal-workstation.yml -i inventory --ask-become-pass
    ;;

  2)
    ansible-playbook sys76-server.yml -i inventory --ask-become-pass
    ;;

  3)
    ansible-playbook workstation.yml -i inventory --ask-become-pass
    ;;
  4)
    ansible-playbook sys76-workstation.yml -i inventory --ask-become-pass
    ;;

  *)
    die '*** Invalid selection'
    ;;
esac
