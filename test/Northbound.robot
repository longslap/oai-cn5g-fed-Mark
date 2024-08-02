*** Settings ***
Library    Process
Library    CNTestLib.py
Resource   common.robot

Variables    vars.py

#Suite Setup    Launch Northbound Test CN
#Suite Teardown    Suite Teardown Default

*** Test Cases ***
Sleep Test
    [tags]  SLP
    Launch RfSim For Northbound
    Sleep     6s