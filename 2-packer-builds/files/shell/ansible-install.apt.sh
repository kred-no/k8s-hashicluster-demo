#!/usr/bin/env sh
set -x

echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
apt-get update
apt-get -qqy install -o DPkg::Lock::Timeout=30 --no-install-recommends apt-utils vim.tiny > /dev/null 2>&1
apt-get -qqy install -o DPkg::Lock::Timeout=30 --no-install-recommends python3-simplejson python3-pip
apt-get -qqy install -o DPkg::Lock::Timeout=30 --no-install-recommends openssh-client ansible
apt-get autoclean

ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix
