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

# Variables that are relevant for robot framework

EXT_DN1_IP = "192.168.79.141"
EXT_DN2_IP = "192.168.79.142"
EXT_DN3_IP = "192.168.79.143"
EXT_DN_EBPF_IP = "192.168.81.144"
EXT_DN1_IP_N3 = "192.168.81.141"

EXT_DN1_NAME = "oai-ext-dn"
EXT_DN2_NAME = "oai-ext-dn-2"
EXT_DN3_NAME = "oai-ext-dn-3"
EXT_DN_EBPF_NAME = "oai-ext-dn-ebpf"

ebf_upf_config = {
    "host": "oai-upf-ebpf",
    "sbi": {
        "port": 8080,
        "api_version": "v1",
        "interface_name": "demo-oai-test"
    },
    "n4": {
        "interface_name": "demo-oai-test"
    },
    "n3": {
        "interface_name": "demo-n3-test"
    },
    "n6": {
        "interface_name": "demo-n6-test"
    }
}
