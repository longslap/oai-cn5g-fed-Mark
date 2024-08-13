*** Settings ***
Library    OperatingSystem
Library    RfSimLib.py
Library    NotificationTest.py    WITH NAME    NotifTest
Library    5gcsdk/src/main/init_handler.py    WITH NAME    Handler

Resource   common.robot

Variables    vars.py

Suite Setup    Launch Northbound Test CN
Suite Teardown    Suite Teardown Default

#Test Setup    Test Setup For Northbound
#Test Teardown    Test Teardown With RAN


*** Test Cases ***
Check AMF Registration Notifications
    [tags]  North   AMF
    [Setup]    Test Setup For Northbound
    [Teardown]    None
    [Documentation]    Check Callback registration notification
    @{UEs}=    Get UE container Names
    FOR   ${ue}   IN    @{UEs}   
        Start NR UE    ${ue}
        Sleep  2s
    END    

    # Start All NR UE
    Wait Until Keyword Succeeds  60s  1s  Check RAN Elements Health Status
    ${logs} =    Get AMF Report Logs
    Wait Until Keyword Succeeds  60s  6s    Check AMF Reg Callback    ${3}    ${logs}

Check AMF Location Report  
    [tags]  North   AMF
    [Setup]    None
    [Teardown]    None  
    [Documentation]    Check Callback Location Notification
    ${logs} =    Get AMF Location Report Logs
    Wait Until Keyword Succeeds  60s  6s    Check AMF Location Report Callback    '${logs}'    ${3}

Check SMF Notifications
    [tags]  North   SMF
    [Setup]    None
    [Teardown]    None
    [Documentation]    Check SMF Callback Notification (PDU Session Establishment)
    ${logs} =    Get UE Info From SMF Log
    Wait Until Keyword Succeeds  60s  6s    Check SMF Callback    '${logs}'    ${3}

Check Traffic Notification
    [tags]   North   SMF
    [Setup]    None
    [Teardown]    None
    [Documentation]    Check SMF Traffic Notification Callback
    @{UEs}=    Get UE container Names
    Start Iperf3 Server     ${EXT_DN1_NAME}
    Sleep    10s
    FOR     ${ue}   IN    @{UEs}   
        ${ip}=   Get UE IP Address   ${ue}
        ${imsi}=   Get UE IMSI    ${ue}
        Start Iperf3 Client     ${ue}  ${ip}  ${EXT_DN1_IP_N3}  bandwidth=3
        Wait and Verify Iperf3 Result    ${ue}  ${3}  #for bandwidth check, not important
        Sleep   6s
        ${result}=    Get Iperf3 Results   ${ue}
        Check Ue Traffic Notification  ${result}  ${imsi}
    END

Check AMF Deregistration Notification
    [tags]  North   AMF
    [Setup]    Test Setup for Deregistration
    [Teardown]    Test Teardown With RAN
    [Documentation]    Remove all UEs added during the test and check their DEREGISTRATION Notifications
    ${logs} =    Get AMF Report Logs
    Wait Until Keyword Succeeds  60s  6s    Check AMF Dereg Callback    ${logs}    ${3}
    

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

Get AMF Report Logs
    ${logs}    Run    docker logs oai-amf | sed -n '/--UEs. Information--/,/----------------------------/p' 
    RETURN    ${logs}

Get AMF Location Report Logs
    ${logs}    Run    docker logs oai-amf | sed -n '/"type":"LOCATION_REPORT"/p' 
    RETURN    ${logs}



