#!/bin/bash
#
# pg_fw_rules.sh
#
# TO DO: Take host and port as input params
#######################
## Script vars
#######################
scriptname=`basename ${BASH_SOURCE[0]}`
logdir="/mnt/resource"
logfile="$scriptname.log"

kira_webapi1="#{var_webapi_vm_ip_node_1}#"
kira_webapi2="#{var_webapi_vm_ip_node_2}#"
kira_worker1="#{var_worker_vm_ip_node_1}#"
kira_worker2="#{var_worker_vm_ip_node_2}#"
kira_coord="#{var_rmq_vm_ip}#"
pg_port=5432

## Logger function
#######################
function logit {
  echo -e "$*"
  echo -e "$(date +%Y/%m/%d-%H:%M:%S) $*" | sudo /bin/tee -a $logdir/$logfile
}

## Apply Firewall Rules
#######################
function applyFirewallRules {
  logit "applyFirewallRules: Applying Firewall Rules"

  # add other kira nodes to trusted zone
  logit "applyFirewallRules: Get Active Zones"
  /usr/bin/firewall-cmd --list-all-zones

  # add other kira nodes to trusted zone
  /usr/bin/firewall-cmd --permanent --zone=trusted --add-source=$kira_webapi1/32
  /usr/bin/firewall-cmd --permanent --zone=trusted --add-source=$kira_webapi2/32
  /usr/bin/firewall-cmd --permanent --zone=trusted --add-source=$kira_worker1/32
  /usr/bin/firewall-cmd --permanent --zone=trusted --add-source=$kira_worker2/32
  /usr/bin/firewall-cmd --permanent --zone=trusted --add-source=$kira_coord/32
  /usr/bin/firewall-cmd --permanent --zone=trusted --add-port=$pg_port/tcp

  /usr/bin/firewall-cmd --reload

  # add other kira nodes to trusted zone
  logit "applyFirewallRules: Get updated Active Zones"
  /usr/bin/firewall-cmd --list-all-zones

  logit "applyFirewallRules: Done. Exit code: $?"
}

#######################
## Main processing
#######################
logit `date '+RUN DATE: %m/%d/%y%nRUN TIME:%H:%M:%S'`
START=$(date +$SECONDS)
echo
echo "*** All output logged to $logdir/$logfile ***"
echo

# getopts
#######################
while getopts :t:h FLAG; do
    case $FLAG in 
        t) type=$OPTARG ;;
        h) usage ;;
        \?) echo -e \\n"Invalid Option"
            usage 
            break
            ;;
    esac
done
shift "$((OPTIND-1))"

applyFirewallRules      # call aapplyFirewallRules

logit "Final Return Code: $?"
# return exitcode
END=$(date +$SECONDS)
ELAPSED=$(($END-$START))
logit "*** Runtime: $(( $(($END-$START)) / 60)) mins:$(( $(($END-$START)) % 60)) sec."
logit "END RUN"

exit $?
