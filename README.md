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

`ansible-playbook <playbook>.yml -i inventory
