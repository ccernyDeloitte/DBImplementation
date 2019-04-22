#!/bin/bash
# setup_celanupcron.sh
# removes @reboot entris from cron
############################################# 

## Script vars
#######################
logdir="/mnt/resource"
logfile="setup_cleanupcron.log"
lckfile=".cleanupcron"

## Logger function
#######################
function logit {
  echo -e "$*"
  echo -e "$(date +%Y/%m/%d-%H:%M:%S) $*" >> $logdir/$logfile
}

## Check script setup
#######################
function checksetup {
  ## Verify User Executing Script is root
  if [[ $EUID -ne 0 ]]; then
    logit "checksetup: Error: This script must be run as root" 1>&2
    exit $?
  fi
}

function removebootcronjob {
	crontab -l | grep -v '@reboot /var/lib/waagent/custom-script/download/0/dotnet-install.sh'  | crontab -
}

function removevstsagentsetupcronjob {
	crontab -l | grep -v '@reboot /var/lib/waagent/custom-script/download/0/setup_installvstsagent.sh' | crontab -
}

function removecleanupcron {
	crontab -l | grep -v '@reboot /var/lib/waagent/custom-script/download/0/setup_cleanupcron.sh' | crontab -
}

#######################
## Main processing
#######################
logit `date '+RUN DATE: %m/%d/%y%nRUN TIME:%H:%M:%S'`
START=$(date +$SECONDS)

echo
echo "*** All output logged to $logdir/$logfile ***"
echo

## Ensure file user is root
checksetup                               
umask 022                               # set umask
## check Retry. Bail if exists.
if [ ! -f "$logdir/$lckfile" ] ; then
	removebootcronjob
	removevstsagentsetupcronjob
	removecleanupcron
fi

# return exitcode
END=$(date +$SECONDS)
ELAPSED=$(($END-$START))
logit "*** Runtime: $(( $(($END-$START)) / 60)) mins:$(( $(($END-$START)) % 60)) sec."

## semaphore
if [ $? -eq 0 ] ; then
	logit  "Done with configuration. Creating semaphore file."
	touch "$logdir/$lckfile"
fi

logit "Final Return Code: $?"
logit "END RUN"

exit $?