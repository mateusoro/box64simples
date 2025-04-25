#!/bin/bash
clear
echo "Updating packages and installing dependencies to run installer"
echo ""
apt-get update &>/dev/null
apt-get -y --with-new-pkgs -o Dpkg::Options::="--force-confdef" upgrade &>/dev/null
apt install python --no-install-recommends -y &>/dev/null
python3 instalador.py