#!/bin/bash
export START_UE1=1
export START_UE2=0
export START_UE1_LOCAL=1
export START_UE2_LOCAL=0

function wait4Podlog {
  UE_POD_NAME=$1
  CONTAINER_NAME=$2
  LOG_WANTED="$3"
  # Waiting for UE receive its IP address from CN with time-out
  for ((i=1;i<=10;i++)); do
    LOG=$(kubectl logs -c $CONTAINER_NAME $UE_POD_NAME | grep "$LOG_WANTED" | wc -l)
    if [[ $LOG == 0 ]]; then
      echo "."
      sleep 2
    else
      return 0
    fi
  done
  return 1
}

export RETURN_VAL=''
# RETURN_VAL should be set and read by calling bash
function wait4UeIpAddress {
  UE_POD_NAME=$1
  wait4Podlog $UE_POD_NAME nr-ue 'Interface\ oaitun_ue1'
  RESULT=$?
  if [[ $RESULT == 0 ]]; then
    RETURN_VAL=$(kubectl exec -it -n $NAMESPACE -c nr-ue $UE_POD_NAME -- ifconfig oaitun_ue1 |grep -E '(^|\s)inet($|\s)' | awk {'print $2'})
    return 0
  else
    RETURN_VAL='NOT AN IP ADDRESS'
    return 1
  fi
}

export -f wait4Podlog
export -f wait4UeIpAddress

export NAMESPACE=`oc project -q`
helm uninstall -n $NAMESPACE $(helm list -aq -n $NAMESPACE)
sleep 3
./deploycn.bash
ret=$?;[[ $ret -ne 0 ]] && exit $ret
sleep 3
./deployran.bash
ret=$?;
sleep 3
./deployranlocal.bash
ret=$?;

CUCP=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-cu-cp | grep -v build`
CUUP1=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-cu-up | grep -v oai-cu-up2 | grep -v local | grep -v build`
CUUP2=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-cu-up2 | grep -v build`
CUUPLOCAL=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-cu-up-local | grep -v build`
DU=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-du | grep -v local | grep -v build`
DULOCAL=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-du-local | grep -v build`
UE1=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-nr-ue | grep -v ue2 | grep -v local | grep -v build`
UE2=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-nr-ue2  | grep -v local | grep -v build`
UE1LOCAL=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-nr-ue-local | grep -v build`
UE2LOCAL=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-nr-ue2-local | grep -v build`
UPF=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-upf | grep -v oai-upf-local | grep -v build`
UPFLOCAL=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-upf-local | grep -v build`
AMF=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-amf | grep -v build`
SMF=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-smf | grep -v build`
UDR=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-udr | grep -v build`
UDM=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-udm | grep -v build`

echo "CUCP=$CUCP"
echo "CUUP1=$CUUP1"
echo "CUUP2=$CUUP2"
echo "CUUPLOCAL=$CUUPLOCAL"
echo "DU=$DU"
echo "DULOCAL=$DULOCAL"
echo "UE1=$UE1"
echo "UE2=$UE2"
echo "UE1LOCAL=$UE1LOCAL"
echo "UE2LOCAL=$UE2LOCAL"
echo "UPF=$UPF"
echo "UPFLOCAL=$UPFLOCAL"
echo "AMF=$AMF"
echo "SMF=$SMF"
exit 0


