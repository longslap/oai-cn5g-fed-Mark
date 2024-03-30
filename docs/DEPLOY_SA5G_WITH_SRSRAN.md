<table style="border-collapse: collapse; border: none;">
  <tr style="border-collapse: collapse; border: none;">
    <td style="border-collapse: collapse; border: none;">
      <a href="http://www.openairinterface.org/">
         <img src="./images/oai_final_logo.png" alt="" border=3 height=50 width=150>
         </img>
      </a>
    </td>
    <td style="border-collapse: collapse; border: none; vertical-align: center;">
      <b><font size = "5">OpenAirInterface 5G Core Network Deployment and Testing with srsRAN</font></b>
    </td>
  </tr>
</table>


![SA dsTest Demo](./images/5gcn_vpp_upf_srsran.png)

**Reading time: ~ 30mins**

**Tutorial replication time: ~ 1h30mins**

Note: In case readers are interested in deploying debuggers/developers core network environment with more logs please follow [this tutorial](./DEBUG_5G_CORE.md)

**TABLE OF CONTENTS**

[[_TOC_]]

For this demo, all the images which use the `develop` branch have been retrieved from the official `docker-hub` (see also
[Retrieving images](./RETRIEVE_OFFICIAL_IMAGES.md)).

| NF Name | Branch Name | Tag used at time of writing | Ubuntu 22.04 | RHEL8 |
|----------|:------------|-----------------------------|--------------|-------|
| NSSF     | `develop`    | `v2.0.1`                    | X            | -     |
| AMF      | `develop`    | `v2.0.1`                    | X            | -     |
| AUSF     | `develop`    | `v2.0.1`                    | X            | -     |
| NRF      | `develop`    | `v2.0.1`                    | X            | -     |
| SMF      | `develop`    | `v2.0.1`                    | X            | -     |
| UDR      | `develop`    | `v2.0.1`                    | X            | -     |
| UDM      | `develop`    | `v2.0.1`                    | X            | -     |
| PCF      | `develop`    | `v2.0.1`                    | X            | -     |
| UPF-VPP  | `develop`    | `v2.0.1`                    | X            | -     |


<br/>

This tutorial is an extension of a previous tutorial: [testing a `basic` deployment with dsTester](./DEPLOY_SA5G_BASIC_DS_TESTER_DEPLOYMENT.md). In previous tutorial, we have seen the advanced testing tool dsTester, which is useful for validating even more complex scenarios.

Moreover, there are various other opensource gnb/ue simulator tools that are available for SA5G test. In this tutorial, we use an opensource simulator tool called `srsRAN`. With the help of `srsRAN` tool, we can perform very basic SA5G test by simulating one gnb and multiple ues.

##### About srsRAN -

