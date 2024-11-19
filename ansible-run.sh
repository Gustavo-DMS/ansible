#!/usr/bin/env bash

## Install ansible
sudo pacman -Syu
sudo pacman -S --needed git curl ansible

## install ansible-galaxy roles
ansible-galaxy install -r requirements.yml

## Run ansible playbook
ansible-playbook -i inventory main.yml -K --ask-vault-pass
