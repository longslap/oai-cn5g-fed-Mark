#!/usr/bin/env python3
"""
Licensed to the OpenAirInterface (OAI) Software Alliance under one or more
contributor license agreements.  See the NOTICE file distributed with
this work for additional information regarding copyright ownership.
The OpenAirInterface Software Alliance licenses this file to You under
the OAI Public License, Version 1.1  (the "License"); you may not use this file
except in compliance with the License.
You may obtain a copy of the License at

  http://www.openairinterface.org/?page_id=698

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
------------------------------------------------------------------------------
For more information about the OpenAirInterface (OAI) Software Alliance:
  contact@openairinterface.org
---------------------------------------------------------------------
"""

import argparse
import logging
import os
import re
import sys
import common.python.cls_cmd as cls_cmd

from common.python.generate_html import (
    generate_header,
    generate_footer,
    generate_chapter,
    generate_button_header,
    generate_button_footer,
    generate_image_table_header,
    generate_image_table_footer,
    generate_image_table_row,
    generate_list_header,
    generate_list_footer,
    generate_list_row,
    generate_nav_pills_list_header,
    generate_nav_pills_list_footer,
    generate_nav_pills_list_item,
    generate_tab_content_header,
    generate_tab_content_footer,
)

REPORT_NAME = 'test_results_oai_cn5g_cots_ue.html'

logging.basicConfig(
    level=logging.DEBUG,
    stream=sys.stdout,
    format="[%(asctime)s] %(levelname)8s: %(message)s"
)

def _parse_args() -> argparse.Namespace:
    """Parse the command line args

    Returns:
        argparse.Namespace: the created parser
    """
    example_text = '''example:
        ./ci-scripts/checkCOTS-UE-Testing.py --help
        ./ci-scripts/checkCOTS-UE-Testing.py --job_name NameOfPipeline --job_id BuildNumber --job_url BuildURL'''

    parser = argparse.ArgumentParser(description='OAI 5G CORE NETWORK COTS-UE-Test-Checker',
                                    epilog=example_text,
                                    formatter_class=argparse.RawDescriptionHelpFormatter)

    # Job Name
    parser.add_argument(
        '--job_name', '-n',
        action='store',
        help='Pipeline is called JOB_NAME',
    )

    # Job Build Id
    parser.add_argument(
        '--job_id', '-id',
        action='store',
        help='Build # JOB_ID',
    )

    # Job URL
    parser.add_argument(
        '--job_url', '-u',
        action='store',
        help='Pipeline provides an URL for this run',
    )

    # Optional Options to indicate that some stages failed
    # By default, they mean the stage passed
    parser.add_argument(
        '--core_deploy_failed',
        action='store_true',
        default=False,
        help='If True, the Core Network deployment failed',
    )
    parser.add_argument(
        '--gnb_deploy_failed',
        action='store_true',
        default=False,
        help='If True, the OAI gNB deployment failed',
    )
    parser.add_argument(
        '--ue_test0_start_failed',
        action='store_true',
        default=False,
        help='If True, the first UE start test failed',
    )
    parser.add_argument(
        '--ue_test0_stop_failed',
        action='store_true',
        default=False,
        help='If True, the first UE stop test failed',
    )
    parser.add_argument(
        '--ue_test1_start_failed',
        action='store_true',
        default=False,
        help='If True, the second UE start test failed',
    )
    parser.add_argument(
        '--ue_test1_stop_failed',
        action='store_true',
        default=False,
        help='If True, the second UE stop test failed',
    )

    return parser.parse_args()

