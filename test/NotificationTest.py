import os
import sys
import logging
from pymongo import MongoClient, errors
import re
from common import *
from docker_api import DockerApi
from image_tags import image_tags
import json


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def mongo_access(service_type: str):
    try:
        logging.getLogger('pymongo').setLevel(logging.INFO)
        client = MongoClient('mongodb://localhost:27017/')
        client.server_info()
        db = client['notification_db']
        if service_type == "amf notifications":
            return db['amf_notifications']
        elif service_type == "smf notifications":
            return db['smf_notifications']
        elif service_type == "smf traffic report":
            return db['smf_notification_traffic']
        elif service_type == "amf location report":
            return db['amf_location_notification']
        else:
            raise ValueError(f"Invalid service type: {service_type}")
    except errors.ServerSelectionTimeoutError:
        logger.error(f"Failed to connect to MongoDB server")
        raise AssertionError("Failed to connect to MongoDB server")
    
    
def check_smf_callback(logs, nb_of_users):
    try:
        smf_collection = mongo_access("smf notifications")
        smf_contexts = re.findall(r'SMF CONTEXT:.*?(?=SMF CONTEXT:|$)', logs, re.DOTALL)
        parsed_log_data = []

        for context in smf_contexts:
            parsed_context = {}
            lines = context.split('\n')
            for line in lines:
                if "SUPI:" in line:
                    parsed_context['SUPI'] = line.split(':')[1].strip()
                if "PDU Session ID:" in line:
                    parsed_context['PDU Session ID'] = line.split(':')[1].strip()
                if "DNN:" in line:
                    parsed_context['DNN'] = line.split(':')[1].strip()
                if "PAA IPv4:" in line:
                    parsed_context['PAA IPv4'] = line.split(':')[1].strip()
                if "PDN type:" in line:
                    parsed_context['PDN type'] = line.split(':')[1].strip()
            parsed_log_data.append(parsed_context)
        if len(parsed_log_data) != nb_of_users:
            raise Exception(f"Number of SMF contexts in logs ({len(parsed_log_data)}) does not match the number of users added ({nb_of_users})")
        callback_data = []

        for document in smf_collection.find():
            for report in document["eventNotifs"]:
                supi = report["supi"]
                pdu_session_id = report["pduSeId"]
                dnn = report["dnn"]
                paa_ipv4 = report["adIpv4Addr"]
                ip_session_type = report["pduSessType"]
                callback_data.append({
                    'SUPI': supi,
                    'PDU Session ID': f"{pdu_session_id}",
                    'DNN': dnn,
                    'PAA IPv4': paa_ipv4,
                    'PDN type': ip_session_type
                })
        if parsed_log_data != []: 
            for log_entry in parsed_log_data:
                match_found = False
                for callback_entry in callback_data:
                    if (log_entry['SUPI'] == callback_entry['SUPI'] and
                        log_entry['PDU Session ID'] == callback_entry['PDU Session ID'] and
                        log_entry['DNN'] == callback_entry['DNN'] and
                        log_entry['PAA IPv4'] == callback_entry['PAA IPv4']):
                        match_found = True
                        break
                if not match_found:
                    logger.error(f"Mismatch found for SUPI: {log_entry['SUPI']}")
                    raise Exception(f"Mismatch found for SUPI: {log_entry['SUPI']}")
                    

            logger.info(f"All SMF contexts match the callback data.{callback_data}")

        else :

            logger.error(f"No SMF contexts found in logs.")
            raise Exception("No SMF contexts found in logs.")

    except Exception as e:
        logger.error(f"An error occurred: {e}")
        raise e
    
          
def amf_report_from_handler(service_type: str):
    try:
        amf_collection = mongo_access(service_type)
        latest_imsi_events = {}
        for document in amf_collection.find():
            for report in document["reportList"]:
                supi = report["supi"]
                rm_state = report["rmInfoList"][0]["rmState"]
                timestamp = report["timeStamp"]
                ran_ue_ngap_id = report.get("ranUeNgapId", "")
                amf_ue_ngap_id = report.get("amfUeNgapId", "")

                if supi.startswith("imsi-"):
                    supi = supi[5:]
                if supi not in latest_imsi_events or timestamp > latest_imsi_events[supi]['timestamp']:
                    latest_imsi_events[supi] = {
                        'rm_state': rm_state,
                        'timestamp': timestamp,
                        'ran_ue_ngap_id': ran_ue_ngap_id,
                        'amf_ue_ngap_id': amf_ue_ngap_id,
                    }
        latest_registered_imsis = [
            {'imsi': imsi, 'details': event}
            for imsi, event in latest_imsi_events.items()
        ]
        return latest_registered_imsis
    except Exception as e:
        logger.error(f"Failed to get IMSIs from handler collection: {e}")
        raise e


