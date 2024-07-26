*** Settings ***
Library    OperatingSystem
Library    Process
Library    common.py   WITH NAME   common   

Library    5gcsdk/src/modules/RFsimUEManager.py    WITH NAME    RFsim
Library    5gcsdk/src/main/init_handler.py    WITH NAME    Handler
Library    NotificationTest.py     WITH NAME    NotifTest

Suite Setup    Launch northbound CN
Suite Teardown    Down northbound CN

*** Variables ***
${DOCKER_YAML_PATH}   test/template/northbound_templates/docker-compose-northbound.yaml
${nb_of_users}    ${1}
@{containers}=    oai-amf   oai-smf   oai-gnb   oai-nrf  oai-ausf   mysql   oai-ext-dn  vpp-upf  oai-udr   oai-udm


*** Test Cases ***
Check AMF Registration Notifications
    [tags]  North
    [Documentation]    Check MongoDB Status, Start the handler and wait for it to initialize, check Callback registration notification
    Check Mongo Status
    Handler.start_handler
    Sleep    10s
    FOR    ${user}    IN RANGE    ${nb_of_users}
         RFsim.Add UEs    ${1}
         Sleep    15s
    END
    NotifTest.check_imsi_match    ${DOCKER_YAML_PATH}    ${nb_of_users}

Check SMF Notifications: 
     [tags]  North
     ${logs} =    Get UE Info From SMF Log
     NotifTest.check_smf_logs_and_callback_notification    '${logs}'

Check AMF Deregistration Notification
    [tags]  North
    [Documentation]    Remove all UEs added during the test and check their DEREGISTRATION Notifications
    FOR    ${user}    IN RANGE    ${nb_of_users}
         RFsim.Remove UEs    ${1}
    END
    Sleep    15s
    NotifTest.check_latest_deregistered_imsis    ${DOCKER_YAML_PATH}    ${nb_of_users}
    Handler.stop_handler

*** Keywords ***
Launch northbound CN
     FOR     ${container}   IN    @{containers} 
     common.start_docker_compose    ${DOCKER_YAML_PATH}    ${container}     
     END
     Wait Until Keyword Succeeds  60s  1s    NotifTest.check_health_status    ${DOCKER_YAML_PATH}

Down northbound CN    
     Common.down_docker_compose    ${DOCKER_YAML_PATH}
     #Handler.stop_handler

Check Mongo Status 
    ${result}    Run    systemctl is-active mongod
    Should Not Contain    ${result}    inactive
    Run Keyword If    '${result}' == 'active'    Log    MongoDB is active
    ...    ELSE    Log    MongoDB is not active

Get UE Info From SMF Log
     ${logs}    Run    docker logs oai-smf | sed -n '/SMF CONTEXT:/,/^[[:space:]]*$/p' 
     RETURN    ${logs}

