#!/bin/bash

ip link add bridge type bridge
ip link set bridge up

ip link add tap1 type veth peer name bridge-tap1

ip link set bridge-tap1 master bridge
ip link set bridge-tap1 up

ip address add 10.0.0.1/24 dev bridge

echo 1 > /proc/sys/net/ipv4/ip_forward

iptables -t nat -I POSTROUTING 1 -o enp0s3 -s 10.0.0.0/8 -j MASQUERADE

ip netns add router
ip netns add client

##############
### router ###
##############
ip link set tap1 netns router

ip netns exec router ip address add 10.0.0.254/24 dev tap1
ip netns exec router ip link set tap1 up

ip netns exec router ip route add default via 10.0.0.1

ip netns exec router ip link add eth0 type veth peer name eth0 netns client

ip netns exec router ip address add 192.168.0.1/24 dev eth0
ip netns exec router ip link set eth0 up

##############
### client ###
##############
ip netns exec client ip address add 192.168.0.25/24 dev eth0
