#!/bin/bash

# prefix for docker containers involved in testing
docker_pre=$1
# name of the docker container image
docker_container=$2
# volume parameters
docker_volumes=$3
# test case name (all tests are run if empty string)
test=$4
# trap interrupts to ensure that cleanup code is run
trap 'echo interrupting tests..' SIGINT
cd SCALE-MAMBA
# set up test network and dummy image for copying from and into volumes
docker network create --subnet 172.29.0.0/16 $docker_pre-testnet > /dev/null
docker container create --name $docker_pre-dummy $docker_volumes $docker_container > /dev/null
docker cp Auto-Test-Data/ $docker_pre-dummy:/scale-mamba/
docker cp Programs/ $docker_pre-dummy:/scale-mamba/
# run test suite
./run_tests.sh $docker_pre $docker_container "$docker_volumes" $test
result=$? # temporarily store test result to return after cleanup
# cleanup container, volumes and network
docker container rm $docker_pre-dummy > /dev/null
docker volume rm $docker_pre-certs $docker_pre-programs $docker_pre-data $docker_pre-test-data > /dev/null
docker network rm $docker_pre-testnet > /dev/null
trap SIGINT
exit $result
