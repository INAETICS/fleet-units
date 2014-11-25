#/bin/bash

UNIT_FILES_PATH="/home/inaetics/units"
PROVISIONING_UNIT_FILE_NAME_PREFIX="provision-8080"
CELIX_UNIT_FILE_NAME_PREFIX="celix@"
FELIX_UNIT_FILE_NAME_PREFIX="felix@"

UNIT_FILE_NAME_SUFFIX=".service"

CELIX_AGENTS_NUMBER=2
FELIX_AGENTS_NUMBER=2

function stop_inaetics(){
  
  #Stop Felix units
  for fu in $(fleetctl list-units -no-legend | grep $FELIX_UNIT_FILE_NAME_PREFIX | awk '{print $1}')
  do
    fleetctl stop $fu
    fleetctl unload $fu
    fleetctl destroy $fu
  done

  fleetctl stop "$FELIX_UNIT_FILE_NAME_PREFIX$UNIT_FILE_NAME_SUFFIX"
  fleetctl unload "$FELIX_UNIT_FILE_NAME_PREFIX$UNIT_FILE_NAME_SUFFIX"
  fleetctl destroy "$FELIX_UNIT_FILE_NAME_PREFIX$UNIT_FILE_NAME_SUFFIX"

  #Stop Celix units
  for cu in $(fleetctl list-units -no-legend | grep $CELIX_UNIT_FILE_NAME_PREFIX | awk '{print $1}')
  do
    fleetctl stop $cu
    fleetctl unload $cu
    fleetctl destroy $cu
  done

  fleetctl stop "$CELIX_UNIT_FILE_NAME_PREFIX$UNIT_FILE_NAME_SUFFIX"
  fleetctl unload "$CELIX_UNIT_FILE_NAME_PREFIX$UNIT_FILE_NAME_SUFFIX"
  fleetctl destroy "$CELIX_UNIT_FILE_NAME_PREFIX$UNIT_FILE_NAME_SUFFIX"

  #Stop Provisioning unit
  
  fleetctl stop    "$PROVISIONING_UNIT_FILE_NAME_PREFIX$UNIT_FILE_NAME_SUFFIX"
  fleetctl unload  "$PROVISIONING_UNIT_FILE_NAME_PREFIX$UNIT_FILE_NAME_SUFFIX"
  fleetctl destroy "$PROVISIONING_UNIT_FILE_NAME_PREFIX$UNIT_FILE_NAME_SUFFIX"

}


function start_inaetics(){

	echo "Inaetics Environment starting with $CELIX_AGENTS_NUMBER Celix agents and $FELIX_AGENTS_NUMBER Felix agents"

  #Submit unit files
  fleetctl submit "$UNIT_FILES_PATH/$PROVISIONING_UNIT_FILE_NAME_PREFIX$UNIT_FILE_NAME_SUFFIX"
  fleetctl submit "$UNIT_FILES_PATH/$CELIX_UNIT_FILE_NAME_PREFIX$UNIT_FILE_NAME_SUFFIX"
  fleetctl submit "$UNIT_FILES_PATH/$FELIX_UNIT_FILE_NAME_PREFIX$UNIT_FILE_NAME_SUFFIX"

  #Start the unique Node Provisioning
  fleetctl start -no-block "$PROVISIONING_UNIT_FILE_NAME_PREFIX$UNIT_FILE_NAME_SUFFIX"
  sleep 2

  #Start Felix agents (Felix before Celix because they have more conflicts)"
  for (( INDEX=1; INDEX<=$FELIX_AGENTS_NUMBER; INDEX++ ))
  do
    fleetctl start -no-block "$FELIX_UNIT_FILE_NAME_PREFIX$INDEX$UNIT_FILE_NAME_SUFFIX"
    sleep 2
  done

  #Start Celix agents
  for (( INDEX=1; INDEX<=$CELIX_AGENTS_NUMBER; INDEX++ ))
  do
    fleetctl start -no-block "$CELIX_UNIT_FILE_NAME_PREFIX$INDEX$UNIT_FILE_NAME_SUFFIX"
    sleep 2
  done
  


}

function status_inaetics(){
  
  echo "Available machines:"
  fleetctl list-machines
  echo

  echo "Submitted unit files:"
  fleetctl list-unit-files
  echo

  echo "Deployed units:"
  fleetctl list-units
  echo

}

function usage(){

  echo "Usage: $0 <--status | --stop | --start [--celixAgents=X] [--felixAgents=Y] [--unitFilesPath=/path/to/unit/files/repo]>"

}

#Main

[ $# -eq 0 ] && usage && exit 1

READY_TO_START=0

for ITEM in $*; do
  case ${ITEM} in
    --status)
      status_inaetics
    ;;
    --stop)
      stop_inaetics
    ;;
    --start)
      READY_TO_START=1
    ;;
    --celixAgents=*)
      CELIX_AGENTS_NUMBER=`echo ${ITEM} | cut -d"=" -f2`
    ;;
    --felixAgents=*)
      FELIX_AGENTS_NUMBER=`echo ${ITEM} | cut -d"=" -f2`
    ;;
    --unitFilesPath=*)
      UNIT_FILES_PATH=`echo ${ITEM} | cut -d"=" -f2`
    ;;
    *)
      usage
      exit 1
    ;;
  esac
done

[ $READY_TO_START -eq 1 ] && start_inaetics

