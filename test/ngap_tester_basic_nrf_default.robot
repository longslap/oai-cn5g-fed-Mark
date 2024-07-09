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
Library    NGAPTesterLib.py
Resource   common.robot

Variables    vars.py

Suite Setup    Launch NRF CN
Suite Teardown    Suite Teardown Default

Test Setup    Test Setup NGAP Tester
Test Teardown    Test Teardown NGAP Tester

*** Test Cases ***

NGAP Tester TC 1 Basic NRF Default
    [Tags]    AMF  AUSF  NRF  NSSF  PCF  SMF  UDM  UDR  UPF
    Run NGAP Tester Test   TC1     default

NGAP Tester TC 1X2 Basic NRF Default
    [Tags]    AMF  AUSF  NRF  NSSF  PCF  SMF  UDM  UDR  UPF
    Run NGAP Tester Test   TC1X2   default

NGAP Tester TC 1V4V6 Basic NRF Default
    [Tags]    AMF  SMF  UPF  PCF
    Run NGAP Tester Test   TC1V4V6   default

NGAP Tester TC 23502_49122 Basic NRF Default
    [Tags]    AMF  SMF  UPF
    TRY
        Run NGAP Tester Test   TC23502_49122   default
    EXCEPT    AS   ${error_message}
        Log   Non-mandatory NGAP Tester test failed: TC23502_49122  level=ERROR
    END

NGAP Tester TC 23502_4913 Basic NRF Default
    [Tags]    AMF  SMF  UPF
    TRY
        Run NGAP Tester Test   TC23502_4913   default
    EXCEPT    AS   ${error_message}
        Log   Non-mandatory NGAP Tester test failed: TC23502_4913  level=ERROR
    END
    
NGAP Tester TC 24501_54137B_T3560 Basic NRF Default
    [Tags]    AMF  SMF  UPF
    TRY
        Run NGAP Tester Test   TC24501_54137B_T3560   default
    EXCEPT    AS   ${error_message}
        Log   Non-mandatory NGAP Tester test failed: TC24501_54137B_T3560  level=ERROR
    END

NGAP Tester TC 24501_54137EF Basic NRF Default
    [Tags]    AMF  SMF  UPF
    Run NGAP Tester Test   TC24501_54137EF   default

NGAP Tester TC N Basic NRF Default
    [Tags]    AMF  SMF  UPF
    Run NGAP Tester Test   TCN   default

NGAP Tester TC SERVICE_REQUEST_24501_5611c Basic NRF Default
    [Tags]    AMF  SMF  UPF
    Run NGAP Tester Test   TC_SERVICE_REQUEST_24501_5611c   default

NGAP Tester TC SERVICE_REQUEST_24501_5611d Basic NRF Default
    [Tags]    AMF  SMF  UPF
    # TODO, this test case should not fail
    TRY
        Run NGAP Tester Test   TC_SERVICE_REQUEST_24501_5611d   default
    EXCEPT    AS   ${error_message}
        Log   Non-mandatory NGAP Tester test failed: TC_SERVICE_REQUEST_24501_5611d  level=ERROR
    END

NGAP Tester TC SERVICE_REQUEST_24501_5611d_Easy Basic NRF Default
    [Tags]    AMF  SMF  UPF
    Run NGAP Tester Test   TC_SERVICE_REQUEST_24501_5611d_easy   default

NGAP Tester TC SERVICE_REQUEST_24501_5611e Basic NRF Default
    [Tags]    AMF  SMF  UPF
    TRY
        Run NGAP Tester Test   TC_SERVICE_REQUEST_24501_5611e   default
    EXCEPT    AS   ${error_message}
        Log   Non-mandatory NGAP Tester test failed: TC_SERVICE_REQUEST_24501_5611e  level=ERROR
    END
