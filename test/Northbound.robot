*** Settings ***
Library    Process
Library    RfSimLib.py
Resource   common.robot

Variables    vars.py

Suite Setup    Launch Northbound Test CN
Suite Teardown    Suite Teardown Default

Test Setup    Test Setup For Northbound
Test Teardown    Test Teardown With RAN


*** Test Cases ***
Sleep Test
    [tags]  North
    Sleep   15s
    Start All NR UE
    Sleep     100s