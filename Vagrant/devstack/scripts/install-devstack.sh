#!/bin/bash

PASSWORD="$(echo $1 | grep -Po '^--\K.+')"
HOST_IP="10.0.0.25"

cd /tmp
git clone https://opendev.org/openstack/devstack
cd devstack

git checkout stable/train

cat << EOF > local.conf
[[local|localrc]]
ADMIN_PASSWORD=$PASSWORD
DATABASE_PASSWORD=$PASSWORD
RABBIT_PASSWORD=$PASSWORD
SERVICE_PASSWORD=$PASSWORD
HOST_IP=$HOST_IP

Q_AGENT=linuxbridge
LB_PHYSICAL_INTERFACE=enp0s3
PUBLIC_PHYSICAL_NETWORK=default
LB_INTERFACE_MAPPINGS=default:enp0s3

enable_plugin heat https://opendev.org/openstack/heat stable/train
enable_plugin heat-dashboard https://opendev.org/openstack/heat-dashboard stable/train
EOF

./stack.sh

cat << EOF > /home/vagrant/admin-openrc
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=kis2020
export OS_AUTH_URL=http://$HOST_IP/identity
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

source /home/vagrant/admin-openrc

openstack user set --project demo demo
openstack user set --project admin admin
