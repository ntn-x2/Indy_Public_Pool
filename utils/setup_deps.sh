#!/bin/bash

path_folder=`dirname "$0"`

apt update
apt install -y apt-transport-https python3-pip=8.*
apt update
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 68DB5E88
bash -c 'echo "deb https://repo.sovrin.org/deb xenial stable" >> /etc/apt/sources.list'
apt update || true
apt install -y indy-node=1.6.83
pip3 install -r .deps.txt