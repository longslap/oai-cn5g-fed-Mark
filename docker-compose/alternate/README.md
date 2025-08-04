# OAI Core Docker Management Script

## Overview

This Bash script manages docker containers and multiple independent networks for the OpenAirInterface (OAI) 5G Core and IMS environment. The reason of having this script rather than docker compose because today `docker-compose` does to allow changing the name of network interfaces which are inside a docker container. OAI core network configuration file accepts only interface names to bind their services rather than an ip-address. Example: UPF have multiple interfaces sbi, n3, n4, n6 and docker compose assign networks interface name randomly eth0, eth1. It can not be controlled. 

[Refer to the issue](https://github.com/moby/moby/issues/49935) 

It supports creating custom Docker networks, starting, stopping, removing containers, and viewing logs or status for core network functions and related services.

---

## Supported Containers

- `mysql` (MySQL database)
- `asterisk-ims` (IMS core)
- `oai-udr` (Unified Data Repository)
- `oai-udm` (Unified Data Management)
- `oai-ausf` (Authentication Server Function)
- `oai-nrf` (Network Repository Function)
- `oai-amf` (Access and Mobility Management Function)
- `oai-smf` (Session Management Function)
- `oai-upf` (User Plane Function)
- `oai-ext-dn` (External Data Network / Traffic Generator)

---

## Docker Networks Created

| Network Name | Subnet            | Bridge Name    |
| ------------ | ----------------- | -------------- |
| sbi_network  | 192.168.70.128/26 | oai-core-sbi   |
| n2_network   | 192.168.76.0/28   | oai-core-n2    |
| n3_network   | 192.168.77.0/28   | oai-core-n3    |
| n4_network   | 192.168.78.0/28   | oai-core-n4    |
| n6_network   | 192.168.79.0/28   | oai-core-n6    |

The route towards `n2` and `n3` subnets have to exist in the `gNB` server. You can add the route like below in `gNB` server

```bash
#n2 route
sudo ip route add 192.168.76.0/28 dev via <gnB-interface-which-can-communicate-with-core-network-server>
#n3 route
sudo ip route add 192.168.77.0/28 dev via <gnB-interface-which-can-communicate-with-core-network-server>
```

---

## Usage

Make the script executable:

```bash
git clone && cd 
chmod +x oai-core.sh
./oai-core.sh 
```

## OAI Core network configuration

The configuration of OAI core network is taken from `./conf/basic.yaml`. IMS configuration is in `./conf/users.conf` and `./conf/sip.conf`. 

## User data

The user data should be configured in `./database/oai_db.sql` and `./conf/users.conf` if your UE will requires an IMS.

