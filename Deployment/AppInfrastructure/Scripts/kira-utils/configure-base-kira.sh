#!/bin/bash
# configure-base-kira.sh
# script that configures kira-base directories
#
# Kira Base directories
##########################################################################

#######################
## Script vars
#######################
logdir="/mnt/resource"
logfile="configure-base-kira.sh.log"

kiraid="kira"
kiragrp="kira"

kiradir="/opt/kira"
kiralogdir="$kiradir/log"
kiraconfigdir="$kiradir/config"
kirajarsdir="$kiradir/jars"
kirassldir="$kiradir/ssl"
kiratmpdir="$kiradir/tmp"
kiradockerdir="$kiradir/docker-images"
kiraocrdir="$kiradir/kira-ocr"
kiracustommodeldir="$kiradir/custom-models"
kiramodeldir="$kiradir/model-cache"
migrationdir="$kiradir/migrations"
kirafields="$kiradir/fields"

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
    if /usr/bin/sudo [ ! -d $dir ] ; then
        /usr/bin/sudo  mkdir -p $dir
        # Set owners
        /usr/bin/sudo chown -R $kiraid:$kiragrp $dir

        if [[ "$dir" = "$kiratmpdir" ]] ; then
           # Set tmp permissions
          /usr/bin/sudo chmod 0777 $dir
        else
          # Set default on folders
          /usr/bin/sudo chmod 0755 $dir
        fi
    fi
    logit "     createDir: Done. Exit code: $?" 
}

#########################
## used to create directories
## Calls createDir $arg
#########################
function createStructure {
    logit "createStructure: Creating directories"

    createDir $kiradir               # root kiradir,should already exist
    createDir $kiralogdir            # log 
    createDir $kiraconfigdir         # config
    createDir $kiradockerdir         # docker-images
    createDir $kirajarsdir           # jars
    createDir $kirassldir            # ssl
    createDir $kiratmpdir            # tmp
    createDir $kiramodeldir          # models
    createDir $kiraocrdir            # kira-ocr
    createDir $migrationdir          # migrations 
    createDir $kirafields            # kira built-in models

    logit "createStructure: Done. Exit code: $?"
}

#######################
## Main processing
## Setup BASE Kira Structure
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
