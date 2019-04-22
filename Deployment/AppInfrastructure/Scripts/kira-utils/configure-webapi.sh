#!/bin/bash
# configure-webapi.sh
# script that configures kira-webapi
#
# Kira WebAPI Component
##########################################################################

#######################
## Script vars
#######################
logdir="/mnt/resource"
logfile="configure-webapi.log"

kiraid="kira"
kiragrp="kira"

kiradir="/opt/kira"
omnipagedir="$kiradir/omnipage"
omnipagebindir="$omnipagedir/bin"
omnipagelicensedir="$omnipagedir/license"
ocrlibdir="$kiradir/kira-ocr/lib"
ocrdatadir="$kiradir/kira-ocr/data"

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
        /usr/bin/sudo mkdir -p $dir
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
    logit "createStructure: Creating directories"

    createDir $kirafields           # kira built-in models
    createDir $omnipagedir          # omnipage
    createDir $omnipagebindir       # omnipage bin
    createDir $omnipagelicensedir   # omnipage license
    createDir $ocrlibdir            # OCR lib
    createDir $ocrdatadir           # OCR data 

    logit "createStructure: Done. Exit code: $?"
}

#######################
## Main processing
## Setup Kira WebAPI
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