def nfDetails(nfName):
    cwd = os.getcwd()
    contName = ''
    fullTag = ''
    ocTag = ''
    creationDate = ''
    size = ''
    # File should be always be there. Just being cautious
    if not os.path.isfile(os.path.join(cwd, 'archives/describe-pods.logs')):
        return generate_image_table_row(nfName, 'Not Found', 'Not Found', 'could not open archives/describe-pods.logs', 'N/A')

    with open(os.path.join(cwd, 'archives/describe-pods.logs'), 'r') as podLogs:
        for line in podLogs:
            result = re.search('^Name: *(?P<contName>' + nfName + '[a-zA-Z0-9\-]+)', line)
            if result is not None:
                contName = result.group('contName')
            if nfName == 'mysql':
                result = re.search('Image: *(?P<imageName>docker.io/' + nfName + '[a-zA-Z0-9\-\:]+)', line)
                if result is not None:
                    fullTag = result.group('imageName')

    if nfName == 'mysql':
        notApplicable = 'N/A'
        return generate_image_table_row(contName, fullTag, notApplicable, notApplicable, notApplicable)

    if nfName == 'oai-gnb':
        contName = 'sa-b210-gnb'
        ocTag = 'N/A'

    # File should be there also. But being cautious again.
    if not os.path.isfile(os.path.join(cwd, f'archives/{nfName}-image-info.log')):
        return generate_image_table_row(contName, 'Not Found', 'Not Found', f'could not open archives/{nfName}-image-info.log', 'N/A')
    with open(os.path.join(cwd, f'archives/{nfName}-image-info.log'), 'r') as podImageLog:
        for line in podImageLog:
            result = re.search('Tested Tag is (?P<imageName>' + nfName + '[a-zA-Z0-9\.\-\:]+)', line)
            if result is not None:
                fullTag = result.group('imageName')
            result = re.search('OC Pushed Tag is (?P<ocName>' + nfName + '[a-zA-Z0-9\.\-\:]+)', line)
            if result is not None:
                ocTag = result.group('ocName')
            result = re.search('Tested Tag is (?P<imageName>[a-zA-Z0-9\.\/]+' + nfName + '[a-zA-Z0-9\-\:\.\_]+)', line)
            if result is not None:
                fullTag = result.group('imageName')
            result = re.search('Size = (?P<imageSize>[0-9]+) bytes', line)
            if result is not None:
                sizeInt = int(result.group('imageSize'))
                if sizeInt > 1000000000:
                    size = f'{(sizeInt/1000000000):.3f} Gbytes'
                else:
                    size = f'{(sizeInt/1000000):.1f} Mbytes'
            result = re.search('Image Size:\\t*(?P<imageSize>[0-9\.]+)MB', line)
            if result is not None:
                sizeInt = float(result.group('imageSize')) * 2.6
                size = f'{sizeInt:.1f} Mbytes'
            result = re.search('Date = (?P<imageDate>[0-9\-]+ [0-9\:]+)', line)
            if result is not None:
                creationDate = result.group('imageDate')
            result = re.search('Date = (?P<imageDate>[0-9\-]+T[0-9\:]+)', line)
            if result is not None:
                creationDate = re.sub('T', ' ', result.group('imageDate'))
            result = re.search('"(?P<imageDate>[0-9\-]+T[0-9\:]+)Z"', line)
            if result is not None:
                creationDate = re.sub('T', ' ', result.group('imageDate'))

    return generate_image_table_row(contName, fullTag, ocTag, creationDate, size)

def nrRegistrationCheck(nfName):
    cwd = os.getcwd()
    ipAddr = ''
    if not os.path.isfile(os.path.join(cwd, f'archives/{nfName}-nf-registration.log')):
        return generate_list_row(f'could not open archives/{nfName}-nf-registration.log', 'question-sign')
    # We should have one line if successful
    with open(os.path.join(cwd, f'archives/{nfName}-nf-registration.log'), 'r') as nfRegLog:
        for line in nfRegLog:
            ipAddr = line.strip()
    if ipAddr == '':
        message = f'oai-{nfName} network function did NOT register properly to NRF'
        iconName = 'remove-sign'
    else:
        message = f'oai-{nfName} network function did register properly to NRF with IP address: {ipAddr}'
        iconName = 'check'
    return generate_list_row(message, iconName)

def upfPfcpCheck():
    cwd = os.getcwd()
    count = 0
    if not os.path.isfile(os.path.join(cwd, f'archives/upf_pcfp_heartbeat.log')):
        return generate_list_row(f'could not open archives/upf_pcfp_heartbeat.log', 'question-sign')
    with open(os.path.join(cwd, f'archives/upf_pcfp_heartbeat.log'), 'r') as pfcpLog:
        for line in pfcpLog:
           if re.search('Received SX HEARTBEAT REQUEST', line) is not None:
               count += 1
           if re.search('handle_receive', line) is not None:
               count += 1
    if (count > 0):
        message = 'UPF seems PFCP-associated with SMF'
        iconName = 'check'
    else:
        message = 'UPF was NOT properly PFCP-associated with SMF'
        iconName = 'remove-sign'
    return generate_list_row(message, iconName)

