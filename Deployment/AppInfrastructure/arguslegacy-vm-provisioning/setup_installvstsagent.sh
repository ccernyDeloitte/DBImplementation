#!/bin/bash
# setup_installvstsagent.sh
# Installs and configures vsts agent and dependent packages
# Requires machine to be domain joined
#############################################

## Script vars
#######################
logdir="/mnt/resource"
logfile="setup_installvstsagent.log"
agenttarball="/var/lib/waagent/custom-script/download/0/vsts-agent-linux-x64-2.129.0.tar.gz"
installdir="/opt/vstsagents"
vstsuid:"usauditvstssvc"
vstsgrp:"domain_users"
agentname="$(hostname)-agent"
agentcount=4

## Logger function
#######################
function logit {
  echo -e "$*"
  echo -e "$(date +%Y/%m/%d-%H:%M:%S) $*" >> $logdir/$logfile
}

function updateProfile {
  echo "# Add .NET Core 2.0 to my login environment \n source scl_source enable rh-dotnet20" >> /home/$1/.bash_profile
}

#######################
## Main processing
#######################
logit `date '+RUN DATE: %m/%d/%y%nRUN TIME:%H:%M:%S'`
START=$(date +$SECONDS)

echo
echo "*** All output logged to $logdir/$logfile ***"
echo

## check Retry. Bail if exists.
if [ ! -f $agenttarball ] ; then
  logit "Error: VSTS Agent not found. \r\n\ Expected location is $agenttarball ."
  exit 1
fi

logit "Creating directory and copying agent files."                        # log stuff
mkdir -p $installdir                                                       # create agents dir, as root
cp -p $agenttarball $installdir/.                                          # copy file to installdir, as root
chown $vstsuid:$vstsgrp $installdir                                        # chown to usauditvstssvc, as root
chown $vstsuid:$vstsgrp $installdir/$(basename $agenttarball)              # chown to usauditvstssvc, as root
updateProfile $vstsuid                                                     # update profile

for (( i=1; i<=$agentcount; i++ ))                                                 # create & config agent based on agentcount val
do
  if [ ! -d "$installdir/$agentname$i" ] ; then                          # create only if directory !exist
    logit "Creating VSTS Agent $i of $agentcount..."                   # log stuff
    cd $installdir                                                     # cd to installdir
    logit "Creating agent directory: $agentname$i."                    # log stuff
    su - $vstsuid -c `/bin/mkdir -p $installdir/$agentname$i`    # create agent folder
    chown $vstsuid:$vstsgrp $installdir/$agentname$i
    logit "Extracting agent tar file: $(basename $agenttarball)."
    tar -xzvf $(basename $agenttarball) -C $installdir/$agentname$i    # extract the agent tar file
    chmod a+rx -R $installdir/$agentname$i                             # set perms, just in case
    logit "Configuring agent $installdir/$agentname$i"
  fi
done

# return exitcode
END=$(date +$SECONDS)
ELAPSED=$(($END-$START))
logit "*** Runtime: $(( $(($END-$START)) / 60)) mins:$(( $(($END-$START)) % 60)) sec."
logit "END RUN"

exit $?