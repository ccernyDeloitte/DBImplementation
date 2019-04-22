#!/bin/bash
# configure-rabbitmq.sh
# script that configures rabbitmq
#
# RabbitMQ - Performs Queuing of tasks/jobs and works as a message broker
############################################# 


#######################
## Script vars
#######################
logdir="/mnt/resource"
logfile="configure-rabbitmq.log"
kiradir="/opt/kira"
kiraid="kira"
kiragrp="kira"
kiradir="/opt/kira"
rmqdir="$kiradir/rabbitmq"
rmqetcdir="$rmqdir/etc"
rmqlogdir="$rmqdir/log"
rmqmnesiadir="$rmqdir/mnesia"

## Logger function
#######################
function logit {
  echo -e "$*"
  echo -e "$(date +%Y/%m/%d-%H:%M:%S) $*" | sudo /bin/tee -a $logdir/$logfile
}

## used to create directory
## usage: createDir /thedirectorytocreate
#########################
function createDir {
    logit "     createDir: Creating $1"
    dir=$1      # the directory to create
    # create dir
    if /usr/bin/sudo [ ! -d $dir ]; then
        /usr/bin/sudo mkdir -p $dir
        
        # Set permissions
        /usr/bin/sudo chown -R $kiraid:$kiragrp $dir
    fi
    logit "     createDir: Done. Exit code: $?"
}

## used to create directories
## Calls createDir $arg
#########################
function createStructure {
    logit "createStructure: Creating directories."

    createDir $rmqdir         # rabbitmq base
    createDir $rmqetcdir      # rmq etc 
    createDir $rmqlogdir      # rmq log
    createDir $rmqmnesiadir   # rmq mnesia

    logit "createStructure: Done. Exit code: $?"
}

#######################
## Main processing
## Setup RabbitMQ
#######################
logit `date '+RUN DATE: %m/%d/%y%nRUN TIME:%H:%M:%S'`
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