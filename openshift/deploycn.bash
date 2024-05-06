#!/bin/bash
NAMESPACE=`oc project -q`
cd ../charts/oai-5g-core/oai-5g-basic && helm dependency update && helm install oai-5g-basic .
while [[ $(kubectl get pods -l app.kubernetes.io/name=oai-5g-basic-mysql -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod mysql" && sleep 1; done
echo "MySQL ready"

while [[ $(kubectl get pods -l app=oai-amf -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod oai-amf" && sleep 1; done
export AMF_POD_NAME=$(kubectl get pods --namespace $NAMESPACE -l "app.kubernetes.io/name=oai-amf" -o jsonpath="{.items[0].metadata.name}")
export AMF_eth0_POD_IP=$(kubectl get pods --namespace $NAMESPACE -l "app.kubernetes.io/name=oai-amf" -o jsonpath="{.items[0].status.podIP}")
echo "AMF ready"

while [[ $(kubectl get pods -l app=oai-smf -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod oai-smf" && sleep 1; done
export SMF_POD_NAME=$(kubectl get pods --namespace $NAMESPACE -l "app.kubernetes.io/name=oai-smf" -o jsonpath="{.items[0].metadata.name}")
echo "SMF ready"

while [[ $(kubectl get pods -l app=oai-upf -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod oai-upf" && sleep 1; done
export UPF_POD_NAME=$(kubectl get pods --namespace $NAMESPACE -l "app.kubernetes.io/name=oai-upf" -o jsonpath="{.items[0].metadata.name}")
echo "UPF ready"

while [[ $(kubectl get pods -l app=oai-udr -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod oai-udr" && sleep 1; done
export UDR_POD_NAME=$(kubectl get pods --namespace $NAMESPACE -l "app.kubernetes.io/name=oai-udr" -o jsonpath="{.items[0].metadata.name}")
echo "UDR ready"

while [[ $(kubectl get pods -l app=oai-nrf -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod oai-nrf" && sleep 1; done
export NRF_POD_NAME=$(kubectl get pods --namespace $NAMESPACE -l "app.kubernetes.io/name=oai-nrf" -o jsonpath="{.items[0].metadata.name}")
echo "NRF ready"

while [[ $(kubectl get pods -l app=oai-upf-local -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod oai-upf-local" && sleep 1; done
export UPF_LOCAL_POD_NAME=$(kubectl get pods --namespace $NAMESPACE -l "app.kubernetes.io/name=oai-upf-local" -o jsonpath="{.items[0].metadata.name}")
echo "UPF-Local ready"

export UPF_log1=$(oc logs $UPF_POD_NAME -c upf | grep 'Received SX HEARTBEAT REQUEST' | wc -l)
export UPF_log2=$(oc logs $UPF_POD_NAME -c upf | grep 'handle_receive(16 bytes)' | wc -l)
export SMF_log=$(oc logs $SMF_POD_NAME -c smf | grep 'handle_receive(16 bytes)' | wc -l)
if [[ $UPF_log1 ]] && [[ $UPF_log2 ]] && [[ $SMF_log ]]; then
  echo "Core Network start Success!"  >>/dev/stderr
  exit 0
else
  echo "UPF counting log trace \'Received SX HEARTBEAT REQUEST\'=$UPF_log1"  >>/dev/stderr
  echo "UPF counting log trace \'handle_receive(16 bytes)\'=$UPF_log2"  >>/dev/stderr
  echo "SMF counting log trace \'handle_receive(16 bytes)\'=$SMF_log"  >>/dev/stderr
  echo "Core Network start Failed!"  >>/dev/stderr
  exit 1
fi
