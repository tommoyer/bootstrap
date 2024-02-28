#!/bin/bash

die() {
    (($#)) && printf >&2 '%s\n' "$@"
    exit 1
}

if [[ $# -gt 1 ]]
then
  printf >&2 'You can only specify one argument\n'
  die 'Usage: $0 [-c|-d]'
fi

OPTSTRING=":cdg"

CHOICE=0

while getopts ${OPTSTRING} opt; do
  case ${opt} in
    c)
      echo "Minimal workstation chosen"
      CHOICE=1
      ;;
    d)
      echo "Desktop system chosen"
      CHOICE=2
      ;;
    g)
      echo "Gnome desktop system chosen"
      CHOICE=2
      ;;
    ?)
      die "Invalid option: -${OPTARG}."
      ;;
  esac
done

export PATH=${PATH}:${HOME}/.local/bin

pkgs=""

if ! dpkg-query -l pipx &> /dev/null
then
  pkgs+="pipx"
  echo "Selecting pipx to be installed"
else
  echo "pipx already installed"
fi

if ! dpkg-query -l git &> /dev/null
then
  pkgs+=" git"
  echo "Selecting git to be installed"
else
  echo "git already installed"
fi

if [[ $pkgs != "" ]]
then
  sudo apt install $pkgs -y
else
  echo "All packaages installed"
fi

if ! pipx list | grep "package ansible" &> /dev/null
then
  pipx install --include-deps ansible
else
  echo "Ansible already installed"
fi

if ! ansible-galaxy collection list | grep community.general &> /dev/null
then
  ansible-galaxy collection install community.general
else
  echo "Skipping installation of community.general"
fi

if [[ ! -d ~/Repos/tommoyer/bootstrap ]]
then
  git clone https://github.com/tommoyer/bootstrap.git ~/Repos/tommoyer/bootstrap
else
  echo "Bootstrap repo already installed"
fi

pushd ~/Repos/tommoyer/bootstrap &> /dev/null

if [[ $CHOICE == 0 ]]
then
  echo "Please choose system type:"
  echo "1 - Command-line only system"
  echo "2 - Desktop system"
  echo "3 - Gnome specific desktop system"

  read -ep 'Select type: ' CHOICE
  [[ $CHOICE =~ ^[[:digit:]]+$ ]] ||
      die '*** Error: you should have entered a number'
  (( ( (CHOICE=(10#$CHOICE)) <= 3 ) && CHOICE >= 0 )) ||
      die '*** Error, number not in range 1..3'
fi

EXTRA_VARS=""

case $CHOICE in

  1)
    EXTRA_VARS='{"workstation":"false","gnome":"false"}'
    ;;

  2)
    EXTRA_VARS='{"workstation":"true","gnome":"false"}'
    ;;

  3)
    EXTRA_VARS='{"workstation":"true","gnome":"true"}'
    ;;

  *)
    die '*** Invalid selection'
    ;;
esac

ansible-playbook workstation.yml -i inventory --ask-become-pass -e @gh-token.enc --ask-vault-pass --check

popd &> /dev/null
