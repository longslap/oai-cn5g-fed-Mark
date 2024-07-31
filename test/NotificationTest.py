import os
import sys
import logging
import yaml
from pymongo import MongoClient, errors
import importlib
import re
from common import *
from docker_api import DockerApi
from image_tags import image_tags
parent_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, parent_dir)
RFsimUEManager = importlib.import_module('5gcsdk.src.modules.RFsimUEManager')
init_handler = importlib.import_module('5gcsdk.src.main.init_handler')
add_ues = RFsimUEManager.add_ues
remove_ues = RFsimUEManager.remove_ues
start_handler = init_handler.start_handler  
stop_handler = init_handler.stop_handler

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def mongo_access(service_type: str):
    try:
        logging.getLogger('pymongo').setLevel(logging.INFO)
        client = MongoClient('mongodb://localhost:27017/')
        client.server_info()
        db = client['notification_db']
        if service_type == "amf":
            return db['amf_notifications']
        elif service_type == "smf":
            return db['smf_notifications']
        else:
            raise ValueError(f"Invalid service type: {service_type}")
    except errors.ServerSelectionTimeoutError:
        logger.error(f"Failed to connect to MongoDB server")
        raise AssertionError("Failed to connect to MongoDB server")
               
def extract_imsi_from_docker_yaml(docker_yaml_path):
    home_dir = os.path.dirname(os.path.abspath(__file__))
    docker_yaml_path = os.path.normpath(os.path.join(home_dir, '..' ,docker_yaml_path))
    with open(docker_yaml_path, 'r') as file:
        data = yaml.safe_load(file)
    imsis = []
    for service_name, config in data['services'].items():
        if service_name.startswith('oai-nr-ue'):
            environment = config.get('environment', [])
            options = environment['USE_ADDITIONAL_OPTIONS']
            parts = options.split()
            if '--uicc0.imsi' in parts:
                imsi_index = parts.index('--uicc0.imsi') + 1
                if imsi_index < len(parts):
                    imsis.append(parts[imsi_index])
    if imsis:
        return imsis
    else:
        logger.error("No IMSIs found in Docker YAML file")
        raise ValueError("No IMSIs found in Docker YAML file")

def check_smf_logs_and_callback_notification(logs, nb_of_users):
   
    try:
        smf_collection = mongo_access("smf")
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
    
          
def get_imsi_from_handler_collection():
    try:
        amf_collection = mongo_access("amf")
        latest_imsi_events = {}
        for document in amf_collection.find():
            for report in document["reportList"]:
                supi = report["supi"]
                rm_state = report["rmInfoList"][0]["rmState"]
                timestamp = report["timeStamp"]
                if supi.startswith("imsi-"):
                    supi = supi[5:]
                if supi not in latest_imsi_events or timestamp > latest_imsi_events[supi]['timestamp']:
                    latest_imsi_events[supi] = {'rm_state': rm_state, 'timestamp': timestamp}
        latest_registered_imsis = [
            imsi for imsi, event in latest_imsi_events.items()
            if event['rm_state'] == "REGISTERED"]
        return latest_registered_imsis
    except Exception as e:
        logger.error(f"Failed to get IMSIs from handler collection: {e}")
        raise e

def check_imsi_match(docker_yaml_path,nb_of_users):
    imsi_from_yaml = extract_imsi_from_docker_yaml(docker_yaml_path)[:nb_of_users]
    imsi_from_handler = get_imsi_from_handler_collection()
    if set(imsi_from_yaml) == set(imsi_from_handler):
        logger.info("IMSI match successful.")
    else:
        logger.error(f"IMSI mismatch. Docker YAML IMSI: {imsi_from_yaml}, Handler IMSI: {imsi_from_handler}")
        raise Exception("IMSI mismatch.")
        
        
def check_latest_deregistered_imsis(docker_yaml_path, n):
    home_dir = os.path.dirname(os.path.abspath(__file__))
    docker_yaml_path = os.path.normpath(os.path.join(home_dir, '..' ,docker_yaml_path))
    try:
        amf_collection = mongo_access("amf")
        imsis_from_yaml = extract_imsi_from_docker_yaml(docker_yaml_path)[:n]      
        latest_deregistered_imsis = []
        
        for imsi in imsis_from_yaml:
            events = amf_collection.find(
            {"reportList.supi": f"imsi-{imsi}"},
            sort=[("timeStamp", -1)]
        )
            for event in events:
                for report in event["reportList"]:
                    if report["supi"] == f"imsi-{imsi}" and report["rmInfoList"][0]["rmState"] == "DEREGISTERED":
                        latest_deregistered_imsis.append(imsi)
                        break
                if imsi in latest_deregistered_imsis:
                    break
        if set(latest_deregistered_imsis) == set(imsis_from_yaml):
            logger.info("Deregistered IMSI match successful.")
        else:
            logger.error(f"Deregistered IMSI mismatch. Docker YAML IMSIs: {imsis_from_yaml}, Deregistered IMSIs: {latest_deregistered_imsis}")
            raise ValueError("Deregistered IMSI mismatch.")
    except Exception as e:
        logger.error(f"Failed to check latest deregistered IMSIs: {e}")
        raise e

def add_ues_process():
    try:
        add_ues(1)
        logger.info("UEs were successfully added.")
    except Exception as e:
        logger.error(f"Core network is not healthy. UEs were not added: {e}")
        raise e    
                 
def check_health_status(docker_compose_file):
    docker_api = DockerApi()
    containers = get_docker_compose_services(docker_compose_file)
    docker_api.check_health_status(containers)

def collect_all_logs(docker_compose_file, folder=None):
        docker_api = DockerApi()
        all_services = get_docker_compose_services(docker_compose_file)
        log_dir = get_log_dir()
        if folder:
            log_dir = os.path.join(log_dir, folder)
        docker_api.store_all_logs(log_dir, all_services)

def update_docker_compose(compose_file_path):
    with open(compose_file_path, 'r') as file:
        compose_data = yaml.safe_load(file)
        
    for service_name, service_data in compose_data.get('services', {}).items():
        if service_name in image_tags:
            service_data['image'] = image_tags[service_name]
            
    with open(compose_file_path, 'w') as file:
        yaml.safe_dump(compose_data, file, default_flow_style=False)