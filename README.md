# bootstrap
Ansible script to install necessary tools

# Pre-Requisits
Prior to running this make sure that Ansible is installed

Install Ansible and Git

`$ sudo apt install ansible git -y`

Install Ansible Snaps Module

`$ ansible-galaxy collection install community.general`

## Checkout this Project

`$ git clone https://github.com/tommoyer/bootstrap.git`

# Running the Script

## For VMs/CLI-only systems

`ansible-playbook minimal-workstation.yml -i inventory --ask-become-pass`

## For desktop workstations

`ansible-playbook workstation.yml -i inventory --ask-become-pass`
