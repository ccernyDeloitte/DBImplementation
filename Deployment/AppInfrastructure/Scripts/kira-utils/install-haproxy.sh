#!/bin/bash
#
#  install-haproxy.sh
#
# This script is used to install install ha-proxy
##########################################################################


#######################
## Script vars
#######################
logdir="/mnt/resource"
logfile="install-haproxy.sh.log"

#######################
## Logger function
#######################
function logit {
  echo -e "$*"
  echo -e "$(date +%Y/%m/%d-%H:%M:%S) $*" | sudo /bin/tee -a $logdir/$logfile
}

#######################
## Install Postgresql
#######################
function installHAProxy {
  # https://www.softwarecollections.org/en/scls/rhscl/rh-postgresql96/
  logit "installHAProxy: Installing HA Proxy."
  /usr/bin/sudo yum install -y haproxy
  logit "installHAProxy:  Done. Exit code: $?"
}

#######################
## Main processing
#######################
logit `date '+RUN DATE: %m/%d/%y%nRUN TIME:%H:%M:%S'`
START=$(date +$SECONDS)
echo
echo "*** All output logged to $logdir/$logfile ***"
echo

installHAProxy
 
logit "Final Return Code: $?"
# return exitcode
END=$(date +$SECONDS)
ELAPSED=$(($END-$START))
logit "*** Runtime: $(( $(($END-$START)) / 60)) mins:$(( $(($END-$START)) % 60)) sec."
logit "END RUN"

exit $?