def detailsCoreDeployment():
    status = True
    detailsHtml = generate_button_header('cn5g-details', 'Details on the OAI CN5G Deployment')
    detailsHtml += generate_image_table_header()
    coreElements = ['mysql', 'oai-nrf', 'oai-amf', 'oai-smf', 'oai-upf', 'oai-ausf', 'oai-udm', 'oai-udr']
    for element in coreElements:
        imageStatus = nfDetails(element)
        detailsHtml += imageStatus
        if re.search('could not open', imageStatus) is not None:
            status = False
    detailsHtml += generate_image_table_footer()
    detailsHtml += generate_list_header()
    coreElements = ['amf', 'smf', 'upf']
    for element in coreElements:
        registration = nrRegistrationCheck(element)
        detailsHtml += registration
        if re.search('could not open', registration) is not None or re.search('NOT', registration):
            status = False
    pfcpCheck = upfPfcpCheck()
    detailsHtml += pfcpCheck
    if re.search('could not open', pfcpCheck) is not None or re.search('NOT', pfcpCheck):
        status = False
    detailsHtml += generate_list_row('For more details look at NF logs and archives/describe-pods.logs', 'info-sign')
    detailsHtml += generate_list_footer()
    detailsHtml += generate_button_footer()
    return (status, detailsHtml)

def detailsCoreUndeployment():
    cwd = os.getcwd()
    status = True
    detailsHtml = generate_button_header('cn5g-undeploy-details', 'Details on the OAI CN5G Undeployment')
    detailsHtml += generate_list_header()
    coreElements = ['oai-nrf', 'oai-amf', 'oai-smf', 'oai-upf', 'oai-ausf', 'oai-udm', 'oai-udr']
    for element in coreElements:
        byeMessagePresent = False
        if not os.path.isfile(f'{cwd}/archives/{element}.logs'):
            detailsHtml += generate_list_row(f'{element} has NO LOGS', 'remove-sign')
            status = False
            continue
        with open(f'{cwd}/archives/{element}.logs', mode='r', errors='ignore') as nfRuntimeLogFile:
            for line in nfRuntimeLogFile:
                result = re.search('system.*info.* Bye. Shutdown Procedure took (?P<duration>[0-9]+) ms', line)
                if result is not None:
                    byeMessagePresent = True
                    duration = int(result.group('duration'))
                    detailsHtml += generate_list_row(f'{element} has the bye message -- Shutdown took {duration} ms', 'info-sign')
        if not byeMessagePresent:
            detailsHtml += generate_list_row(f'{element} has NO Bye message', 'remove-sign')
            status = False
    detailsHtml += generate_list_footer()
    detailsHtml += generate_button_footer()
    return (status, detailsHtml)

def checkAMFconnection(folder_name):
    cwd = os.getcwd()
    count = 0
    if not os.path.isfile(os.path.join(cwd, f'archives/{folder_name}/oai-gnb.logs')):
        return generate_list_row(f'could not open archives/{folder_name}/oai-gnb.logs', 'question-sign')
    with open(os.path.join(cwd, f'archives/{folder_name}/oai-gnb.logs'), 'r') as gnbLogs:
        for line in gnbLogs:
           if re.search('Received NGAP_REGISTER_GNB_CNF: associated AMF 1', line) is not None:
               count += 1
    if (count > 0):
        message = 'gNB associated with AMF'
        iconName = 'check'
    else:
        message = 'gNB did NOT associate with AMF'
        iconName = 'remove-sign'
    return generate_list_row(message, iconName)

def detailsOaiGNBDeployment(folder_name, idx):
    status = True
    detailsHtml = generate_button_header(f'ran-details-{idx}', 'Details on the OAI RAN gNB Deployment')
    detailsHtml += generate_image_table_header()
    imageStatus = nfDetails('oai-gnb')
    detailsHtml += imageStatus
    if re.search('could not open', imageStatus) is not None:
        status = False
    detailsHtml += generate_image_table_footer()
    detailsHtml += generate_list_header()
    amfConnection = checkAMFconnection(folder_name)
    detailsHtml += amfConnection
    if re.search('could not open', amfConnection) is not None or re.search('NOT', amfConnection) is not None:
        status = False
    detailsHtml += generate_list_row(f'For more details look at archives/{folder_name}/oai-gnb.logs', 'info-sign')
    detailsHtml += generate_list_footer()
    detailsHtml += generate_button_footer()
    return (status, detailsHtml)

