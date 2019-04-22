#!/bin/bash
# create-kira.sh
# script that creates kira-user
#
# Creates kira-user
# accepts 2 inputs 
# $1 = the credential for user
# $2 = if present, update user credential w/ value from $1
############################################# 

#######################
## Script vars
#######################
logdir="/mnt/resource"
logfile="create-kira.sh.log"
uid="kira"
cred=$1
rotate=$2

#######################
## Logger function
#######################
function logit {
  echo -e "$*"
  echo -e "$(date +%Y/%m/%d-%H:%M:%S) $*" | sudo /bin/tee -a $logdir/$logfile
}

#######################
# create user kira with id of 500
#######################
function createUser {
  logit "create-kira: Creating $uid w/ id of 500."

  groupadd -g 500 $uid
  useradd -d /opt/$uid -u 500 $uid -g 500
  usermod -aG wheel $uid
  usermod --password $cred $uid
  passwd $uid $cred
  groupmod -g 500 $uid
  chown $uid:$uid /opt/$uid -R

  logit "create-kira:  Done. Exit code: $?"
}

#######################
## Main processing
#######################
logit `date '+RUN DATE: %m/%d/%y%nRUN TIME:%H:%M:%S'`
START=$(date +$SECONDS)
echo
echo "*** All output logged to $logdir/$logfile ***"
echo

#######################
# validate cred val
#######################
if [[ ! -z "$cred" ]]; then
  # Check if user exists
  if [ `id -u $uid 2>/dev/null || echo -1` -ge 0 ]; then
    logit "create-kira: User $uid exists. Updating credential."
    #  if rotate $2 is present, updated the credential
    if [ ! -z "$rotate" ]; then
      logit "create-kira: User $uid exists. Rotate Cred Arg found. Updating credentials."
      echo -e "$cred\n$cred" | passwd $uid -f
    fi
  else
    createUser           # Create user
  fi
fi
 
logit "Final Return Code: $?"
# return exitcode
END=$(date +$SECONDS)
ELAPSED=$(($END-$START))
logit "*** Runtime: $(( $(($END-$START)) / 60)) mins:$(( $(($END-$START)) % 60)) sec."
logit "END RUN"

exit $?