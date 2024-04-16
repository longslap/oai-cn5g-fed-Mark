# Helm chart for Asterisk SIP

The helm-chart is tested on [Minikube](https://minikube.sigs.k8s.io/docs/) and [Red Hat Openshift](https://www.redhat.com/fr/technologies/cloud-computing/openshift) 4.10, 4.12 and 4.13. There are no special resource requirements for Asterisk. 

**NOTE**: 
- We are only maintaining these helm-charts temporarily till the time we don't have an IMS
- We will not provide any support for asterisk. Only if it used with OAI.
- All the extra interfaces/multus interfaces created inside the pod are using `macvlan` mode. If your environment does not allow using `macvlan` then you need to change the multus definition.

## Introduction

We have built our own asterisk image on ubuntu base image and its on [dockerhub](https://hub.docker.com/r/oaisoftwarealliance/ims). The user information for the UEs is in [./templates/configmap.yaml](./templates/configmap.yaml).

These helm charts creates multiples Kubernetes resources,

1. Service
2. Role Base Access Control (RBAC) (role and role bindings)
3. Deployment
4. Configmap (contains users.conf to add all the user information)
5. Service account
6. Network-attachment-definition (Optional only when multus is used)

The directory structure

```
├── Chart.yaml
├── README.md
├── templates
│   ├── configmap.yaml (contains users.conf to add all the user information)
│   ├── deployment.yaml
│   ├── _helpers.tpl
│   ├── multus.yaml
│   ├── NOTES.txt
│   ├── rbac.yaml
│   ├── serviceaccount.yaml
│   └── service.yaml
└── values.yaml (Parent file contains all the configurable parameters)

```

## Parameters

[Values.yaml](./values.yaml) contains all the configurable parameters. Below table defines the configurable parameters. 


|Parameter                    |Allowed Values                 |Remark                                   |
|-----------------------------|-------------------------------|-----------------------------------------|
|kubernetesType               |Vanilla/Openshift              |Vanilla Kubernetes or Openshift          |
|image.repository           |Image Name                     |                                         |
|image.version              |Image tag                      |                                         |
|image.pullPolicy           |IfNotPresent or Never or Always|                                         |
|imagePullSecrets.name        |String                         |Good to use for docker hub               |
|serviceAccount.create        |true/false                     |                                         |
|serviceAccount.annotations   |String                         |                                         |
|serviceAccount.name          |String                         |                                         |
|exposedPorts.tcp            |Integer                        |TCP port to be exposed                  |
|exposedPorts.udp            |Integer                        |UDP port to be exposed                  |
|podSecurityContext.runAsUser |Integer (0,65534)              |Mandatory to use 0                       |
|podSecurityContext.runAsGroup|Integer (0,65534)              |Mandatory to use 0                       |
|multus.create                |true/false                     |default false                            |
|multus.IPadd               |IPV4                           |NA                                       |
|multus.Netmask             |Netmask                        |NA                                       |
|multus.defaultGateway        |IPV4                           |Default route inside container (optional)|
|multus.hostInterface         |HostInterface Name             |NA                                       |


## Advanced Debugging Parameters

Only needed if you are doing advanced debugging

|Parameter                    |Allowed Values|Remark                   |
|-----------------------------|--------------|-------------------------|
|resources.define             |true/false    |                         |
|resources.limits.cpu         |string        |Unit m for milicpu or cpu|
|resources.limits.memory      |string        |Unit Mi/Gi/MB/GB         |
|resources.limits.nf.cpu      |string        |Unit m for milicpu or cpu|
|resources.limits.nf.memory   |string        |Unit Mi/Gi/MB/GB         |
|resources.requests.cpu       |string        |Unit m for milicpu or cpu|
|resources.requests.memory    |string        |Unit Mi/Gi/MB/GB         |
|readinessProbe               |true/false    |default true             |
|livenessProbe                |true/false    |default false            |
|terminationGracePeriodSeconds|5             |In seconds (default 5)   |
|nodeSelector                 |Node label    |                         |
|nodeName                     |Node Name     |                         |

## Installation

Better to use the parent charts from [oai-5g-basic](../oai-5g-basic/README.md) for basic deployment of OAI-5G Core network. Enable `ims` in [values.yaml](../oai-5g-basic/values.yaml) to install ims. 

## Note

1. If you are using multus then make sure it is properly configured and if you don't have a gateway for your multus interface then avoid using gateway and defaultGateway parameter. Either comment them or leave them empty. Wrong gateway configuration can create issues with pod networking and pod will not be able to resolve service names.
2. Some useful asterisk commands, for debugging to reload the server `asterix -r`, `sip users reload` and `sip users list`