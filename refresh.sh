#!/bin/bash

die() {
    (($#)) && printf >&2 '%s\n' "$@"
    exit 1
}

echo "Please choose system type:"
echo "1 - Command-line only system"
echo "2 - Desktop system"

read -ep 'Select type: ' number
[[ $number =~ ^[[:digit:]]+$ ]] ||
    die '*** Error: you should have entered a number'
(( ( (number=(10#$number)) <= 2 ) && number >= 0 )) ||
    die '*** Error, number not in range 1..2'

case $number in

  1)
    ansible-playbook minimal-workstation.yml -i inventory --ask-become-pass -e @gh-token.enc --ask-vault-pass
    ;;

  2)
    ansible-playbook workstation.yml -i inventory --ask-become-pass -e @gh-token.enc --ask-vault-pass
    ;;

  *)
    die '*** Invalid selection'
    ;;
esac