def detailsOaiGNBUndeployment(folder_name, idx):
    status = True
    detailsHtml = generate_button_header(f'ram-stop-details-{idx}', 'Details on the OAI RAN gNB Undeployment')
    cwd = os.getcwd()
    bye_count = 0
    assertion_count = 0
    if not os.path.isfile(os.path.join(cwd, f'archives/{folder_name}/oai-gnb.logs')):
        return generate_list_row(f'could not open archives/{folder_name}/oai-gnb.logs', 'question-sign')
    with open(os.path.join(cwd, f'archives/{folder_name}/oai-gnb.logs'), 'r') as gnbLogs:
        for line in gnbLogs:
           if re.search('Bye', line) is not None:
               bye_count += 1
           if re.search('Assertion', line) is not None:
               assertion_count += 1
    if (bye_count > 0) and (assertion_count == 0):
        message = 'Bye message appeared. No issue'
        iconName = 'check'
    elif (bye_count == 0) and (assertion_count > 0):
        message = 'Assertion occured'
        iconName = 'remove-sign'
        status = False
    else:
        message = 'No Bye message. No Assertion'
        iconName = 'question-mark'
        status = False
    detailsHtml += generate_list_header()
    detailsHtml += generate_list_row(message, iconName)
    detailsHtml += generate_list_row(f'For more details look at archives/{folder_name}/oai-gnb.logs', 'info-sign')
    detailsHtml += generate_list_footer()
    detailsHtml += generate_button_footer()
    return (status, detailsHtml)

def detailsUeStartTest(folder_name, runNb):
    status = False
    detailsHtml = generate_button_header(f'ue-start{runNb}-details', f'Details on the UE start test #{runNb}')
    detailsHtml += generate_list_header()
    cwd = os.getcwd()
    if not os.path.isfile(os.path.join(cwd, f'archives/{folder_name}/test-start{runNb}.log')):
        detailsHtml += generate_list_row(f'could not open archives/{folder_name}/test-start{runNb}.log', 'question-sign')
        detailsHtml += generate_list_footer()
        detailsHtml += generate_button_footer()
        return (status, detailsHtml)
    pingStatus = [False, False]
    pingIdx = 0
    with open(os.path.join(cwd, f'archives/{folder_name}/test-start{runNb}.log'), 'r') as testRunLog:
        for line in testRunLog:
            if re.search('PING 8\.8\.8\.8 \(8\.8\.8\.8\) from 12\.1\.1\.', line) is not None:
                detailsHtml += generate_list_row(line.strip(), 'info-sign')
            if re.search('PING 8\.8\.8\.8 \(8\.8\.8\.8\) from 12\.2\.1\.', line) is not None:
                detailsHtml += generate_list_row(line.strip(), 'info-sign')
            stats = re.search('(?P<nbTrans>[0-9]+) packets transmitted, (?P<nbRec>[0-9]+) received, (?P<packetLoss>[0-9\.]+)% packet loss', line)
            if stats is not None:
                if ((int(stats.group('nbTrans')) == int(stats.group('nbRec'))) and (float(stats.group('packetLoss')) == 0)):
                    detailsHtml += generate_list_row(line.strip(), 'check')
                    pingStatus[pingIdx] = True
                else:
                    detailsHtml += generate_list_row(line.strip(), 'remove-sign')
                pingIdx += 1
            if re.search('rtt min', line) is not None:
                detailsHtml += generate_list_row(line.strip(), 'info-sign')
    if pingStatus[0] and pingStatus[1]:
        status = True
    detailsHtml += generate_list_row(f'More details in archives/{folder_name}/test-start{runNb}.log', 'info-sign')
    detailsHtml += generate_list_footer()
    detailsHtml += generate_button_footer()
    return (status, detailsHtml)

