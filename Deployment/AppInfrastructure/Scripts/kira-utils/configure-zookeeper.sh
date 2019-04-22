#!/bin/bash
# configure-zookeeper.sh
# script that configures kira-backend
#
# ZooKeeper	Performs distribution and synchronization of jobs
# 
# This script is deployed inconjunction with rabbitmq
# cofigure-rabbitmq.sh creates base kira directories 
############################################# 

#######################
## Script vars
#######################
logdir="/mnt/resource"
logfile="configure-zookeper.log"

kiraid="kira"
kiragrp="kira"

kiradir="/opt/kira"
zookeeperdir="$kiradir/zookeeper"
zookeeperbindir="$zookeeperdir/bin"
zookeeperconfdir="$zookeeperdir/conf"
zookeeperdatadir="$zookeeperdir/data"
zookeeperlogdir="$zookeeperdir/log"

#########################
## Logger function
#######################
function logit {
  echo -e "$*"
  echo -e "$(date +%Y/%m/%d-%H:%M:%S) $*" | sudo /bin/tee -a $logdir/$logfile
}

#########################
## used to create directory
## usage: createDir /thedirectorytocreate
#########################
function createDir {
    logit "     createDir: Creating $1"
    dir=$1      # the directory to create
    # create dir
    if /usr/bin/sudo [ ! -d $dir ]; then
        /usr/bin/sudo  mkdir -p $dir
        # Set permissions
        /usr/bin/sudo chown -R $kiraid:$kiragrp $dir
    fi
    logit "     createDir: Done. Exit code: $?"
}
   
#########################
## used to create directories
## Calls createDir $arg
#########################
function createStructure {
    logit "createStructure: Creating directories."

    createDir $zookeeperdir           # zookpr base
    createDir $zookeeperbindir        # zookpr bin
    createDir $zookeeperconfdir       # zookpr conf
    createDir $zookeeperdatadir       # zookpr data
    createDir $zookeeperlogdir        # zookpr log

    logit "createStructure: Done. Exit code: $?"
}
 
#######################
## Setup ZooKeeper
#######################logit `date '+RUN DATE: %m/%d/%y%nRUN TIME:%H:%M:%S'`
START=$(date +$SECONDS)
echo
echo "*** All output logged to $logdir/$logfile ***"
echo

createStructure

logit "Final Return Code: $?"
# return exitcode
END=$(date +$SECONDS)
ELAPSED=$(($END-$START))
logit "*** Runtime: $(( $(($END-$START)) / 60)) mins:$(( $(($END-$START)) % 60)) sec."
logit "END RUN"

exit $?