#!/bin/bash
################################################################################
# Licensed to the OpenAirInterface (OAI) Software Alliance under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The OpenAirInterface Software Alliance licenses this file to You under
# the OAI Public License, Version 1.1  (the "License"); you may not use this file
# except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.openairinterface.org/?page_id=698
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#-------------------------------------------------------------------------------
# For more information about the OpenAirInterface (OAI) Software Alliance:
#      contact@openairinterface.org
################################################################################


# List of containers
CONTAINERS=(
  mysql asterisk-ims oai-udr oai-udm oai-ausf oai-nrf
  oai-amf oai-smf oai-upf oai-ext-dn
)


declare -A NETWORKS=(
  ["sbi_network"]="192.168.70.128/26:oai-core-sbi"
  ["n2_network"]="192.168.76.0/28:oai-core-n2"
  ["n3_network"]="192.168.77.0/28:oai-core-n3"
  ["n4_network"]="192.168.78.0/28:oai-core-n4"
  ["n6_network"]="192.168.79.0/28:oai-core-n6"
)

declare -A DEPENDENCIES=(
  ["oai-ext-dn"]="oai-upf"
)

pull_latest_image() {
  echo "🔄 Pulling latest Docker images for all containers..."
  local success=true

  for c in "${CONTAINERS[@]}"; do
    image=$(get_image_name "$c")
    echo -n "⏳ Pulling image: $image ... "
    if docker image pull "$image" > /dev/null 2>&1; then
      echo "✅ Success"
    else
      echo "❌ Failed to pull $image"
      success=false
    fi
  done

  if $success; then
    echo "🎉 All images pulled successfully."
  else
    echo "⚠️  Some images failed to pull. Check above messages."
  fi
}

delete_images() {
  echo "⚠️  Warning: This will remove local Docker images for all listed containers!"
  read -rp "Are you sure you want to delete these images? (y/N): " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "❌ Operation cancelled by user."
    return 1
  fi

  local success=true
  echo "🗑️  Deleting Docker images for containers..."

  for c in "${CONTAINERS[@]}"; do
    image=$(get_image_name "$c")
    echo -n "🧹 Removing image: $image ... "
    if docker image rm -f "$image" > /dev/null 2>&1; then
      echo "✅ Removed"
    else
      echo "❌ Failed to remove $image (maybe it's in use or doesn't exist)"
      success=false
    fi
  done

  if $success; then
    echo "🧼 All images removed successfully."
  else
    echo "⚠️  Some images could not be removed. Check above messages."
  fi
}

get_image_name() {
  local container="$1"
  case "$container" in
    mysql)
      echo "mysql:8.0"
      ;;
    asterisk-ims)
      echo "oaisoftwarealliance/ims:latest"
      ;;
    oai-ext-dn)
      echo "oaisoftwarealliance/trf-gen-cn5g:latest"
      ;;
    *)
      echo "oaisoftwarealliance/$container:develop"
      ;;
  esac
}

