#!/bin/bash

UNIT_FILES_PATH="./units"
PROVISIONING_UNIT_FILE_NAME_PREFIX="provision-8080"
CELIX_UNIT_FILE_NAME_PREFIX="celix@"
FELIX_UNIT_FILE_NAME_PREFIX="felix@"

UNIT_FILE_NAME_SUFFIX=".service"

CELIX_AGENTS_NUMBER=2
FELIX_AGENTS_NUMBER=2

function stop_inaetics() {
    # Stop Felix units
    for fu in $(fleetctl list-units -no-legend | grep $FELIX_UNIT_FILE_NAME_PREFIX | awk '{print $1}'); do
        fleetctl stop $fu && fleetctl unload $fu && fleetctl destroy $fu
    done
    # Stop Celix units
    for cu in $(fleetctl list-units -no-legend | grep $CELIX_UNIT_FILE_NAME_PREFIX | awk '{print $1}'); do
        fleetctl stop $cu && fleetctl unload $cu && fleetctl destroy $cu
    done
    # Stop Provisioning unit
    for pu in $(fleetctl list-units -no-legend | grep provision | awk '{print $1}'); do
        fleetctl stop $pu && fleetctl unload $pu && fleetctl destroy $pu 
    done
}

function start_inaetics() { 
    echo "Inaetics Environment starting with $CELIX_AGENTS_NUMBER Celix agents and $FELIX_AGENTS_NUMBER Felix agents"

    # Submit unit files
    cd $UNIT_FILES_PATH

    # Start the unique Node Provisioning
    fleetctl submit $PROVISIONING_UNIT_FILE_NAME_PREFIX && fleetctl start $PROVISIONING_UNIT_FILE_NAME_PREFIX

    # Start Felix agents (Felix before Celix because they have more conflicts)"
    for (( INDEX=1; INDEX<=$FELIX_AGENTS_NUMBER; INDEX++ )); do
        name="${FELIX_UNIT_FILE_NAME_PREFIX}${INDEX}"
        fleetctl submit $name && fleetctl start $name
    done

    # Start Celix agents
    for (( INDEX=1; INDEX<=$CELIX_AGENTS_NUMBER; INDEX++ )); do
        name="${CELIX_UNIT_FILE_NAME_PREFIX}${INDEX}"
        fleetctl submit $name && fleetctl start $name
    done

    # Restore working directory...
    cd -

    echo "Inaetics Environment started"
    status_inaetics
}

function shutdown_nodes() {
    for node in $(fleetctl list-machines -no-legend | awk '{print $2}'); do
        ping -c 1 $node &>/dev/null
        [ $? -eq 0 ] && ssh core@$node sudo poweroff
    done
}

function reboot_nodes() {
    for node in $(fleetctl list-machines -no-legend | awk '{print $2}'); do
        ping -c 1 $node &>/dev/null
        [ $? -eq 0 ] && ssh core@$node sudo reboot
    done
}

function reset_nodes() {
    stop_inaetics
    reboot_nodes
}

function status_inaetics() { 
    echo "Available machines:"
    fleetctl list-machines
    echo

    #echo "Submitted unit files:"
    #fleetctl list-unit-files
    #echo

    echo "Deployed units:"
    fleetctl list-units
    echo
}

function usage() {
  echo "Usage: $0 < --status | --stop | --reset | --reboot | --shutdown | --start [--celixAgents=X] [--felixAgents=Y] [--unitFilesPath=/path/to/unit/files/repo]>"
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
    --reset)
      reset_nodes
    ;;
    --reboot)
      reboot_nodes
    ;;
    --shutdown)
      shutdown_nodes
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

###EOF###
