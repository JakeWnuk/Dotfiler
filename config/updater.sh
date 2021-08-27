#!/bin/bash
sudo apt update -y && sudo apt full-upgrade -y
sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y
sudo apt-get autoclean -y && sudo apt-get clean -y
sudo apt-get autoremove -y
pipx upgrade-all
go get -u all