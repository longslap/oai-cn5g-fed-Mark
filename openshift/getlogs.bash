#!/bin/bash


AMF=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-amf | grep -v build`
AUSF=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-ausf | grep -v build`
CUCP=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-cu-cp | grep -v build`
CUUP1=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-cu-up | grep -v oai-cu-up2 | grep -v local | grep -v build`
CUUP2=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-cu-up2 | grep -v build`
CUUPLOCAL=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-cu-up-local | grep -v build`
DULOCAL=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-du-local | grep -v build`
DU=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-du | grep -v local | grep -v build`
NRF=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-nrf | grep -v build`
SMF=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-smf | grep -v build`
UDM=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-udm | grep -v build`
UDR=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-udr | grep -v build`
UE1LOCAL=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-nr-ue-local | grep -v build`
UE1=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-nr-ue | grep -v ue2 | grep -v local | grep -v build`
UE2LOCAL=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-nr-ue2-local | grep -v build`
UE2=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-nr-ue2  | grep -v local | grep -v build`
UPFLOCAL=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-upf-local | grep -v build`
UPF=`oc get pods -o custom-columns=POD:.metadata.name --no-headers | grep oai-upf | grep -v oai-upf-local | grep -v build`

# disk space not so big
rm -Rf pcap/*
rm *.log
TIMESTAMP=`date +%Y-%m-%d_%H_%M-%S-%Z`
if [ "a$AMF" != "a" ]; then 
  echo "AMF=$AMF"; 
  oc logs $AMF -c amf > $TIMESTAMP'_amf'.log;
  oc rsync -c tcpdump $AMF:/tmp/pcap . ;
fi
if [ "a$AUSF" != "a" ]; then 
  echo "AUSF=$AUSF"; 
  oc logs $AUSF -c ausf > $TIMESTAMP'_ausf'.log ; 
fi
if [ "a$CUCP" != "a" ]; then 
  echo "CUCP=$CUCP"; 
  oc logs $CUCP -c gnbcucp > $TIMESTAMP'_cucp'.log; 
  oc rsync -c tcpdump $CUCP:/tmp/pcap . ; 
fi
if [ "a$CUUP1" != "a" ]; then 
  echo "CUUP1=$CUUP1"; 
  oc logs $CUUP1 -c gnbcuup > $TIMESTAMP'_cuup1'.log; 
  oc rsync -c tcpdump $CUUP1:/tmp/pcap . ; 
fi
if [ "a$CUUP2" != "a" ]; then 
  echo "CUUP2=$CUUP2"; 
  oc logs $CUUP2 -c gnbcuup > $TIMESTAMP'_cuup2'.log; 
  oc rsync -c tcpdump $CUUP2:/tmp/pcap . ; 
fi
if [ "a$CUUPLOCAL" != "a" ]; then 
  echo "CUUPLOCAL=$CUUPLOCAL"; 
  oc logs $CUUPLOCAL -c gnbcuup > $TIMESTAMP'_cuuplocal'.log; 
  oc rsync -c tcpdump $CUUPLOCAL:/tmp/pcap . ; 
fi
if [ "a$DU" != "a" ]; then 
  echo "DU=$DU"; 
  oc logs $DU -c gnbdu > $TIMESTAMP'_du'.log; 
  oc rsync -c tcpdump $DU:/tmp/pcap . ; 
fi
if [ "a$DULOCAL" != "a" ]; then 
  echo "DULOCAL=$DULOCAL"; 
  oc logs $DULOCAL -c gnbdu > $TIMESTAMP'_dulocal'.log; 
  oc rsync -c tcpdump $DULOCAL:/tmp/pcap . ; 
fi
if [ "a$NRF" != "a" ]; then echo "NRF=$NRF"; fi
if [ "a$SMF" != "a" ]; then echo "SMF=$SMF"; fi
if [ "a$UDM" != "a" ]; then echo "UDM=$UDM"; fi
if [ "a$UDR" != "a" ]; then echo "UDR=$UDR"; fi
if [ "a$UE1" != "a" ]; then 
  echo "UE1=$UE1"; 
  oc logs $UE1 -c nr-ue > $TIMESTAMP'_ue1'.log; 
fi
if [ "a$UE1LOCAL" != "a" ]; then 
  echo "UE1LOCAL=$UE1LOCAL"; 
  oc logs $UE1LOCAL -c nr-ue > $TIMESTAMP'_ue1local'.log; 
fi
if [ "a$UE2" != "a" ]; then 
  echo "UE2=$UE2"; 
  oc logs $UE2 -c nr-ue > $TIMESTAMP'_ue2'.log; 
fi
if [ "a$UE2LOCAL" != "a" ]; then
  echo "UE2LOCAL=$UE2LOCAL"; 
  oc logs $UE2LOCAL -c nr-ue > $TIMESTAMP'_ue2local'.log; 
fi
if [ "a$UPF" != "a" ]; then 
  echo "UPF=$UPF"; 
  oc logs $UPF -c upf > $TIMESTAMP'_upf'.log; 
  oc rsync -c tcpdump $UPF:/tmp/pcap .; 
fi
if [ "a$UPFLOCAL" != "a" ]; then echo "UPFLOCAL=$UPFLOCAL"; fi
exit 0


