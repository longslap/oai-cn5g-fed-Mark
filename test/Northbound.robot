*** Settings ***
Library    OperatingSystem
Library    RfSimLib.py
Library    NotificationTest.py    WITH NAME    NotifTest
Library    5gcsdk/src/main/init_handler.py    WITH NAME    Handler

Resource   common.robot

Variables    vars.py

Suite Setup    Launch Northbound Test CN
Suite Teardown    Suite Teardown Default

Test Setup    Test Setup For Northbound
Test Teardown    Test Teardown With RAN


*** Test Cases ***
Check AMF Registration Notifications
    [tags]  North   AMF
    [Setup]    Test Setup For Northbound
    [Teardown]    None
    [Documentation]    Check Callback registration notification
    Start All NR UE
    Wait Until Keyword Succeeds  60s  6s    Check AMF Reg Callback    ${3}
    #Sleep    30s

Check SMF Notifications
    [tags]  North   SMF
    [Setup]    None
    [Teardown]    None
    ${logs} =    Get UE Info From SMF Log
    Wait Until Keyword Succeeds  60s  6s    Check SMF Callback    '${logs}'    ${3}
    #Sleep    30s

Check AMF Deregistration Notification
    [tags]  North   AMF
    [Setup]    Test Setup for Deregistration
    [Teardown]    Test Teardown With RAN
    [Documentation]    Remove all UEs added during the test and check their DEREGISTRATION Notifications
    Wait Until Keyword Succeeds  60s  6s    Check AMF Dereg Callback    ${3}
    #Sleep   10s
    


*** Keywords ***
Launch Mongo
     Run    docker run -d -p 27017:27017 --name=mongo-northbound mongo:latest

Down Mongo   
     Run    docker stop mongo-northbound
     Run    docker rm mongo-northbound

Get UE Info From SMF Log
     ${logs}    Run    docker logs oai-smf | sed -n '/SMF CONTEXT:/,/^[[:space:]]*$/p' 
     RETURN    ${logs}

Test Setup For Northbound
    Launch Mongo
    Handler.Start Handler
    Sleep   10s

Test Setup for Deregistration
    Stop NR UE
    Down NR UE

Test Teardown With RAN
    Handler.Stop Handler
    Down Mongo
    Stop gNB
    Collect All RAN Logs
    ${docu}=   Create RAN Docu
    Set Suite Documentation    ${docu}   append=${TRUE}
    Down gNB
