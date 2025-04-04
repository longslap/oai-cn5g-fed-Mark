#!/bin/bash

#docker compose -f docker-compose-ueransim-ebpf.yaml down -t0
docker compose -f docker-compose-multi-ue-qos.yaml down -t0
#sleep 3

docker compose -f docker-compose-basic-nrf-ebpf.yaml down -t0

#sleep 3

docker ps -a
