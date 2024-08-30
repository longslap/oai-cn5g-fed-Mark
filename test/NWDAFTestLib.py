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

import shutil
import time
import re

from common import *
from docker_api import DockerApi
from vars import *


BASIC_VPP_NRF_DOCKER_COMPOSE_PATH = "../docker-compose/docker-compose-basic-vpp-nrf.yaml"
BASIC_VPP_NRF_CONFIG_PATH = "../docker-compose/conf/basic_vpp_nrf_config.yaml"
GNBSIM_VPP = "../docker-compose/docker-compose-gnbsim-vpp.yaml"
VPP_MYSQL_PATH = "../docker-compose/database/oai_db2.sql"
HEALTH_CHECK_PATH = "../docker-compose/healthscripts/mysql-healthcheck2.sh"
NWDAF_HTTP1_DOCKER_COMPOSE_FILE = "template/docker-compose-nwdaf-http1.yaml"
NWDAF_HTTP2_DOCKER_COMPOSE_FILE = "template/docker-compose-nwdaf-http2.yaml"
NWDAF_CONFIG_FILES = "template/kong.yml"

class NWDAFTestLib:
    ROBOT_LIBRARY_SCOPE = 'SUITE'
    
    def __init__(self):
        self.docker_api = DockerApi()
        self.conf_path = ""
        self.cn_docker_compose_path = ""
        self.nwdaf_docker_compose_path = ""
        self.running_traces = {}
        self.gnbsim_docker_compose_path = ""
        prepare_folders()
    
    def prepare_nwdaf(self,http_version = 1):
        self.cn_docker_compose_path = os.path.join(get_out_dir(), "docker-compose-basic-vpp-nrf.yaml")
        self.conf_path = os.path.join(get_out_dir(), "conf/basic_vpp_nrf_config.yaml")
        nwdaf_config_file = os.path.join(get_out_dir(), "conf/kong.yml")
        mysql_path = os.path.join(get_out_dir(), "database/oai_db2.sql")
        healthcheck_path = os.path.join(get_out_dir(), "healthscripts/mysql-healthcheck2.sh")
        self.nwdaf_docker_compose_path = os.path.join(get_out_dir(), "docker-compose-nwdaf.yaml")
        self.gnbsim_docker_compose_path = os.path.join(get_out_dir(),"docker-compose-gnbsim-vpp.yaml")
        os.makedirs(os.path.join(get_out_dir(), "conf"),exist_ok=True)
        os.makedirs(os.path.join(get_out_dir(), "database"),exist_ok=True)
        os.makedirs(os.path.join(get_out_dir(), "healthscripts"),exist_ok=True)
        shutil.copy(os.path.join(DIR_PATH, BASIC_VPP_NRF_DOCKER_COMPOSE_PATH), self.cn_docker_compose_path)
        shutil.copy(os.path.join(DIR_PATH, BASIC_VPP_NRF_CONFIG_PATH), self.conf_path)
        shutil.copy(os.path.join(DIR_PATH, VPP_MYSQL_PATH), mysql_path)
        shutil.copy(os.path.join(DIR_PATH, HEALTH_CHECK_PATH), healthcheck_path)
        shutil.copy(os.path.join(DIR_PATH, NWDAF_CONFIG_FILES), nwdaf_config_file)
        shutil.copy(os.path.join(DIR_PATH, GNBSIM_VPP), self.gnbsim_docker_compose_path)
        if http_version == 1:
            with open(self.cn_docker_compose_path, "r") as f:
                parsed = yaml.safe_load(f)
                parsed["services"]["vpp-upf"]["environment"][-1] = f"HTTP_VERSION={http_version}"           
            with open(self.cn_docker_compose_path, 'w') as f:
                yaml.dump(parsed, f)
            with open(self.conf_path, 'r') as f:
                content = f.read()
                new_content = content.replace('http_version: 2', f'http_version : {http_version}')
            with open(self.conf_path, 'w') as f:
                f.write(new_content)
            shutil.copy(os.path.join(DIR_PATH, NWDAF_HTTP1_DOCKER_COMPOSE_FILE), self.nwdaf_docker_compose_path)
        else:
            shutil.copy(os.path.join(DIR_PATH, NWDAF_HTTP2_DOCKER_COMPOSE_FILE), self.nwdaf_docker_compose_path)   
        with open(self.cn_docker_compose_path, "r") as f:
            parsed = yaml.safe_load(f)
            for service in parsed["services"]:
                if get_image_tag(service):
                    parsed["services"][f"{service}"]["image"] = get_image_tag(service)
        with open(self.cn_docker_compose_path, 'w') as f:
            yaml.dump(parsed, f) 
        # with open(self.nwdaf_docker_compose_path, "r") as f:
        #     parsed = yaml.safe_load(f)
        #     for service in parsed["services"]:
        #         if get_image_tag(service):
        #             parsed["services"][f"{service}"]["image"] = get_image_tag(service)
        # with open(self.nwdaf_docker_compose_path, "w") as f:
        #     yaml.dump(parsed, f)
            
    def start_basic_vpp_nrf_cn(self):
        start_docker_compose(self.cn_docker_compose_path)
        
    def stop_basic_vpp_nrf_cn(self):
        stop_docker_compose(self.cn_docker_compose_path)
        
    def down_basic_vpp_nrf_cn(self):
        down_docker_compose(self.cn_docker_compose_path)
        
    def start_nwdaf(self):
        start_docker_compose(self.nwdaf_docker_compose_path)
        
    def stop_nwdaf(self):
        stop_docker_compose(self.nwdaf_docker_compose_path)
        
    def down_nwdaf(self):
        down_docker_compose(self.nwdaf_docker_compose_path)
        
    def start_gnbsim_for_nwdaf(self):
        start_docker_compose(self.gnbsim_docker_compose_path)
    
    def stop_gnbsim_for_nwdaf(self):
        stop_docker_compose(self.gnbsim_docker_compose_path)
    
    def down_gnbsim_for_nwdaf(self):
        down_docker_compose(self.gnbsim_docker_compose_path)
    
    def check_nwdaf_health_status(self):
        all_cn_services = get_docker_compose_services(self.cn_docker_compose_path)
        all_nwdaf_services = get_docker_compose_services(self.nwdaf_docker_compose_path)
        self.docker_api.check_health_status(all_cn_services + all_nwdaf_services)
        
    def collect_cn_and_nwdaf_logs(self):
        all_cn_services = get_docker_compose_services(self.cn_docker_compose_path)
        all_nwdaf_services = get_docker_compose_services(self.nwdaf_docker_compose_path)
        self.docker_api.store_all_logs(get_log_dir(),all_cn_services + all_nwdaf_services)
    

        
        
        
    



