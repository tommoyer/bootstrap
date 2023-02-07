# bootstrap
Ansible script to install necessary tools

# Pre-Requisits
Prior to running this make sure that Ansible is installed

Install Ansible and Git

`sudo apt install ansible git -y`

Install Ansible Snaps Module

`ansible-galaxy collection install community.general`

## Checkout this Project

`git clone https://github.com/tommoyer/bootstrap.git ~/Repos/tommoyer/bootstrap`

# Running the Script

## For VMs/CLI-only systems

`ansible-playbook minimal-workstation.yml -i inventory --ask-become-pass`

## For System76 server systems

`ansible-playbook sys76-server.yml -i inventory --ask-become-pass`

## For desktop workstations

`ansible-playbook workstation.yml -i inventory --ask-become-pass`

## For system76 workstations

`ansible-playbook sys76-workstation.yml -i inventory --ask-become-pass`