create_networks() {
  echo "Creating networks..."
  for net in "${!NETWORKS[@]}"; do
    subnet_bridge=(${NETWORKS[$net]//:/ })
    subnet=${subnet_bridge[0]}
    bridge=${subnet_bridge[1]}
    if ! docker network inspect "$net" &>/dev/null; then
      docker network create \
        --driver=bridge \
        --subnet="$subnet" \
        --opt "com.docker.network.bridge.name=$bridge" \
        "$net"
    fi
  done
}

find_ip_for_interface() {
   c=$1
   i=$2
   ip=$(docker inspect "$c" | jq -r --arg iface "$i" \
     '.[].NetworkSettings.Networks
      | map(select(.DriverOpts."com.docker.network.endpoint.ifname" == $iface))
      | .[0].IPAddress')
   echo "Container $c interface $i ip-address is $ip"
}


wait_for_health() {
  local container="$1"
  local timeout=60  # seconds
  local elapsed=0
  local interval=2

  echo -n "⏳ Waiting for $container to be healthy"

  while [ $elapsed -lt $timeout ]; do
    status=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null)

    if [ "$status" == "healthy" ]; then
      echo -e " ✅"
      return 0
    elif [ "$status" == "unhealthy" ]; then
      echo -e " ❌ Unhealthy"
      return 1
    elif [ "$status" == "" ]; then
      # No health check configured
      echo -e " ⚠️  No health check"
      return 0
    fi

    echo -n "."
    sleep $interval
    elapsed=$((elapsed + interval))
  done

  echo -e " ❌ Timeout after ${timeout}s"
  return 1
}

start_containers() {
  SECONDS=0
  create_networks
  echo "Starting containers..."

  for c in "${CONTAINERS[@]}"; do
    echo -n "🔄 Starting container: $c... "
    if docker ps -a --format '{{.Names}}' | grep -wq "$c"; then
      docker rm -f "$c" &>/dev/null
    fi

    case "$c" in
      mysql)
        image=$(get_image_name "$c")
        docker run -d --name mysql \
          --env TZ=Europe/Paris \
          --env MYSQL_DATABASE=oai_db \
          --env MYSQL_USER=test \
          --env MYSQL_PASSWORD=test \
          --env MYSQL_ROOT_PASSWORD=linux \
          -v "$(pwd)/database/oai_db.sql:/docker-entrypoint-initdb.d/oai_db.sql" \
          -v "$(pwd)/healthscripts/mysql-healthcheck.sh:/tmp/mysql-healthcheck.sh" \
          --health-cmd='/bin/bash -c "/tmp/mysql-healthcheck.sh"' \
          --health-interval=10s \
          --health-timeout=3s \
          --health-retries=5 \
          --network=name=sbi_network,driver-opt=com.docker.network.endpoint.ifname=sbi \
          --network-alias=msql.openairinterface.org \
          "$image" &>/dev/null
        ;;
      asterisk-ims)
        image=$(get_image_name "$c")
        docker run -d --name asterisk-ims \
          -v "$(pwd)/conf/sip.conf:/etc/asterisk/sip.conf" \
          -v "$(pwd)/conf/users.conf:/etc/asterisk/users.conf" \
          --health-cmd='/bin/bash -c "pgrep asterisk"' \
          --health-interval=10s \
          --health-timeout=5s \
          --health-retries=5 \
          --network=name=n6_network,driver-opt=com.docker.network.endpoint.ifname=n6 \
          --ip 192.168.79.3 \
          "$image" &>/dev/null
        ;;
      oai-amf)
        image=$(get_image_name "$c")
        docker run -d --name oai-amf \
          --env TZ=Europe/Paris \
          -v "$(pwd)/conf/basic.yaml:/openair-amf/etc/config.yaml" \
          --network=name=sbi_network,driver-opt=com.docker.network.endpoint.ifname=sbi \
          --network=name=n2_network,driver-opt=com.docker.network.endpoint.ifname=n2 \
          "$image" &>/dev/null
        ;;
      oai-smf)
        image=$(get_image_name "$c")
        docker run -d --name oai-smf \
          --env TZ=Europe/Paris \
          -v "$(pwd)/conf/basic.yaml:/openair-smf/etc/config.yaml" \
          --network=name=sbi_network,driver-opt=com.docker.network.endpoint.ifname=sbi \
          --network=name=n4_network,driver-opt=com.docker.network.endpoint.ifname=n4 \
          "$image" &>/dev/null
        ;;
      oai-upf)
        image=$(get_image_name "$c")
        docker run -d --name oai-upf \
          --privileged \
          --cap-add=NET_ADMIN \
          --cap-add=SYS_ADMIN \
          --cap-drop=ALL \
          --env TZ=Europe/Paris \
          -v "$(pwd)/conf/basic.yaml:/openair-upf/etc/config.yaml" \
          --network=name=sbi_network,driver-opt=com.docker.network.endpoint.ifname=sbi \
          --network=name=n3_network,driver-opt=com.docker.network.endpoint.ifname=n3 \
          --network=name=n4_network,driver-opt=com.docker.network.endpoint.ifname=n4 \
          --network=name=n6_network,gw-priority=1,driver-opt=com.docker.network.endpoint.ifname=n6 \
          "$image" &>/dev/null
        ;;
      oai-ext-dn)
        image=$(get_image_name "$c")
        docker run -d --name oai-ext-dn \
          --privileged \
          --cap-add=NET_ADMIN \
          --cap-add=SYS_ADMIN \
          --cap-drop=ALL \
          --init \
          --network=name=n6_network,driver-opt=com.docker.network.endpoint.ifname=n6 \
          --ip 192.168.79.4 \
          --health-cmd='/bin/bash -c "ip r | grep 12.1.1"' \
          --health-interval=10s \
          --health-timeout=5s \
          --health-retries=5 \
          --entrypoint /bin/bash \
          "$image" \
          -c "ip route add 12.1.1.0/24 via 192.168.79.2 dev n6; trap : SIGTERM SIGINT; sleep infinity & wait" &>/dev/null
        ;;
      *)
        image=$(get_image_name "$c")
        docker run -d --name "$c" \
          --env TZ=Europe/Paris \
          -v "$(pwd)/conf/basic.yaml:/openair-${c#oai-}/etc/config.yaml" \
          --network=name=sbi_network,driver-opt=com.docker.network.endpoint.ifname=sbi \
          "$image" &>/dev/null
        ;;
    esac
    if [ $? -eq 0 ]; then
      echo "✅ Done"
    else
      echo "❌ Failed to start $c"
    fi
  done
  for c in "${CONTAINERS[@]}"; do
    wait_for_health $c
  done
  echo "✅ All containers attempted to start."
  echo "⏱️  Total time to start: ${SECONDS}s"
  find_ip_for_interface "oai-amf" "n2"
  find_ip_for_interface "oai-upf" "n3"
  find_ip_for_interface "oai-upf" "n6"
}

