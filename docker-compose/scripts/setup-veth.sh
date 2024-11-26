#!/bin/bash

# Create veth pair interfaces
ip link add ran0 type veth peer name vethran0
ip link set vethran0 master demo-n3
ip address add 192.168.71.130/26 dev ran0
ip link set ran0 up
ip link set vethran0 up

# Ping the ran0, bridge ip, and upf ip
ping -c 2 192.168.71.130

ping -c 2 -I ran0 192.168.71.129

ping -c 2 -I ran0 192.168.71.134

# Show arp tables
arp -n