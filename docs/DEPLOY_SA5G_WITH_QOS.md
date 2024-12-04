<table style="border-collapse: collapse; border: none;">
  <tr style="border-collapse: collapse; border: none;">
    <td style="border-collapse: collapse; border: none;">
      <a href="http://www.openairinterface.org/">
         <img src="./images/oai_final_logo.png" alt="" border=3 height=50 width=150>
         </img>
      </a>
    </td>
    <td style="border-collapse: collapse; border: none; vertical-align: center;">
      <b><font size = "5">OpenAirInterface 5G Core Network Deployment with eBPF-UPF using docker-compose</font></b>
    </td>
  </tr>
</table>


**Reading time: ~ 30mins**

**Tutorial replication time: ~ 1hs**


**TABLE OF CONTENTS**

[[_TOC_]]

-----------------------------------------------------------------------------------------

## 

Replicate the following steps to test user plane with QoS enabled

```bash
docker-compose -f docker-compose/docker-compose-basic-nrf-ebpf.yaml up
docker-compose -f docker-compose/docker-compose-ueransim-ebpf.yaml up
docker exec -it ueransim ping -I 12.1.1.2 -c1 192.168.72.135 
```

