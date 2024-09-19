<table style="border-collapse: collapse; border: none;">
  <tr style="border-collapse: collapse; border: none;">
    <td style="border-collapse: collapse; border: none;">
      <a href="http://www.openairinterface.org/">
         <img src="../docs/images/oai_final_logo.png" alt="" border=3 height=50 width=150>
         </img>
      </a>
    </td>
    <td style="border-collapse: collapse; border: none; vertical-align: center;">
      <b><font size = "5">OpenAirInterface: Building UBI Container Images</font></b>
    </td>
  </tr>
</table>

**TABLE OF CONTENTS**

0.  [Pre-requisites](#0-pre-requisites)
1.  [How to Build UBI Images of Core Network Function](#1-how-to-build-ubi-images-of-core-network-functions)
2.  [How to Build UBI Images of gNB and UE](#2-how-to-build-ubi-images-of-gnb-and-ue)


## 0. Pre-requisites

We assume that there is already a project name `oai-tutorial` in case there is no project like that then create a new project `oc new-project oai-tutorial`. 

Also you need to create configmaps and secrets because that is needed for creating the images of the network functions. In the future we will try to avoid using the entitlements. Run below commands from a RHEL8 host machine which have access to Openshift cluster,

```bash
oc create configmap rhsm-conf --from-file /etc/rhsm/rhsm.conf
oc create configmap rhsm-ca --from-file /etc/rhsm/ca/redhat-uep.pem
oc create secret generic etc-pki-entitlement --from-file /etc/pki/entitlement/<pem>.pem --from-file /etc/pki/entitlement/<key>-key.pem
```

*NOTE*: The entitlements have to be renewed every month. We will remove import of entitlements and configmaps starting next release. 

## 1. How to Build UBI Images of Core Network Functions?

Create the build configs for each core network function, the build config yamls will also create the image streams.

```bash
oc create -f oai-amf-build-config.yaml
oc create -f oai-ausf-build-config.yaml
oc create -f oai-udr-build-config.yaml
oc create -f oai-udm-build-config.yaml
oc create -f oai-smf-build-config.yaml
oc create -f oai-upf-build-config.yaml
oc create -f oai-nrf-build-config.yaml
```

You can do `oc get bc` to see all the build configs in `oai-tutorial` project. Once all the build config definations are there, you can start building the network function images parallel or one by one its a choice, 

``` bash
oc start-bc oai-amf 
oc start-bc oai-smf 
oc start-bc oai-ausf 
oc start-bc oai-nrf
oc start-bc oai-upf
oc start-bc oai-udm
oc start-bc oai-udr
```

For the moment the dockerfiles used in these build configs are based on v1.4.0 release tag of all the network functions. 

## 2. How to Build UBI Images of gNB and UE?

For the moment CU and DU are using the same image with different configuration parameters so you just need to build one monolithic gNB image. 

The gNB image is build in three steps
- Base image
- Builder image
- Final/Target image

You can follow [this tutorial](https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/develop/openshift/README.md?ref_type=heads) to build RAN network function images. 
