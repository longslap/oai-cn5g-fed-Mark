*** Settings ***
Library    OperatingSystem
Library    NWDAFTestLib.py
Library    /home/foreur/5gcsdk/src/main/init_handler.py          WITH NAME    Handler

Resource   common.robot

Variables    vars.py

Suite Setup       NWDAF Suite Setup
Suite Teardown    NWDAF Suite Teardown

*** Test Cases ***
Check NWDAF Status
    [tags]  NWDAF
    [Setup]    None
    [Teardown]    None
    [Documentation]    Check NWDAF Health Status
    Sleep  10s

*** Keywords ***
NWDAF Suite Setup
    Prepare NWDAF   http_version=2
    Start Basic VPP NRF CN
    Start NWDAF
    Wait Until Keyword Succeeds  60s  6s  Check NWDAF Health Status
    Start gNBSim for NWDAF
    # Handler.Start Handler

NWDAF Suite Teardown
    Stop gNBSim for NWDAF
    Stop NWDAF
    Stop Basic VPP NRF CN
    # Handler.Stop Handler
    Collect CN and NWDAF Logs
    Down Gnbsim For Nwdaf
    Down NWDAF
    Down Basic VPP NRF CN


    


    
