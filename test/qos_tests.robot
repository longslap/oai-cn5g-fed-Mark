# Licensed to the OpenAirInterface (OAI) Software Alliance under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The OpenAirInterface Software Alliance licenses this file to You under
# the OAI Public License, Version 1.1  (the "License"); you may not use this file
# except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.openairinterface.org/?page_id=698
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ------------------------------------------------------------------------------
# For more information about the OpenAirInterface (OAI) Software Alliance:
#   contact@openairinterface.org
# ---------------------------------------------------------------------

*** Settings ***
Library    Process
Library    CNTestLib.py
Library    GNBSimTestLib.py
Resource   common.robot

Variables    vars.py

Suite Setup    Launch NRF CN For QoS
Suite Teardown    Suite Teardown Default

Test Setup    Test Setup With Gnbsim
Test Teardown    Test Teardown With Gnbsim

*** Test Cases ***

UPF Bandwidth 1000Mbits
    [Tags]  UPF
    Start Gnbsim    ${GNBSIM_IN_USE}
    ${ip} =   Check Gnbsim IP    ${GNBSIM_IN_USE}

    # UPLINK
    Start Iperf3 Server     ${EXT_DN1_NAME}
    Start Iperf3 Client     ${GNBSIM_IN_USE}  ${ip}  ${EXT_DN1_NAME}  bandwidth=1000
    Wait and Verify Iperf3 Result   ${GNBSIM_IN_USE}  1000

    # DOWNLINK
    Start Iperf3 Server     ${GNBSIM_IN_USE}
    Start Iperf3 Client     ${EXT_DN1_NAME}  ${EXT_DN1_IP}  ${ip}  bandwidth=1000
    Wait and Verify Iperf3 Result   ${EXT_DN1_NAME}  1000

Default QoS Session AMBR
    [Tags]  SMF  UPF  PCF
    Configure Default Qos  5qi=9  session_ambr=50  # TODO
    Start GnbSIM    ${GNBSIM_IN_USE}
    ${ip} =  Check Gnbsim IP    ${GNBSIM_IN_USE}
    # UPLINK
    Start Iperf3 Server     ${EXT_DN1_NAME}
    Start Iperf3 Client     ${GNBSIM_IN_USE}  ${ip}  ${EXT_DN1_IP}  bandwidth=40
    Wait and Verify Iperf3 Result   ${GNBSIM_IN_USE}  40

    Start Iperf3 Client    ${GNBSIM_IN_USE}   ${ip}  ${EXT_DN1_IP}  bandwidth=60
    Wait And Verify Iperf3 Result    ${GNBSIM_IN_USE}    50
    # TODO error in CNTestLib or dockerlib, background task ID is correct, but get wrong one from docker API
    # Stop Iperf3 Server    ${EXT_DN1_NAME}

    # DOWNLINK
    Start Iperf3 Server     ${GNBSIM_IN_USE}   bind_ip=${ip}
    Start Iperf3 Client     ${EXT_DN1_NAME}  ${EXT_DN1_IP}  ${ip}   bandwidth=40
    Wait And Verify Iperf3 Result    ${EXT_DN1_NAME}    40

    Start Iperf3 Client     ${EXT_DN1_NAME}  ${EXT_DN1_IP}  ${ip}   bandwidth=60
    Wait And Verify Iperf3 Result    ${EXT_DN1_NAME}    50
    # Stop Iperf3 Server      ${GNBSIM_IN_USE}


QoS Flow Session AMBR
    [Tags]  SMF  UPF  PCF
    Configure Default Qos  five_qi=9  session_ambr=50  # TODO
    Add Qos Flow On Pcf    five_qi=5  match=${EXT_DN2_IP}
    Start GnbSIM    ${GNBSIM_IN_USE}
    ${ip} =  Check Gnbsim IP    ${GNBSIM_IN_USE}
    Start Iperf3 Server     ${GNBSIM_IN_USE}   39265   bind_ip=${ip}
    Start Iperf3 Client     ${EXT_DN1_NAME}   ${EXT_DN1_IP}  ${ip}

    Start Iperf3 Server    ${GNBSIM_IN_USE}    39266   bind_ip=${ip}
    Start Iperf3 Client    ${EXT_DN2_NAME}   ${EXT_DN2_IP}  ${ip}   port=39266   bandwidth=10

    Wait And Verify Iperf3 Result    ${EXT_DN1_NAME}    40
    Wait And Verify Iperf3 Result    ${EXT_DN2_NAME}    10


QoS Flow GBR Session AMBR
    [Tags]  SMF  UPF  PCF
    Configure Default Qos  5qi=9  session_ambr=50  # TODO
    Add Qos Flow On Pcf    five_qi=1   gfbr=10   mfbr=11   match=${EXT_DN_2_IP}
    Start GnbSIM    ${GNBSIM_IN_USE}
    ${ip} =  Check Gnbsim IP    ${GNBSIM_IN_USE}
    Start Iperf3 Server     ${GNBSIM_IN_USE}   39265   bind_ip=${ip}
    Start Iperf3 Client     ${EXT_DN1_NAME}   ${EXT_DN1_IP}  ${ip}

    Start Iperf3 Server    ${GNBSIM_IN_USE}    39266   bind_ip=${ip}
    Start Iperf3 Client    ${EXT_DN2_NAME}   ${EXT_DN2_IP}  ${ip}   port=39266   bandwidth=10

    Wait And Verify Iperf3 Result    ${EXT_DN1_NAME}    40
    Wait And Verify Iperf3 Result    ${EXT_DN2_NAME}    10

QoS Flow GBR Session AMBR 2
    [Tags]  SMF  UPF  PCF
    Configure Default Qos  5qi=9  session_ambr=50  # TODO
    Add Qos Flow On Pcf    five_qi=5    match=${EXT_DN_2_IP}
    Add Qos Flow On Pcf    five_qi=1   gfbr=10   mfbr=11   match=${EXT_DN_3_IP}
    Start GnbSIM    ${GNBSIM_IN_USE}
    ${ip} =  Check Gnbsim IP    ${GNBSIM_IN_USE}
    Start Iperf3 Server     ${GNBSIM_IN_USE}   39265   bind_ip=${ip}
    Start Iperf3 Client     ${EXT_DN1_NAME}   ${EXT_DN1_IP}  ${ip}

    Start Iperf3 Server    ${GNBSIM_IN_USE}    39266   bind_ip=${ip}
    Start Iperf3 Client    ${EXT_DN2_NAME}   ${EXT_DN2_IP}  ${ip}   port=39266   bandwidth=10

    Start Iperf3 Server    ${GNBSIM_IN_USE}    39267   bind_ip=${ip}
    Start Iperf3 Client    ${EXT_DN3_NAME}   ${EXT_DN3_IP}  ${ip}   port=39267   bandwidth=10

    Wait And Verify Iperf3 Result    ${EXT_DN1_NAME}    0
    Wait And Verify Iperf3 Result    ${EXT_DN2_NAME}    5
    Wait And Verify Iperf3 Result    ${EXT_DN3_NAME}    10

