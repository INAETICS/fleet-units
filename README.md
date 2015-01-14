fleet-units
===========

Unit files needed to control the system with fleet, and a script that allows to easily
control the Inaetics environment.

## Prerequisites

The `inaetics_fleet_manager.sh` script relies on the `fleetctl` binary to available on
your path.

## Unit files

- `provision-8080.service`: Unit files for ACE Provisioning server deployment. Should be
  started via fleetctl only once. Conflicts with Felix node agents (due to 8080 port
  mapping);
- `celix@.service`: template that allows to launch N Celix node agents. To deploy *N*
  Celix instances, use `fleetctl start celix@X.service`, with *X* starting from 1 and
  ending to *N*;
- `felix@.service`: template that allows to launch N Felix node agents. To deploy *N*
  Felix instances, use `fleetctl start felix@X.service`, with *X* starting from 1 and
  ending to *N*. Conflicts with provision-8080.service (due to 8080 port mapping).

Please note that all the unit files rely on the `node.config` environment file (see
https://github.com/INAETICS/node-bootstrap), which contain basic environment variables
useful to setup the environment (e.g. external Etcd server, Docker server, INAETICS
subnetwork, Docker containers names). In the unit files it is expected to exist under
`/usr/share/oem`, in case it's located somewhere else on your fleet machine just change
the path.

## inaetics_fleet_manager.sh

Setting up the Inaetics environment via fleetctl can require a lot of commands and steps.
This script tries to automatically deploy the units on the available machines belonging to
the fleet.  It offers three functions:

- `--start [--celixAgents=X] [--felixAgents=Y] [--unitFilesPath=/path/to/unit/files]`:
  starts the Inaetics environment submitting the unit files located in
  "/path/to/unit/files" (defaults to `/home/inaetics/units`) and bringing up one ACE
  provisioning server (mandatory), *N* Celix Agents (defaults to 2 in case omitted) and
  *Y* Felix agents (defaults to 2 in case omitted). Please note that the fleet scheduler
  tries to load as much units as possible, given the specified number of Felix/Celix
  agents and conflicts between units. When it cannot load anymore units, the fleetctl
  start returns submitting the unit but without starting it;
- `--stop`: stop all the scheduled units and unload/destroy the unit files;
- `--status`: prints the list of available machines belonging to the fleet, the submitted
  unit files and the deployed units.

