#!/bin/sh
for i in "$@"; do
  case $i in
    -s=*|--script-path=*)
      SCRIPT_PATH="${i#*=}"
      shift # past argument=value
      ;;
    -d=*|--delete-old=*)
      DELETE_OLD="${i#*=}"
      shift # past argument=value
      ;;
  esac
done


RED='\u001b[1;91m' ; NO_COLOR='\u001b[0m' 
# remove old containers and volumes in development environment
if [[ $DELETE_OLD = "true" ]]
then
echo -e "${RED}--------   STARTING FULL RESET   -------"
echo ""
echo -e       "       PRESS 'CTRL' + 'C' TO ABORT      "
echo ""
sleep 1
echo -en      "█████████████"
sleep 1
echo -en                    "████████████"
sleep 1
echo -en                                 "███████████████${NO_COLOR}"
sleep 1
echo ""
sh reset.sh
echo -e "${RED}--------     RESET FINISHED      --------${NO_COLOR}"
fi

docker rm pektin-scripts -v &> /dev/null


if [[ ! -z ${SCRIPT_PATH} ]]
then
    echo "Using the local pektin scripts docker image from $SCRIPT_PATH"
    docker build ${SCRIPT_PATH} -t "pektin-scripts" > /dev/null
else
    docker build ./scripts/ -t "pektin-scripts" > /dev/null
fi

mkdir secrets
echo -e "R_PEKTIN_SERVER_PASSWORD='stop'\nCSP_CONNECT_SRC='the'\nV_PEKTIN_API_PASSWORD='warnings'\nR_PEKTIN_API_PASSWORD='docker'\nUSE_POLICIES='foo'\n" > secrets/.env



# start vault
docker-compose --env-file secrets/.env -f pektin-compose/pektin.yml up -d vault

# run pektin-install
docker rm pektin-scripts -v &> /dev/null
docker run --env UID=$(id -u) --env GID=$(id -g) --env FORCE_COLOR=3 --name pektin-scripts --network rp --mount "type=bind,source=$PWD,dst=/pektin-compose/" -it pektin-scripts node ./dist/js/compose/scripts.js install || exit 1

# join swarm script
sh swarm.sh &> /dev/null
rm swarm.sh &> /dev/null

# run the start script
sh start.sh

# run pektin-first-start
docker rm pektin-scripts -v &> /dev/null
docker run --env UID=$(id -u) --env GID=$(id -g) --env FORCE_COLOR=3 --name pektin-scripts --network pektin-compose_vault --mount "type=bind,source=$PWD,dst=/pektin-compose/" -it pektin-scripts node ./dist/js/compose/scripts.js first-start 
docker rm pektin-scripts -v &> /dev/null
