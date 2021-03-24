#!/bin/bash

RELEASE="victoria"

PASSWORD="$(echo $1 | grep -Po '^--\K.+')"
HOST_IP="10.0.0.25"
FLOATING_RANGE="172.25.0.0/24"
GATEWAY_IP=$(sed -E "s/[[:digit:]]+(\/24)/1\1/" <<< $FLOATING_RANGE)

cd /home/vagrant
git clone https://opendev.org/openstack/devstack
cd devstack

git checkout stable/${RELEASE}

cat << EOF > local.conf
[[local|localrc]]
HOST_IP=$HOST_IP
SERVICE_HOST=$HOST_IP
ADMIN_PASSWORD=$PASSWORD
DATABASE_PASSWORD=$PASSWORD
RABBIT_PASSWORD=$PASSWORD
SERVICE_PASSWORD=$PASSWORD
FLOATING_RANGE=$FLOATING_RANGE

PIP_UPGRADE=True

Q_AGENT=linuxbridge
LB_PHYSICAL_INTERFACE=enp0s3
PUBLIC_PHYSICAL_NETWORK=default
LB_INTERFACE_MAPPINGS=default:enp0s3

enable_plugin heat https://opendev.org/openstack/heat stable/${RELEASE}
enable_plugin heat-dashboard https://opendev.org/openstack/heat-dashboard stable/${RELEASE}
EOF

./stack.sh

cat << EOF > /home/vagrant/admin-openrc
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$PASSWORD
export OS_AUTH_URL=http://$HOST_IP/identity
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

source /home/vagrant/admin-openrc

openstack user set --project demo demo
openstack user set --project admin admin


### Required to be able to restart vagrant instance without disruption of OpenStack functionality
cat << EOF > /usr/local/bin/fix-bridge.sh
brctl addbr br-ex
ifconfig br-ex up
ifconfig br-ex ${GATEWAY_IP}

iptables -t nat -I POSTROUTING 1 -o enp0s3 -j MASQUERADE

systemctl restart devstack@*
EOF

chmod 744 /usr/local/bin/fix-bridge.sh

cat << EOF > /etc/systemd/system/vagrant@fix-bridge.service
[Unit]
After=sshd.service

[Service]
ExecStart=/bin/bash /usr/local/bin/fix-bridge.sh

[Install]
WantedBy=default.target
EOF

chmod 664 /etc/systemd/system/vagrant@fix-bridge.service

systemctl daemon-reload
systemctl enable vagrant@fix-bridge
