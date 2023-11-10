#!/bin/bash

die() {
    (($#)) && printf >&2 '%s\n' "$@"
    exit 1
}

case $number in

  1)
    ansible-playbook minimal-workstation.yml -i inventory --ask-become-pass
    ;;

  2)
    ansible-playbook workstation.yml -i inventory --ask-become-pass -e @gh-token.enc --ask-vault-pass
    ;;

  *)
    die '*** Invalid selection'
    ;;
esac
