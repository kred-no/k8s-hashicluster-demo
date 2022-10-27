#!/usr/bin/env sh
set -ex

HASHICORP_BASE=https://releases.hashicorp.com
ARCH=amd64

NOMAD_VERSION=1.4.2
CONSUL_VERSION=1.14.0-beta1
CONSUL_TEMPLATE_VERSION=0.29.5
CNI_VERSION=1.1.1

writelog() {
  printf "[%s] %s \n" "$(date)" "${1}"|tee -a /opt/cloud-provisioning.log
}

hci() {
  writelog "Installing ${1} v${2}"
  useradd -c "Application User (${1})" --no-create-home --user-group --system ${1}
  curl --retry 5 --retry-delay 1 -fsSL ${HASHICORP_BASE}/${1}/${2}/${1}_${2}_linux_${ARCH}.zip -o /tmp/${1}.zip
  install -d -m 0755 -o ${1} -g ${1} /etc/${1}.d /var/lib/${1}
  unzip -d /usr/local/bin /tmp/${1}.zip
  rm -f /tmp/${1}.zip
}

writelog "Installing required packages"
apt-get -qqy install -o DPkg::Lock::Timeout=120 curl unzip

# Install HashiCorp Applications
hci nomad ${NOMAD_VERSION}
hci consul ${CONSUL_VERSION}
hci consul-template ${CONSUL_TEMPLATE_VERSION}

# CNI-plugins
writelog "Adding CNI-plugins v${CNI_VERSION}"
curl --retry 5 --retry-delay 1 -fsSL https://github.com/containernetworking/plugins/releases/download/v${CNI_VERSION}/cni-plugins-linux-${ARCH}-v${CNI_VERSION}.tgz -o /tmp/cni-plugins.tgz
install -d -m 0755 -o root -g root /opt/cni/bin
tar -C /opt/cni/bin -xzf /tmp/cni-plugins.tgz
rm -f /tmp/cni-plugins.tgz

writelog "Generating CNI-plugin bridge-config"
modprobe br_netfilter && echo "br_netfilter" | tee /etc/modules-load.d/br_netfilter.conf
touch /etc/sysctl.d/cni-plugins.conf && chmod 0644 /etc/sysctl.d/cni-plugins.conf
echo "net.bridge.bridge-nf-call-arptables = 1" | tee -a /etc/sysctl.d/cni-plugins.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" | tee -a /etc/sysctl.d/cni-plugins.conf
echo "net.bridge.bridge-nf-call-iptables = 1" | tee -a /etc/sysctl.d/cni-plugins.conf
sysctl -p /etc/sysctl.d/cni-plugins.conf

# DNS
writelog "Configuring  iptables for Consul DNS"
iptables -t nat -A PREROUTING -p udp -m udp --dport 53 -j REDIRECT --to-ports 8600
iptables -t nat -A PREROUTING -p tcp -m tcp --dport 53 -j REDIRECT --to-ports 8600
iptables -t nat -A OUTPUT -d localhost -p udp -m udp --dport 53 -j REDIRECT --to-ports 8600
iptables -t nat -A OUTPUT -d localhost -p tcp -m tcp --dport 53 -j REDIRECT --to-ports 8600

writelog "Persisting iptables configuration"
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt-get -qqy install -o DPkg::Lock::Timeout=120 iptables-persistent

# Azure CLI
writelog "Installing Azure CLI"
curl -fssL https://aka.ms/InstallAzureCLIDeb|bash

# Docker
writelog "Installing Docker"
curl -fsSL get.docker.com|sh
#usermod -aG docker ${APPUSER}

# Finalize
writelog "Manage services"
systemctl daemon-reload
systemctl enable docker.service
systemctl disable consul.service
systemctl disable nomad.service

writelog "Starting services"
systemctl start docker.service
systemctl stop consul.service
systemctl stop nomad.service

writelog "All done."
exit 0