def detailsUeStopTest(folder_name, runNb):
    detailsHtml = generate_button_header(f'ue-stop{runNb}-details', f'Details on the UE stop test #{runNb}')
    detailsHtml += generate_list_header()
    cwd = os.getcwd()
    if not os.path.isfile(os.path.join(cwd, f'archives/{folder_name}/test-stop{runNb}.log')):
        detailsHtml += generate_list_row(f'could not open archives/{folder_name}/test-stop{runNb}.log', 'question-sign')
        detailsHtml += generate_list_footer()
        detailsHtml += generate_button_footer()
        return (False, detailsHtml)
    status = True
    previousCmd = ''
    errorIssues = ''
    with open(os.path.join(cwd, f'archives/{folder_name}/test-stop{runNb}.log'), 'r') as testRunLog:
        for line in testRunLog:
            if re.search('^---- ', line) is not None:
                previousCmd = re.sub('^---- ', '', line.strip())
            if re.search('error: operation failed:', line) is not None:
                status = False
                errorIssues += generate_list_row(f'This command returned an error: <pre><b>{previousCmd}</b></pre>', 'fire')
                errorIssues += generate_list_row(line.strip(), 'remove-sign')
    detailsHtml += errorIssues
    detailsHtml += generate_list_row(f'More details in archives/{folder_name}/test-stop{runNb}.log', 'info-sign')
    detailsHtml += generate_list_footer()
    detailsHtml += generate_button_footer()
    return (status, detailsHtml)

def detailsUeTrafficTest(folder_name, runNb):
    detailsHtml = generate_button_header(f'ue-traffic{runNb}-details', f'Details on the UE traffic test #{runNb}')
    detailsHtml += generate_list_header()
    cwd = os.getcwd()
    if not os.path.isfile(os.path.join(cwd, f'archives/{folder_name}/test-traffic{runNb}.log')) or not os.path.isfile(os.path.join(cwd, f'archives/{folder_name}/test-oai_final_logo.png')):
        detailsHtml += generate_list_row(f'could not open archives/{folder_name}/test-traffic{runNb}.log', 'question-sign')
        detailsHtml += generate_list_footer()
        detailsHtml += generate_button_footer()
        return (False, detailsHtml)
    status = True
    # Checking the trace route message
    cnt = 0
    oai_org_final_destination = ''
    with open(os.path.join(cwd, f'archives/{folder_name}/test-traffic{runNb}.log'), 'r') as testRunLog:
        for line in testRunLog:
            if re.search('12.1.1.1', line) is not None:
                cnt += 1
                detailsHtml += generate_list_row(line, 'forward')
            if re.search('oaiocp-gw.oai.cs.eurecom.fr', line) is not None:
                cnt += 1
                detailsHtml += generate_list_row(line, 'forward')
            if re.search('eurecom-gw.eurecom.fr', line) is not None:
                cnt += 1
                detailsHtml += generate_list_row(line, 'forward')
            if re.search('openairinterface.org', line) is not None and cnt > 0:
                cnt += 1
                detailsHtml += generate_list_row(line, 'forward')
            # internet is using a cache?
            elif oai_org_final_destination != '' and re.search(oai_org_final_destination, line) is not None:
                cnt += 1
                detailsHtml += generate_list_row(line, 'forward')
            if re.search('traceroute to openairinterface.org', line) is not None:
                cnt += 1
                detailsHtml += generate_list_row(line, 'info-sign')
                res = re.search('traceroute to openairinterface.org \((?P<ip_address>[0-9\.]+)\),', line)
                if res is not None:
                    oai_org_final_destination = res.group('ip_address')
    if cnt != 4:
        detailsHtml += generate_list_row(f'TraceRoute did NOT complete {cnt}', 'question-sign')
        status = False
    else:
        detailsHtml += generate_list_row('TraceRoute was complete', 'thumbs-up')
    # Checking the OAI logo image
    myCmds = cls_cmd.LocalCmd()
    res = myCmds.run(f'file {cwd}/archives/{folder_name}/test-oai_final_logo.png', silent=True)
    if res.returncode != 0:
        status = False
    htmlMessage = re.sub(f'{cwd}/archives/{folder_name}/test-oai_final_logo.png', f'archives/{folder_name}/test-oai_final_logo.png', res.stdout)
    if re.search('PNG image data, 800 x 267, 8-bit/color RGBA, non-interlaced', res.stdout) is None:
        detailsHtml += generate_list_row(htmlMessage, 'thumbs-down')
        status = False
    else:
        detailsHtml += generate_list_row(htmlMessage, 'thumbs-up')
    myCmds.close()
    detailsHtml += generate_list_footer()
    detailsHtml += generate_button_footer()
    return (status, detailsHtml)

