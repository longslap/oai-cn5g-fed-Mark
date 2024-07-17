*** Settings ***
Library    JSONLibrary
Library    5gcsdk/src/modules/RFsimUEManager.py    WITH NAME    RFsim
Library    5gcsdk/src/main/init_handler.py    WITH NAME    Handler
Library    NotificationTest.py     WITH NAME    NotifTest


*** Variables ***
${DOCKER_YAML_PATH}   ../5g_rfsimulator/docker-compose.yaml
${nb_of_users}    ${5}


*** Test Cases ***
Check AMF Registration Notifications
    [Documentation]    Check MongoDB Status, Start the handler and wait for it to initialize, check Callback registration notification
    ${result}    Run    systemctl is-active mongod
    Should Not Contain    ${result}    inactive
    Run Keyword If    '${result}' == 'active'    Log    MongoDB is active
    ...    ELSE    Log    MongoDB is not active
    Handler.start_handler
    Sleep    5s
    FOR    ${user}    IN RANGE    ${nb_of_users}
         RFsim.Add UEs    ${1}
         Sleep    15s
    END
    NotifTest.check_imsi_match    ${DOCKER_YAML_PATH}    ${nb_of_users}

Check SMF Notifications:
     ${logs}    Run    docker logs rfsim5g-oai-smf | sed -n '/SMF CONTEXT:/,/^[[:space:]]*$/p' 
     NotifTest.check_smf_logs_and_callback_notification    '${logs}'

Check AMF Deregistration Notification
    [Documentation]    Remove all UEs added during the test and check their DEREGISTRATION Notifications
    ${result1}    Run    systemctl is-active mongod
    Should Not Contain    ${result1}    inactive
    Run Keyword If    '${result1}' == 'active'    Log    MongoDB is active
    ...    ELSE    Log    MongoDB is not active
    FOR    ${user}    IN RANGE    ${nb_of_users}
         RFsim.Remove UEs    ${1}
    END
    Sleep    15s
    NotifTest.check_latest_deregistered_imsis    ${DOCKER_YAML_PATH}    ${nb_of_users}
    Handler.stop_handler