#!/bin/bash
echo "Deleting old artifacts..."
docker swarm leave --force
docker compose -f pektin-compose/pektin.yml down --remove-orphans
docker rm pektin-vault --force -v
docker volume rm pektin-compose_vault pektin-compose_db pektin-compose_grafana pektin-compose_prometheus
rm -rf your-infos.md update.sh start.sh stop.sh secrets/ arbeiter/ swarm.sh
docker image rm pektin-compose-check-config pektin-compose-install pektin-compose-first-start pektin-compose-start --force