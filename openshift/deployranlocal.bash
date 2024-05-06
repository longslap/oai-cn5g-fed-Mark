#!/bin/bash
NAMESPACE=`oc project -q`
while [[ $(kubectl get pods -l app=oai-amf -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod oai-amf" && sleep 1; done
while [[ $(kubectl get pods -l app=oai-smf -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod oai-smf" && sleep 1; done
while [[ $(kubectl get pods -l app=oai-upf -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod oai-upf" && sleep 1; done
while [[ $(kubectl get pods -l app=oai-upf-local -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod oai-upf-local" && sleep 1; done
AMF_POD_NAME=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-amf`



helm install -f ../charts/oai-5g-ran/oai-cu-up-local/Chart.yaml cuuplocal ../charts/oai-5g-ran/oai-cu-up-local \
        --set serviceAccount.name=oai-cu-up-local-sa \
        --set multus.e1Interface.IPadd="172.21.6.196" \
        --set multus.n3Interface.IPadd="172.21.6.196" \
        --set multus.f1uInterface.IPadd="172.21.6.196" \
        --set config.cuCpHost="172.21.6.190" \
        --set config.f1uDuIpAddress="172.21.6.195" \
        --set config.nssaiSst="1" \
        --set config.nssaiSd="0x000001" \
        --set start.tcpdump="true" \
        --set includeTcpDumpContainer="true" 
while [[ $(kubectl get pods -l app=oai-cu-up-local -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod oai-cu-up-local" && sleep 1; done
CUUP_local=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-cu-up-local`
echo "CUUP_local=$CUUP_local"
oc logs $CUUP_local -c gnbcuup > cuup-local-start.log

helm install -f ../charts/oai-5g-ran/oai-du-local/Chart.yaml dulocal \
                ../charts/oai-5g-ran/oai-du-local \
        --set start.tcpdump="false" \
        --set includeTcpDumpContainer="false" 
while [[ $(kubectl get pods -l app=oai-du-local -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod oai-du-local" && sleep 1; done
DU_LOCAL_POD_NAME=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-du-local`
DU_LOCAL_IP=`kubectl get pod $DU_LOCAL_POD_NAME --template '{{.status.podIP}}'`
echo "DU_local=$DU_LOCAL_POD_NAME @ $DU_LOCAL_IP"

sleep 5

if [ $START_UE1_LOCAL -ne 0 ]; then
  helm install -f ../charts/oai-5g-ran/oai-nr-ue-local/Chart.yaml ue1local \
                ../charts/oai-5g-ran/oai-nr-ue-local \
                --set config.rfsimHost="$DU_LOCAL_IP" \
                --set config.rfSimServer="$DU_LOCAL_IP"
  while [[ $(kubectl get pods -l app=oai-nr-ue-local -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod oai-nr-ue-local" && sleep 1; done
  UE1_LOCAL_POD_NAME=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-nr-ue-local`
  echo "UE1_LOCAL=$UE1_LOCAL_POD_NAME"

  RETURN_VAL=''
  wait4UeIpAddress $UE1_LOCAL_POD_NAME
  if python3 -c "import ipaddress; ipaddress.ip_address('${RETURN_VAL}')" 2>/dev/null; then
  echo "UE1LOCAL IP_ADDR $RETURN_VAL is a valid IPv4 or IPv6 address"
  oc rsh -c nr-ue $UE1_LOCAL_POD_NAME ping -c 15 8.8.8.8 -I oaitun_ue1
  else
  echo "UE1LOCAL IP_ADDR $RETURN_VAL is not a valid IPv4 or IPv6 address"
  fi
fi

if [ $START_UE2_LOCAL -ne 0 ]; then
  helm install -f ../charts/oai-5g-ran/oai-nr-ue2-local/Chart.yaml ue2local \
                ../charts/oai-5g-ran/oai-nr-ue2-local \
                  --set config.rfsimHost="$DU_LOCAL_IP" \
                  --set config.rfSimServer="$DU_LOCAL_IP"
  while [[ $(kubectl get pods -l app=oai-nr-ue2-local -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod oai-nr-ue2-local" && sleep 1; done
  UE2_LOCAL_POD_NAME=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-nr-ue2-local`
  echo "UE2_LOCAL=$UE2_LOCAL_POD_NAME"

  RETURN_VAL=''
  wait4UeIpAddress $UE2_LOCAL_POD_NAME
  if python3 -c "import ipaddress; ipaddress.ip_address('${RETURN_VAL}')" 2>/dev/null; then
    echo "UE2LOCAL IP_ADDR $RETURN_VAL is a valid IPv4 or IPv6 address"
    oc rsh -c nr-ue $UE2_LOCAL_POD_NAME ping -c 15 8.8.8.8 -I oaitun_ue1
  else
    echo "UE2LOCAL IP_ADDR $RETURN_VAL is not a valid IPv4 or IPv6 address"
  fi
fi


