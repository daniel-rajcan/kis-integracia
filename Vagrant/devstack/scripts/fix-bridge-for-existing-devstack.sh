#!/bin/bash

GATEWAY_IP="172.24.4.1/24"

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

### Run it
### vagrant halt
### vagrant --kis2020 up

### vagrant ssh
### source admin-openrc

### brctl show
#bridge name	bridge id		STP enabled	interfaces
#br-ex		8000.000000000000	no
#virbr0		8000.52540067123c	yes		virbr0-nic

### ip a
#br-ex: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
#    link/ether 66:f5:1c:ac:53:82 brd ff:ff:ff:ff:ff:ff
#    inet 172.24.4.1/24 brd 172.25.0.255 scope global br-ex
#       valid_lft forever preferred_lft forever
#    inet6 fe80::a05a:36ff:fe09:c09a/64 scope link
#       valid_lft forever preferred_lft forever

### iptables -t nat -nvL
#Chain POSTROUTING (policy ACCEPT 188 packets, 12334 bytes)
# pkts bytes target     prot opt in     out     source               destination
#  195 13037 LIBVIRT_PRT  all  --  *      *       0.0.0.0/0            0.0.0.0/0
#    7   703 MASQUERADE  all  --  *      enp0s3  0.0.0.0/0            0.0.0.0/0

### openstack network agent list
#+--------------------------------------+--------------------+----------+-------------------+-------+-------+---------------------------+
#| ID                                   | Agent Type         | Host     | Availability Zone | Alive | State | Binary                    |
#+--------------------------------------+--------------------+----------+-------------------+-------+-------+---------------------------+
#| 25d11635-6dc8-4c93-be52-3aea981cb0c1 | Metadata agent     | devstack | None              | :-)   | UP    | neutron-metadata-agent    |
#| 2af35ad6-af87-4a02-8f30-28bd8a0c6714 | L3 agent           | devstack | nova              | :-)   | UP    | neutron-l3-agent          |
#| 5b3c5ee0-dfbc-40b2-9a8c-175a93271d4e | Linux bridge agent | devstack | None              | :-)   | UP    | neutron-linuxbridge-agent |
#| 6ae82e59-65be-4a4b-af76-b75d8c1278c0 | DHCP agent         | devstack | nova              | :-)   | UP    | neutron-dhcp-agent        |
#+--------------------------------------+--------------------+----------+-------------------+-------+-------+---------------------------+

### openstack compute service list
#+----+----------------+----------+----------+---------+-------+----------------------------+
#| ID | Binary         | Host     | Zone     | Status  | State | Updated At                 |
#+----+----------------+----------+----------+---------+-------+----------------------------+
#|  2 | nova-scheduler | devstack | internal | enabled | up    | 2021-03-24T09:17:15.000000 |
#|  5 | nova-conductor | devstack | internal | enabled | up    | 2021-03-24T09:17:14.000000 |
#|  1 | nova-conductor | devstack | internal | enabled | up    | 2021-03-24T09:17:13.000000 |
#|  2 | nova-compute   | devstack | nova     | enabled | up    | 2021-03-24T09:17:11.000000 |
#+----+----------------+----------+----------+---------+-------+----------------------------+