def get_location_report_info(service_type: str):
    try:
        amf_collection = mongo_access(service_type)
        latest_location_events = {}
        for document in amf_collection.find():
            for report in document["reportList"]:
                if report["type"] == "LOCATION_REPORT":
                    supi = report["supi"]
                    location_info = report.get("location", {})
                    nr_location = location_info.get("nrLocation", {})
                    global_gnb_id = nr_location.get("globalGnbId", {})
                    gnb_value = global_gnb_id.get("gNbId", {}).get("gNBValue", "")
                    plmn_id = global_gnb_id.get("plmnId", {})
                    mcc = plmn_id.get("mcc", "")
                    mnc = plmn_id.get("mnc", "")
                    nr_cell_id = nr_location.get("ncgi", {}).get("nrCellId", "")
                    tac = nr_location.get("tai", {}).get("tac", "")
                    timestamp = report["timeStamp"]

                    if supi.startswith("imsi-"):
                        supi = supi[5:]
                    if supi not in latest_location_events or timestamp > latest_location_events[supi]['timestamp']:
                        latest_location_events[supi] = {
                            'gnb_value': gnb_value,
                            'plmn_id': f"{mcc}, {mnc}",
                            'nr_cell_id': nr_cell_id,
                            'tac': tac,
                            'timestamp': timestamp
                        }
        latest_location_reports = [
            {'imsi': imsi, 'details': event}
            for imsi, event in latest_location_events.items()
        ]
        return latest_location_reports
    except Exception as e:
        logger.error(f"Failed to get location reports from handler collection: {e}")
        raise e

def parse_location_log_data(log_data):
    log_data = re.sub(r'\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}\] \[amf_sbi\] \[info\] HTTP message Body: ', '', log_data)
    log_entries = log_data.strip().split('\n')
    cleaned_log_entries = [entry.strip().strip('\'') for entry in log_entries]
    parsed_logs = [json.loads(entry) for entry in cleaned_log_entries]
    location_reports = []
    for log in parsed_logs:
        for report in log.get("reportList", []):
            if report.get("type") == "LOCATION_REPORT":
                supi = report.get("supi", "")
                if supi.startswith("imsi-"):
                    supi = supi[5:]
                location_info = report.get("location", {})
                nr_location = location_info.get("nrLocation", {})
                global_gnb_id = nr_location.get("globalGnbId", {})
                gnb_value = global_gnb_id.get("gNbId", {}).get("gNBValue", "")
                plmn_id = global_gnb_id.get("plmnId", {})
                mcc = plmn_id.get("mcc", "")
                mnc = plmn_id.get("mnc", "")
                nr_cell_id = nr_location.get("ncgi", {}).get("nrCellId", "")
                tac = nr_location.get("tai", {}).get("tac", "")
                timestamp = report.get("timeStamp", 0)

                location_reports.append({
                    'imsi': supi,
                    'gnb_value': gnb_value,
                    'plmn_id': f"{mcc}, {mnc}",
                    'nr_cell_id': nr_cell_id,
                    'tac': tac,
                    'timestamp': timestamp
                })
    return location_reports

def check_AMF_reg_callback(nb_of_users, logs):
    try:
        report_from_handler = amf_report_from_handler(service_type="amf notifications")
        report_from_AMF = extract_ue_info_from_AMF_logs(logs, nb_of_users)
        handler_dict = {report['imsi']: report['details'] for report in report_from_handler}

        for report in report_from_AMF:
            imsi = report['IMSI']
            if report['5GMM state'] != '5GMM-REGISTERED':
                logger.error(f"UE {imsi} is {report['5GMM state']}")
                raise Exception(f"UE {imsi} is {report['5GMM state']}")
            else:
                if imsi in handler_dict:
                    handler_details = handler_dict[imsi]
                    if (report['RAN UE NGAP ID'] == str(handler_details['ran_ue_ngap_id']) and
                        report['AMF UE NGAP ID'] == str(handler_details['amf_ue_ngap_id']) and
                        handler_details['rm_state'] == "REGISTERED"):
                        continue
                    else:
                        logger.error(f"{imsi} callback data does not match AMF data.")
                        raise Exception(f"Data mismatch for IMSI {imsi}.")
                else:
                    logger.error(f"UE {imsi} not found in handler collection.")
                    raise Exception(f"UE {imsi} not found in handler collection.")
        logger.info("AMF UE Data match the callback data.")
    except Exception as e:
        logger.error(f"Failed to check latest registered IMSIs: {e}")
        raise e

