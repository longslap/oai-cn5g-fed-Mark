#!/bin/bash
NAMESPACE=`oc project -q`
while [[ $(kubectl get pods -l app=oai-amf -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod oai-amf" && sleep 1; done
while [[ $(kubectl get pods -l app=oai-smf -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod oai-smf" && sleep 1; done
while [[ $(kubectl get pods -l app=oai-upf -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod oai-upf" && sleep 1; done
AMF_POD_NAME=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-amf`

sleep 3

helm install -f ../charts/oai-5g-ran/oai-cu-cp/Chart.yaml cucp ../charts/oai-5g-ran/oai-cu-cp \
        --set start.tcpdump="false" \
        --set includeTcpDumpContainer="false"

while [[ $(kubectl get pods -l app=oai-cu-cp -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod oai-cu-cp" && sleep 1; done
CUCP_POD_NAME=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-cu-cp | grep -v build`
echo "CUCP=$CUCP_POD_NAME"
sleep 3
AMF_LOG=$(kubectl logs -c amf $AMF_POD_NAME | grep 'Sending NG_SETUP_RESPONSE Ok' | wc -l)
if [[ $AMF_LOG == 0 ]]; then
  echo 'Error: CUCP did not connect to AMF!'
  exit 1
else
  echo 'CUCP connected to AMF!'
fi

# DU @ is config.f1duIpAddress="192.168.20.13" 
# DU LOCAL @ is config.f1duIpAddress="192.168.20.17"
helm install -f ../charts/oai-5g-ran/oai-cu-up/Chart.yaml cuup1 ../charts/oai-5g-ran/oai-cu-up \
        --set serviceAccount.name=oai-cu-up1-sa \
        --set multus.e1Interface.ipAdd="172.21.6.191" \
        --set multus.n3Interface.ipAdd="172.21.6.191" \
        --set multus.f1uInterface.ipAdd="172.21.6.191" \
        --set config.cuCpHost="172.21.6.190" \
        --set config.f1duIpAddress="172.21.6.193" \
        --set config.nssaiSst="1" \
        --set config.nssaiSd="0xffffff" \
        --set start.tcpdump="false" \
        --set includeTcpDumpContainer="false"
while [[ $(kubectl get pods -l app=oai-gnb-cu-up -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod oai-cu-up" && sleep 1; done
CUUP1=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-cu-up | grep -v build`
echo "CUUP1=$CUUP1"
oc logs $CUUP1 -c oaicuup > cuup1-start.log

helm install -f ../charts/oai-5g-ran/oai-cu-up2/Chart.yaml cuup2 ../charts/oai-5g-ran/oai-cu-up2 \
        --set multus.e1Interface.ipAdd="172.21.6.192" \
        --set multus.n3Interface.ipAdd="172.21.6.192" \
        --set multus.f1uInterface.ipAdd="172.21.6.192" \
        --set config.cuCpHost="172.21.6.190" \
        --set config.f1duIpAddress="172.21.6.193" \
        --set config.nssaiSst="2" \
        --set config.nssaiSd="0xffffff" \
        --set start.tcpdump="false" \
        --set includeTcpDumpContainer="false"
while [[ $(kubectl get pods -l app=oai-gnb-cu-up2 -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod oai-cu-up2" && sleep 1; done
CUUP2=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep -v $CUUP2 | grep oai-cu-up2 | grep -v build`
echo "CUUP2=$CUUP2"
oc logs $CUUP2 -c oaicuup > cuup2-start.log


helm install -f ../charts/oai-5g-ran/oai-flexric/Chart.yaml ric ../charts/oai-5g-ran/oai-flexric \
        --set start.tcpdump="false" \
        --set includeTcpDumpContainer="false"
while [[ $(kubectl get pods -l app=oai-flexric -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod oai-flexric" && sleep 1; done
RIC=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep -v $CUUP1 | grep oai-flexric | grep -v build`
echo "RIC=$RIC"
oc logs $RIC -c ric > ric-start.log




LOCAL_DEPLOYMENT=false
if [ "$LOCAL_DEPLOYMENT" = true ]; then

helm install -f ../charts/oai-5g-ran/oai-du/Chart.yaml du \
                ../charts/oai-5g-ran/oai-du \
        --set start.tcpdump="false" \
        --set includeTcpDumpContainer="false"

while [[ $(kubectl get pods -l app=oai-du -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod oai-du" && sleep 1; done
DU_POD_NAME=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-du | grep -v build`
DU_IP=`kubectl get pod $DU_POD_NAME --template '{{.status.podIP}}'`
echo "DU=$DU_POD_NAME @ $DU_IP"
sleep 5

if [ $START_UE1 -ne 0 ]; then
  helm install -f ../charts/oai-5g-ran/oai-nr-ue/Chart.yaml ue1 \
                  ../charts/oai-5g-ran/oai-nr-ue \
                  --set config.rfsimHost="$DU_IP" \
                  --set config.rfSimServer="$DU_IP"
  while [[ $(kubectl get pods -l app=oai-nr-ue -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod oai-nr-ue" && sleep 1; done
  UE1_POD_NAME=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-nr-ue | grep -v build`
  echo "UE1=$UE1_POD_NAME"

  RETURN_VAL=''
  wait4UeIpAddress $UE1_POD_NAME
  if python3 -c "import ipaddress; ipaddress.ip_address('${RETURN_VAL}')" 2>/dev/null; then
    echo "UE1 IP_ADDR $RETURN_VAL is a valid IPv4 or IPv6 address"
    oc rsh -c nr-ue $UE1_POD_NAME ping -c 10 8.8.8.8 -I oaitun_ue1
  else
    echo "UE1 IP_ADDR $RETURN_VAL is not a valid IPv4 or IPv6 address"
    exit 1
  fi
fi
# if [ $START_UE2 -ne 0 ]; then
#   helm install -f ../charts/oai-5g-ran/oai-nr-ue2/Chart.yaml ue2 \
#                   ../charts/oai-5g-ran/oai-nr-ue2 \
#                   --set config.rfsimHost="$DU_IP" \
#                   --set config.rfSimServer="$DU_IP"

#   while [[ $(kubectl get pods -l app=oai-nr-ue2 -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod oai-nr-ue2" && sleep 1; done
#   UE2_POD_NAME=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-nr-ue2 | grep -v build`
#   UE2=$UE2_POD_NAME
#   echo "UE2=$UE2_POD_NAME"

#   RETURN_VAL=''
#   wait4UeIpAddress $UE2_POD_NAME
#   if python3 -c "import ipaddress; ipaddress.ip_address('${RETURN_VAL}')" 2>/dev/null; then
#     echo "UE2 IP_ADDR $RETURN_VAL is a valid IPv4 or IPv6 address"
#     oc rsh -c nr-ue $UE2_POD_NAME ping -c 10 8.8.8.8 -I oaitun_ue1
#   else
#     echo "UE2 IP_ADDR $RETURN_VAL is not a valid IPv4 or IPv6 address"
#     exit 1
#   fi
# fi
fi
exit 0
