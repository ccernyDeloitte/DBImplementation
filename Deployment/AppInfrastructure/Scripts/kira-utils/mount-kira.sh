#!/bin/bash
#
#  mount-kira.sh
#
# This script is used to mount /opt/kira
##########################################################################


#######################
## Script vars
#######################
logdir="/mnt/resource"
logfile="mount-kira.sh.log"
kiraid="kira"
kiragrp="kira"
kiradir="/opt/kira"
kirafs="/mnt/argus"

#######################
## Logger function
#######################
function logit {
  echo -e "$*"
  echo -e "$(date +%Y/%m/%d-%H:%M:%S) $*" | sudo /bin/tee -a $logdir/$logfile
}

#######################
## Mount-Kira
#######################
function mount-kira {
  logit "mount-kira: Mounting $kiradir to $kirafs."  
  if mount | grep $kiradir; then
    logit "mount-kira: $kiradir is a mount."
  else
    logit "mount-kira: Adding to FSTAB and mounting: $kiradir to $kirafs."
    echo "$kirafs                      $kiradir none  bind            0       0" >> /etc/fstab
    mount -a
  fi

  logit "mount-kira: Done. Exit code: $?"
}


#######################
## Main processing
#######################
logit `date '+RUN DATE: %m/%d/%y%nRUN TIME:%H:%M:%S'`
START=$(date +$SECONDS)
echo
echo "*** All output logged to $logdir/$logfile ***"
echo

mount-kira
 
logit "Final Return Code: $?"
# return exitcode
END=$(date +$SECONDS)
ELAPSED=$(($END-$START))
logit "*** Runtime: $(( $(($END-$START)) / 60)) mins:$(( $(($END-$START)) % 60)) sec."
logit "END RUN"

exit $?