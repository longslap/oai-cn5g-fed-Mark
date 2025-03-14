#!/bin/bash
oc delete buildconfig oai-ran-base
oc create -f ./oai-ran-base-build-config.yaml
oc start-build oai-ran-base --follow

oc delete buildconfig oai-ran-build
oc create -f ./oai-ran-builder-build-config.yaml
oc start-build oai-ran-build --follow

oc delete buildconfig oai-gnb
oc create -f ./oai-gnb-build-config.yaml
oc start-build oai-gnb --follow

oc delete buildconfig oai-cu-up
oc create -f ./oai-cu-up-build-config.yaml  
oc start-build oai-cu-up --follow

oc delete buildconfig oai-nr-ue
oc create -f ./oai-nr-ue-build-config.yaml    
oc start-build oai-nr-ue --follow