def check_AMF_dereg_callback(logs,nb_of_users):
    try:
        report_from_handler = amf_report_from_handler(service_type="amf notifications")
        report_from_AMF = extract_ue_info_from_AMF_logs(logs, nb_of_users)    
        handler_dict = {report['imsi']: report['details'] for report in report_from_handler}

        for report in report_from_AMF:
            imsi = report['IMSI']
            if report['5GMM state'] != '5GMM-DEREGISTERED':
                logger.error(f"UE {imsi} is {report['5GMM state']}")
                raise Exception(f"UE {imsi} is {report['5GMM state']}")
            else:
                if imsi in handler_dict:
                    handler_details = handler_dict[imsi]
                    if (report['RAN UE NGAP ID'] == str(handler_details['ran_ue_ngap_id']) and
                        report['AMF UE NGAP ID'] == str(handler_details['amf_ue_ngap_id']) and
                        handler_details['rm_state'] == "DEREGISTERED"):
                        continue
                    else:
                        logger.error(f"{imsi} callback data does not match AMF data.")
                        raise Exception(f"Data mismatch for IMSI {imsi}.")
                else:
                    logger.error(f"UE {imsi} not found in handler collection.")
                    raise Exception(f"UE {imsi} not found in handler collection.")
        logger.info("AMF UE Data match the callback data.")
    except Exception as e:
        logger.error(f"Failed to check latest deregistered IMSIs: {e}")
        raise e

def check_AMF_Location_report_callback(logs, nb_of_users):
    try: 
        if logs == "":
            logger.error("No location reports found in logs.")
            raise Exception("No location reports found in logs.")
        report_from_handler = get_location_report_info(service_type="amf location report")
        report_from_amf = parse_location_log_data(logs)
        handler_dict = {report['imsi']: report['details'] for report in report_from_handler}
        if len(report_from_handler) != nb_of_users:
            logger.error(f"Number of UE Location Reports ({len(report_from_handler)}) does not match the number of users added ({nb_of_users})")
            raise Exception(f"Number of UE Location Reports Callbacks does not match the number of users added.")
        for report in report_from_amf:
            imsi = report['imsi']
            if imsi in handler_dict:
                handler_details = handler_dict[imsi]
                if handler_details['gnb_value'] != report['gnb_value']:
                    logger.error(f"IMSI {imsi} gNB Value mismatch: Handler({handler_details['gnb_value']}) != AMF({report['gnb_value']})")
                    raise Exception(f"Data mismatch for IMSI {imsi}: gNB Value mismatch.")
                if handler_details['plmn_id'] != report['plmn_id']:
                    logger.error(f"IMSI {imsi} PLMN ID mismatch: Handler({handler_details['plmn_id']}) != AMF({report['plmn_id']})")
                    raise Exception(f"Data mismatch for IMSI {imsi}: PLMN ID mismatch.")
                if handler_details['nr_cell_id'] != report['nr_cell_id']:
                    logger.error(f"IMSI {imsi} NR Cell ID mismatch: Handler({handler_details['nr_cell_id']}) != AMF({report['nr_cell_id']})")
                    raise Exception(f"Data mismatch for IMSI {imsi}: NR Cell ID mismatch.")
                if handler_details['tac'] != report['tac']:
                    logger.error(f"IMSI {imsi} TAC mismatch: Handler({handler_details['tac']}) != AMF({report['tac']})")
                    raise Exception(f"Data mismatch for IMSI {imsi}: TAC mismatch.")
                logger.info(f"IMSI {imsi} matches all fields.")
            else:
                logger.error(f"UE {imsi} not found in handler collection.")
                raise Exception(f"UE {imsi} not found in handler collection.")
        
        logger.info("All callback data matches the AMF UEs location Data.")
    except Exception as e:
        logger.error(f"Failed to check latest location reports: {e}")
        raise e


def extract_ue_info_from_AMF_logs(logs, nb_of_users):
    try:
        if not logs.strip():
            raise Exception("No logs found.")
        cleaned_logs = logs.strip()
        ue_info_lines = cleaned_logs.split('\n')
        start_index = None
        end_index = None
        for i, line in enumerate(ue_info_lines):
            if 'UEs\' Information' in line:
                start_index = i + 2 
            elif '|-----------------------------------------------------------------------------------------------------------------------------------------------------------|' in line:
                end_index = i
        if start_index is None or end_index is None:
            raise ValueError("Could not locate UE information table in logs.")
        raw_headers = [header.strip() for header in ue_info_lines[start_index - 1].split('|')[1:-1]]
        ue_info_lines = ue_info_lines[start_index:end_index]
        ue_info_list = []
        for line in ue_info_lines[:nb_of_users]:
            values = [value.strip() for value in line.split('|')[1:-1]]
            ue_info = dict(zip(raw_headers, values))
            ue_info_list.append(ue_info)
        if len(ue_info_list) != nb_of_users:
            raise ValueError(f"Number of UEs in logs ({len(ue_info_list)}) does not match the number of users added ({nb_of_users}).")
        return ue_info_list
    except Exception as e:
        logger.error(f"Failed to extract UE information from logs: {e}")
        raise e