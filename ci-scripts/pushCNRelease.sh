#!/bin/bash


# Licensed to the OpenAirInterface (OAI) Software Alliance under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The OpenAirInterface Software Alliance licenses this file to You under
# the OAI Public License, Version 1.1  (the "License"); you may not use this file
# except in compliance with the License.
# You may obtain a copy of the License at
# 
#   http://www.openairinterface.org/?page_id=698
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ------------------------------------------------------------------------------
# For more information about the OpenAirInterface (OAI) Software Alliance:
#   contact@openairinterface.org
# ---------------------------------------------------------------------
# 


# SCRIPT USAGE: ./pushCNRelease.sh amf v2.1.10

# 1. RELEASE TAG
VERSION=$2 # This tag will be pushed to DockerHub

# 2. DOCKER HUB ACCOUNT AND REGISTRY URL
DH_Account="oaisoftwarealliance"
REGISTRY_URL='selfix.sboai.cs.eurecom.fr'

# 3. GET THE LATEST COMMIT_SHA OF develop BRANCH FOR THE CORE NETWORK FUNCTION FROM GITLAB
NF=$1
BASE_API_URL="https://gitlab.eurecom.fr/api/v4/projects"
BRANCH="develop"
REPO="oai-cn5g-$NF"
ENCODED_REPO="oai%2Fcn5g%2F$REPO"

## 3.1 Construct API URL for the develop branch
API_URL="$BASE_API_URL/$ENCODED_REPO/repository/branches/$BRANCH"

## 3.2 Fetch latest commit SHA using GitLab API
LATEST_COMMIT=$(curl -s "$API_URL" | jq -r '.commit.id')

## 3.3 Get short 8-character commit SHA
SHORT_COMMIT=${LATEST_COMMIT:0:8} # Example: c054106e

echo "Latest short commit SHA: $SHORT_COMMIT of the Repository: $REPO and the Branch: $BRANCH"

# 4. TAG AND PUSH THE IMAGE TO DOCKER HUB
# Authenticate with DockerHub and the private Docker registry before pushing the image

REGISTRY_REPO="oai-$NF"

docker rmi "$REGISTRY_URL"/"$REGISTRY_REPO":"$BRANCH"-"$SHORT_COMMIT" || true
docker buildx imagetools create -t "$DH_Account"/"$REGISTRY_REPO":"$VERSION" "$REGISTRY_URL"/"$REGISTRY_REPO":"$BRANCH"-"$SHORT_COMMIT"

# Log out from DockerHub and the private Docker registry