[srsRAN](https://github.com/srsran/srsRAN)  is a 4G/5G software radio suite developed by Software Radio System Ltd.(SRS). srsRAN follows the 3GPP Release 15 standard for NG-RAN and also allows zmq based virtual Radio to simulate RF interface.

Let's begin !!

* Steps 1 to 5 are similar as previous [tutorial on vpp-upf](https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed/-/blob/master/docs/DEPLOY_SA5G_WITH_VPP_UPF.md#5-deploying-oai-5g-core-network). Please follow these steps to deploy OAI 5G core network components.
* We deploy srsRAN docker service on same host as of core network, so there is no need to create additional route as
we did for dsTest-host.
* Before we proceed further for end-to-end SA5G test, make sure you have healthy docker services for OAI cn5g

## 1. Pre-requisites

Create a folder where you can store all the result files of the tutorial and later compare them with our provided result files, we recommend creating exactly the same folder to not break the flow of commands afterwards.

<!---
For CI purposes please ignore this line
``` shell
docker-compose-host $: rm -rf /tmp/oai/srsran
```
-->
* Update QFI Profile0 in SMF since srsran supports only QFI 9.
```bash
- QOS_PROFILE_5QI0=9
```

``` shell
docker-compose-host $: mkdir -p /tmp/oai/srsran
docker-compose-host $: chmod 777 /tmp/oai/srsran
```
## [2. Building Container Images](./BUILD_IMAGES.md) or [Retrieving Container Images](./RETRIEVE_OFFICIAL_IMAGES.md)

## 3. Deploying OAI 5g Core Network

We use `docker-compose` to deploy the core network. Please refer to the file [docker-compose-basic-nrf.yaml](../docker-compose/docker-compose-basic-nrf.yaml)
for details.

We run the `mysql` service first, so that we can start the trace before anything is sent over the CP. 
You can choose to skip this step and deploy all the NFs at once.

``` shell
docker-compose-host $: Creating network "demo-oai-public-net" with driver "bridge"
Creating mysql ... done
```
We capture the packets on the docker networks and filter out ARP. 
``` shell
docker-compose-host $: sleep 1
docker-compose-host $: nohup sudo tshark -i demo-oai -f "not arp" -w /tmp/oai/srsran/control_plane.pcap > /tmp/oai/srsran/control_plane.log 2>&1 &
```
<!--
For CI purposes please ignore this line
``` shell
docker-compose-host $: ../ci-scripts/checkTsharkCapture.py --log_file /tmp/oai/srsran/control_plane.log --timeout 60
```
-->

Then, we start all the NFs.

`` shell
docker-compose-host $: docker-compose -f docker-compose-basic-nrf.yaml up -d
mysql is up-to-date
Creating oai-ext-dn ... done
Creating oai-nrf    ... done
Creating oai-udr    ... done
Creating oai-udm    ... done
Creating oai-ausf   ... done
Creating oai-amf    ... done
Creating oai-smf    ... done
Creating oai-upf    ... done
```
<!--
For CI purposes please ignore this line
``` shell
docker-compose-host $: ../ci-scripts/checkContainerStatus.py --container_name mysql --timeout 120
docker-compose-host $: ../ci-scripts/checkContainerStatus.py --container_name oai-amf --timeout 30
docker-compose-host $: docker-compose -f docker-compose-basic-nrf.yaml ps -a
```
-->
### Checking the Status of the NFs
Using `docker ps` you can verify that no NF exited, e.g. because of a faulty configuration:

Also all should be in an `healthy` state before going further. The `mysql` container may take some time.
```consol
$ docker ps
CONTAINER ID   IMAGE                                     COMMAND                  CREATED              STATUS                        PORTS                                    NAMES
a394e4a58150   oaisoftwarealliance/oai-upf:develop       "/openair-upf/bin/oa…"   About a minute ago   Up About a minute (healthy)   2152/udp, 8805/udp                       oai-upf
4672c6715bae   oaisoftwarealliance/oai-smf:develop       "/openair-smf/bin/oa…"   About a minute ago   Up About a minute (healthy)   80/tcp, 8080/tcp, 8805/udp               oai-smf
e196525da65a   oaisoftwarealliance/oai-amf:develop       "/openair-amf/bin/oa…"   About a minute ago   Up About a minute (healthy)   80/tcp, 8080/tcp, 9090/tcp, 38412/sctp   oai-amf
e91e7d2861e9   oaisoftwarealliance/oai-ausf:develop      "/openair-ausf/bin/o…"   About a minute ago   Up About a minute (healthy)   80/tcp, 8080/tcp                         oai-ausf
1eb6de486815   oaisoftwarealliance/oai-udm:develop       "/openair-udm/bin/oa…"   About a minute ago   Up About a minute (healthy)   80/tcp, 8080/tcp                         oai-udm
b3ef85d1618f   oaisoftwarealliance/oai-udr:develop       "/openair-udr/bin/oa…"   About a minute ago   Up About a minute (healthy)   80/tcp, 8080/tcp                         oai-udr
a8a8b1a12f5d   oaisoftwarealliance/oai-nrf:develop       "/openair-nrf/bin/oa…"   About a minute ago   Up About a minute (healthy)   80/tcp, 8080/tcp, 9090/tcp               oai-nrf
a2a87f08b6f5   oaisoftwarealliance/trf-gen-cn5g:latest   "/bin/bash /tmp/trfg…"   About a minute ago   Up About a minute (healthy)                                            oai-ext-dn
0bf5f7e06cbe   mysql:8.0                                 "docker-entrypoint.s…"   2 minutes ago        Up 2 minutes (healthy)        3306/tcp, 33060/tcp                      mysql
```

Please wait until all NFs are healthy. 

## 4. Geting a `srsRAN` docker image ##
* Pull pre-built docker image 
``` console
docker-compose-host $: docker pull rohankharade/srsran:latest
```

OR 

* Build `srsRAN` docker image
``` console
docker-compose-host $: https://github.com/orion-belt/srsRAN.git
docker-compose-host $: cd srsRAN/
docker-compose-host $: docker build --build-arg BASE_IMAGE=ubuntu:focal -f docker/Dockerfile --target srsran --tag srsran:latest .
```
## 5. Executing the `srsRAN` Scenario 


``` shell
docker-compose-host $: docker-compose -f docker-compose-srsran.yaml up -d
Creating srsran ... done
```

<!---
For CI purposes please ignore this line
``` shell
docker-compose-host $: sleep 10
```
-->

* After launching srsRAN, make sure service status is healthy -
``` shell
docker-compose-host $: docker-compose -f docker-compose-srsran.yaml ps -a
```

We can verify it using srsran container logs as below -

* Sample output logs
```consol
$ docker logs srsran -f
Now setting these variables '@GNBID@ @GTPU_LOCAL_ADDR@ @MCC@ @MNC@ @NGAP_LOCAL_ADDR@ @NGAP_REMOTE_ADDR@'
Now setting these variables '@TAC@'
Now setting these variables '@DNN@ @IMSI@ @KEY@ @OPC@ @PDU_TYPE@'
Done setting the configuration

Running gNB Service 

Active RF plugins: libsrsran_rf_zmq.so
Inactive RF plugins: 
---  Software Radio Systems LTE eNodeB  ---

Couldn't open , trying /root/.config/srsran/enb.conf
Reading configuration file /root/.config/srsran/enb.conf...
Couldn't open sib.conf, trying /root/.config/srsran/sib.conf
Couldn't open rr.conf, trying /root/.config/srsran/rr.conf
Couldn't open rb.conf, trying /root/.config/srsran/rb.conf

Built in Release mode using commit ce8a3cae1 on branch HEAD.

Opening 1 channels in RF device=zmq with args=fail_on_disconnect=true,tx_port=tcp://*:2000,rx_port=tcp://localhost:2001,id=enb,base_srate=11.52e6
Supported RF device list: zmq file
CHx base_srate=11.52e6
CHx id=enb
Current sample rate is 1.92 MHz with a base rate of 11.52 MHz (x6 decimation)
CH0 rx_port=tcp://localhost:2001
CH0 tx_port=tcp://*:2000
CH0 fail_on_disconnect=true
NG connection successful

==== eNodeB started ===
Type <t> to view trace
Current sample rate is 11.52 MHz with a base rate of 11.52 MHz (x1 decimation)
Current sample rate is 11.52 MHz with a base rate of 11.52 MHz (x1 decimation)
Setting frequency: DL=1842.5 Mhz, DL_SSB=1842.05 Mhz (SSB-ARFCN=368410), UL=1747.5 MHz for cc_idx=0 nof_prb=52
Running UE Service 

Active RF plugins: libsrsran_rf_zmq.so
Inactive RF plugins: 
Couldn't open , trying /root/.config/srsran/ue.conf
Reading configuration file /root/.config/srsran/ue.conf...

Built in Release mode using commit ce8a3cae1 on branch HEAD.

Opening 1 channels in RF device=zmq with args=tx_port=tcp://*:2001,rx_port=tcp://localhost:2000,id=ue,base_srate=11.52e6
Supported RF device list: zmq file
CHx base_srate=11.52e6
CHx id=ue
Current sample rate is 1.92 MHz with a base rate of 11.52 MHz (x6 decimation)
CH0 rx_port=tcp://localhost:2000
CH0 tx_port=tcp://*:2001
Current sample rate is 11.52 MHz with a base rate of 11.52 MHz (x1 decimation)
Current sample rate is 11.52 MHz with a base rate of 11.52 MHz (x1 decimation)
Waiting PHY to initialize ... Closing stdin thread.
done!
Attaching UE...
Closing stdin thread.
Random Access Transmission: prach_occasion=0, preamble_index=0, ra-rnti=0xf, tti=7691
RACH:  slot=7691, cc=0, preamble=0, offset=0, temp_crnti=0x4601
Random Access Complete.     c-rnti=0x4601, ta=0
RRC Connected
RRC NR reconfiguration successful.
PDU Session Establishment successful. IP: 12.1.1.151
RRC NR reconfiguration successful.
```

* The configuration parameters, are preconfigured in [docker-compose-basic-vpp-nrf.yaml](../docker-compose/docker-compose-basic-vpp-nrf.yaml) and [docker-compose-srsran.yaml](../docker-compose/docker-compose-srsran.yaml) and one can modify it for test.
* Launch my5G-RANTester docker service

<!---
For CI purposes please ignore this line
``` shell
docker-compose-host $: sleep 5
```
-->


``` console
```

## Traffic test 

## Multiple UEs registration test ##

##  Recover the logs

``` shell
docker-compose-host $: docker logs oai-amf > /tmp/oai/srsran/amf.log 2>&1
docker-compose-host $: docker logs oai-smf > /tmp/oai/srsran/smf.log 2>&1
docker-compose-host $: docker logs oai-nrf > /tmp/oai/srsran/nrf.log 2>&1
docker-compose-host $: docker logs vpp-upf > /tmp/oai/srsran/vpp-upf.log 2>&1
docker-compose-host $: docker logs oai-udr > /tmp/oai/srsran/udr.log 2>&1
docker-compose-host $: docker logs oai-udm > /tmp/oai/srsran/udm.log 2>&1
docker-compose-host $: docker logs oai-ausf > /tmp/oai/srsran/ausf.log 2>&1
docker-compose-host $: docker logs srsran > /tmp/oai/srsran/srsran.log 2>&1
```

## 8. Analysing the Scenario Results 

| Pcap/log files                                                                             |
|:------------------------------------------------------------------------------------------ |
| [5gcn-deployment-srsran.pcap](./results/srsran/5gcn-deployment-srsran.pcap)                  |


* For detailed analysis of messages, please refer previous tutorial of [testing with dsTester](./docs/DEPLOY_SA5G_WITH_DS_TESTER.md).

## 9. Undeploy 

Last thing is to remove all services - <br/>

* Undeploy the srsRAN
``` shell
docker-compose-host $: docker-compose -f docker-compose-srsran.yaml down
Stopping srsran ... done
Removing srsran ... done
Network demo-oai-public-net is external, skipping
Network oai-public-access is external, skipping
```

* Undeploy the core network
``` shell
docker-compose-host $: docker-compose -f docker-compose-basic-vpp-nrf.yaml down
Stopping oai-smf    ... done
Stopping oai-amf    ... 
Stopping oai-ausf   ... 
Stopping oai-ext-dn ... 
Stopping oai-udm    ... 
Stopping vpp-upf    ... 
Stopping oai-udr    ... 
Stopping mysql      ... 
Stopping oai-nrf    ... 
```