if __name__ == '__main__':
    # Parse the arguments
    args = _parse_args()

    # Parse logs for details
    (coreStatus, coreDetails) = detailsCoreDeployment()
    if coreStatus and not args.core_deploy_failed:
        coreStatus = True
    else:
        coreStatus = False
    # Initial 2 PDU Sessions Test
    (ranStatus, ranDetails) = detailsOaiGNBDeployment('initial-2-pdu-session-test', 0)
    if ranStatus and not args.gnb_deploy_failed:
        ranStatus = True
    else:
        ranStatus = False
    (ueStart0Status, ueStartTest0) = detailsUeStartTest('initial-2-pdu-session-test', 0)
    if ueStart0Status and not args.ue_test0_start_failed:
        ueStart0Status = True
    else:
        ueStart0Status = False
    (ueTraffic0Status, ueTrafficTest0) = detailsUeTrafficTest('initial-2-pdu-session-test', 0)
    (ueStop0Status, ueStopTest0) = detailsUeStopTest('initial-2-pdu-session-test', 0)
    if ueStop0Status and not args.ue_test0_stop_failed:
        ueStop0Status = True
    else:
        ueStop0Status = False
    (ueStart1Status, ueStartTest1) = detailsUeStartTest('initial-2-pdu-session-test', 1)
    if ueStart1Status and not args.ue_test1_start_failed:
        ueStart1Status = True
    else:
        ueStart1Status = False
    (ueStop1Status, ueStopTest1) = detailsUeStopTest('initial-2-pdu-session-test', 1)
    if ueStop1Status and not args.ue_test1_stop_failed:
        ueStop1Status = True
    else:
        ueStop1Status = False
    (stopStatus, stopDetails) = detailsOaiGNBUndeployment('initial-2-pdu-session-test', 0)
    if not ranStatus or not ueStart0Status or not ueStop0Status or not ueStart1Status or not ueStop1Status or not stopStatus:
        initial_2_pdu_session_test = False
    else:
        initial_2_pdu_session_test = True
    # Deconnection Test
    (deconnRanStatus0, deconnRanDetails0) = detailsOaiGNBDeployment('deconnection-test-stop0', 1)
    (ueStart2Status, ueStartTest2) = detailsUeStartTest('deconnection-test', 2)
    (deconnRanStatus1, deconnRanDetails1) = detailsOaiGNBDeployment('deconnection-test', 2)
    (deconnPostRestartUEStatus, deconnPostRestartDetails) = detailsUeStartTest('deconnection-test', 3)
    (ueStop2Status, ueStopTest2) = detailsUeStopTest('deconnection-test', 2)
    (deconnStopStatus, deconnStopDetails) = detailsOaiGNBUndeployment('deconnection-test', 1)
    if not deconnRanStatus0 or not ueStart2Status or not deconnRanStatus1 or not deconnPostRestartUEStatus or not ueStop2Status:
        deconnection_test = False
    else:
        deconnection_test = True
    # Out-of-Coverage Test
    (outCoverageRanStatus0, outCoverageRanDetails0) = detailsOaiGNBDeployment('out-of-coverage-test', 4)
    (ueStart4Status, ueStartTest4) = detailsUeStartTest('out-of-coverage-test', 4)
    (ueStart5Status, ueStartTest5) = detailsUeStartTest('out-of-coverage-test', 5)
    (ueStop4Status, ueStopTest4) = detailsUeStopTest('out-of-coverage-test', 4)
    (outCoverageStopStatus, outCoverageStopDetails) = detailsOaiGNBUndeployment('out-of-coverage-test', 4)
    if not outCoverageRanStatus0 or not ueStart4Status or not ueStart5Status or not ueStop4Status or not outCoverageStopStatus:
        out_of_coverage_test = False
    else:
        out_of_coverage_test = True
    # Core Undeployment
    (undeployStatus, undeployDetails) = detailsCoreUndeployment()

    cwd = os.getcwd()
    with open(os.path.join(cwd, REPORT_NAME), 'w') as wfile:
        wfile.write(generate_header(args))
        wfile.write(generate_nav_pills_list_header())
        wfile.write(generate_nav_pills_list_item('OAI-CN5G Deployment', 'oai-cn5g-deployment', 'log-in', active=True, status=coreStatus))
        wfile.write(generate_nav_pills_list_item('Initial 2 PDU sessions Test', 'init-2-pdu-sessions-test', 'tasks', status=initial_2_pdu_session_test))
        wfile.write(generate_nav_pills_list_item('Deconnection Test', 'deconnection-test', 'repeat', status=deconnection_test))
        wfile.write(generate_nav_pills_list_item('Out-of-Coverage Test', 'out-of-coverage-test', 'new-window', status=out_of_coverage_test))
        wfile.write(generate_nav_pills_list_item('OAI-CN5G Undeployment', 'oai-cn5g-undeployment', 'log-out'))
        wfile.write(generate_nav_pills_list_footer())
        wfile.write(generate_tab_content_header('oai-cn5g-deployment', active=True))
        wfile.write(generate_chapter('OAI-CN5G Deployment', 'Status for the deployment', coreStatus))
        wfile.write(coreDetails)
        wfile.write(generate_tab_content_footer())
        wfile.write(generate_tab_content_header('init-2-pdu-sessions-test'))
        wfile.write(generate_chapter('OAI-gNB Deployment #0', 'Status for the deployment', ranStatus))
        wfile.write(ranDetails)
        wfile.write(generate_chapter('COTS-UE Connection #0', 'Registration / PDU session establishment / Ping Traffic status', ueStart0Status))
        wfile.write(ueStartTest0)
        wfile.write(generate_chapter('COTS-UE Traffic Test #0', 'Traceroute / Curl', ueTraffic0Status))
        wfile.write(ueTrafficTest0)
        wfile.write(generate_chapter('COTS-UE Deconnection #0', 'PDU Session release / Deregistration', ueStop0Status))
        wfile.write(ueStopTest0)
        wfile.write(generate_chapter('COTS-UE Connection #1', 'Registration / PDU session establishment / Ping Traffic status', ueStart1Status))
        wfile.write(ueStartTest1)
        wfile.write(generate_chapter('COTS-UE Deconnection #1', 'PDU Session release / Deregistration', ueStop1Status))
        wfile.write(ueStopTest1)
        wfile.write(generate_chapter('OAI-gNB Un-deployment #0', 'Status for the un-deployment', stopStatus))
        wfile.write(stopDetails)
        wfile.write(generate_tab_content_footer())
        wfile.write(generate_tab_content_header('deconnection-test'))
        wfile.write(generate_chapter('OAI-gNB Deployment #1', 'Status for the deployment', deconnRanStatus0))
        wfile.write(deconnRanDetails0)
        wfile.write(generate_chapter('COTS-UE Connection #2', 'Registration / PDU session establishment / Ping Traffic status', ueStart2Status))
        wfile.write(ueStartTest2)
        wfile.write(generate_chapter('OAI-gNB Deployment #1', 'Status for the restart', deconnRanStatus1))
        wfile.write(deconnRanDetails1)
        wfile.write(generate_chapter('COTS-UE Connection #2', 'Ping Traffic status post gNB Restart', deconnPostRestartUEStatus))
        wfile.write(deconnPostRestartDetails)
        wfile.write(generate_chapter('COTS-UE Deconnection #2', 'PDU Session release / Deregistration', ueStop2Status))
        wfile.write(ueStopTest2)
        wfile.write(generate_chapter('OAI-gNB Un-deployment #1', 'Status for the un-deployment', deconnStopStatus))
        wfile.write(deconnStopDetails)
        wfile.write(generate_tab_content_footer())
        wfile.write(generate_tab_content_header('out-of-coverage-test'))
        wfile.write(generate_chapter('OAI-gNB Deployment #2', 'Status for the deployment', outCoverageRanStatus0))
        wfile.write(outCoverageRanDetails0)
        wfile.write(generate_chapter('COTS-UE Connection #3', 'Registration / PDU session establishment / Ping Traffic status', ueStart4Status))
        wfile.write(ueStartTest4)
        wfile.write(generate_chapter('COTS-UE Connection #3', 'Ping Traffic status post out-of-coverage', ueStart5Status))
        wfile.write(ueStartTest5)
        wfile.write(generate_chapter('COTS-UE Deconnection #4', 'PDU Session release / Deregistration', ueStop4Status))
        wfile.write(ueStopTest4)
        wfile.write(generate_chapter('OAI-gNB Un-deployment #2', 'Status for the un-deployment', outCoverageStopStatus))
        wfile.write(outCoverageStopDetails)
        wfile.write(generate_tab_content_footer())
        wfile.write(generate_tab_content_header('oai-cn5g-undeployment'))
        wfile.write(generate_chapter('Shutdown Analysis', 'Status for undeployment', undeployStatus))
        wfile.write(undeployDetails)
        wfile.write(generate_tab_content_footer(final=True))
        wfile.write(generate_footer())
    if not coreStatus or not initial_2_pdu_session_test or not deconnection_test or not out_of_coverage_test:
        sys.exit(1)
    sys.exit(0)