stop_containers() {
  SECONDS=0
  echo "Stopping containers..."
  stopped_any=false

  for c in "${CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -wq "$c"; then
      echo "🛑 Stopping $c..."
      docker stop "$c" &>/dev/null
      stopped_any=true
    fi
  done

  if ! $stopped_any; then
    echo -e "\033[0;33m⚠️  No containers were running to stop.\033[0m"
  else
    echo "✅ All active containers stopped."
  fi

  echo "⏱️  Total time to stop: ${SECONDS}s"
}

down_containers() {
  SECONDS=0

  echo "Removing containers and networks..."

  any_removed=false
  for c in "${CONTAINERS[@]}"; do
    if docker ps -a --format '{{.Names}}' | grep -wq "$c"; then
      echo "🗑️  Removing container: $c"
      docker rm -f "$c" &>/dev/null
      any_removed=true
    fi
  done

  if ! $any_removed; then
    echo -e "\033[0;33m⚠️  No containers found to delete.\033[0m"
  fi

  for net in "${!NETWORKS[@]}"; do
    if docker network inspect "$net" &>/dev/null; then
      echo "🧹 Removing network: $net"
      docker network rm "$net" &>/dev/null
    fi
  done

  echo "✅ Cleanup complete."
  echo "⏱️  Total time to delete: ${SECONDS}s"

}

show_logs() {
  local any_logs=false
  local log_dir="logs"
  mkdir -p "$log_dir"

  timestamp=$(date +"%Y%m%d_%H%M%S")

  for c in "${CONTAINERS[@]}"; do
    if docker ps -a --format '{{.Names}}' | grep -wq "$c"; then
      echo "📝 Collecting logs for $c..."
      logfile="$log_dir/${c}_${timestamp}.log"
      docker logs "$c" > "$logfile" 2>&1 &
      any_logs=true
    fi
  done

  if ! $any_logs; then
    echo -e "\033[0;33m⚠️  Warning: No containers from the list are running or available to show logs.\033[0m"
  else
    echo -e "\n✅ Logs collected in '$log_dir/' directory with timestamp $timestamp.\n"
  fi

  wait
}

show_ps() {
  local output
  output=$(docker ps -a --format '{{.Names}}' | grep -E "$(IFS=\|; echo "${CONTAINERS[*]}")")
  if [ -z "$output" ]; then
    echo -e "\033[0;33m⚠️  Warning: None of the specified containers are currently running.\033[0m"
  else
    docker ps -a | grep -E "$(IFS=\|; echo "${CONTAINERS[*]}")"
  fi
}

show_help() {
  echo "Usage: $0 <command>"
  echo
  echo "Commands:"
  echo "  up     Create networks and start all containers"
  echo "  down      Delete all containers and network"
  echo "  stop      Stop all containers"
  echo "  logs      Show logs for all containers"
  echo "  ps        Show status of running containers"
  echo "  pull      Pull latest images"
  echo "  clean     It will clean all the images"
  echo "  help      Show this help message"
}

case "$1" in
  up)
    start_containers
    ;;
  stop)
    stop_containers
    ;;
  down)
    down_containers
    ;;
  logs)
    show_logs
    ;;
  pull)
    pull_latest_image
    ;;
  clean)
    delete_images
    ;;
  ps)
    show_ps
    ;;
  help|--help|-h|"")
    show_help
    ;;
  *)
    echo "Unknown command: $1"
    show_help
    exit 1
    ;;
esac
