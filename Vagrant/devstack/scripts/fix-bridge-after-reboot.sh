#!/bin/bash

GATEWAY_IP="${1}"

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
