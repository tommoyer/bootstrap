#!/bin/bash

die() {
    (($#)) && printf >&2 '%s\n' "$@"
    exit 1
}

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

popd &> /dev/null
