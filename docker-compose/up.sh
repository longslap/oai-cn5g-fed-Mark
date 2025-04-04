#!/bin/bash

docker volume prune -f

docker compose -f docker-compose-basic-nrf-ebpf.yaml up -d

echo "Check the container status..."
while true; do
    unhealthy_containers=$(docker ps --format '{{.Names}} {{.Status}}' | grep -E "starting|unhealthy" | wc -l)
    if [[ $unhealthy_containers -eq 0 ]]; then
        echo "All Containers are healthy. Start UEs..."
        break
    fi
    echo "Waiting for healthy containers..."
    sleep 5
done

docker compose -f docker-compose-multi-ue-qos.yaml up -d
sleep 3


docker ps -a
