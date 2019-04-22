#!/bin/bash
# 
# script that configures kira workernode:
#
# 1. kira-ml - Performs model training tasks
# 2. Jamie-export - Performs data extraction tasks from the documents
# 3. Doc-converter - Performs OCR and document coversions tasks
############################################# 

#########################
## Script vars
#######################
logdir="/mnt/resource"
logfile="configure-worker.log"

kiraid="kira"
kiragrp="kira"

kiradir="/opt/kira"
kiraocrdir="$kiradir/kira-ocr"
kiraocrdir="$kiradir/kira-ocr"
kiraocrdatadir="$kiraocrdir/data"
kiraocrlib="$kiraocrdir/lib"

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
    logit "createStructure: Creating directories."

    createDir $kiraocrdir            # ocr
    createDir $kiraocrdatadir        # ocr-data
    createDir $kiraocrlib            # ocr-lib

    logit "createStructure: Done. Exit code: $?"
}
 
#######################
## Main processing
## Setup Jamie/Jamie-Learn.Doc-Extractor
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