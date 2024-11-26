# Run OAI gNB and 5GC on same machine

Instead of configuring oai-upf to use demo-n3, demo-n6 in the container. We create veth pair in the docker-compose (similar to other containers). We also create veth pair interfaces and the assign one to them to the gNB. See:
- `docker-compose/docker-compose-nrf-ebpf-veth.yaml`
- `docker-compose/conf/basic_nrf_config_ebpf_veth.yaml`
- `scripts/setup-veth.sh`

## Set up

It should build nr-softmodem (gNB) and then nr-uesoftmodem

```bash
# Clone the RAN repository
git clone https://gitlab.eurecom.fr/oai/openairinterface5g.git

cd openairinterface5g
git checkout develop

# Installing dependencies
export BUILD_UHD_FROM_SOURCE=True
export UHD_VERSION=4.6.0.0
cd openairinterface5g/cmake_targets/
./build_oai -I --install-optional-packages -w USRP

# Installing asn1c from source
cd openairinterface5g
sudo ls                               # open sudo session, required by install_asn1c_from_source
. oaienv                              # read of default variables
. cmake_targets/tools/build_helper    # read in function
install_asn1c_from_source             # install under `/opt/asn1c`

# Building PHY Simulators
cd openairinterface5g/cmake_targets/
./build_oai --phy_simulators

# Building UEs and gNodeB Executables
cd openairinterface5g/cmake_targets/
./build_oai -w USRP --nrUE --gNB
```

## Start 

```bash
# Start 5GC
cd docker-compose
docker compose -f docker-compose-basic-nrf-ebpf-veth.yaml up -d

# Create veth interfaces for gNB (ifname: ran0, IP: 192.168.71.130)
sudo sh scripts/setup-veth.sh

# Start gnb (in folder cmake_targets/ran_build/build)

# Start gNB
sudo ./nr-softmodem -O ../../../../docker-compose/ran-conf/gnb-veth.conf --sa -E --rfsim

# Start nrUE
sudo ./nr-uesoftmodem -O ../../../../docker-compose/ran-conf/nr-ue.conf -E --sa --rfsim -r 106 --numerology 1 -C 3619200000 --log_config.global_log_options level,nocolor,time
```

**Enabling XDP support on (oai-upf) peer veth device**

Enable GRO on both peers of the veth device, i.e., inside and outside container.

```bash
ip a | grep demo-n

ethtool -K ${vethname} gro on
```

Start ping on the UE

```bash
ping -I 12.1.1.130 8.8.8.8
```