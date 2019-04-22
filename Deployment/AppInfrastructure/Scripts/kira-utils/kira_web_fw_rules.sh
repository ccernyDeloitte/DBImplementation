#!/bin/bash
#
# kira_web_fw_rules
#
# Sets firewall and iptable rules on Kira Web Hosts
#######################
## Script vars
#######################
scriptname=`basename ${BASH_SOURCE[0]}`
logdir="/mnt/resource"
logfile="$scriptname.log"

kira_worker1="#{var_worker_vm_ip_node_1}#"
kira_worker2="#{var_worker_vm_ip_node_2}#"
kira_coord="#{var_rmq_vm_ip}#"
pg_host="#{var_pg_vm_ip}#"

#######################
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

  # add other kira nodes to trusted zone if not in rules already
  if [[ $(firewall-cmd --zone=trusted --list-sources | grep -c "$kira_webapi1") == 0 ]]; then
    logit "applyFirewallRules: Adding source $kira_webapi1 to trusted zone"
    /usr/bin/firewall-cmd --permanent --zone=trusted --add-source=$kira_webapi1
  fi 

  # same source, skip adding the second
  # this logic applies to envs with multiple nodes
  if [[ $(firewall-cmd --zone=trusted --list-sources | grep -c "$kira_webapi2") == 0 ]]; then
    logit "applyFirewallRules: Adding source $kira_webapi2 to trusted zone"
    /usr/bin/firewall-cmd --permanent --zone=trusted --add-source=$kira_webapi2
  fi
  
  if [[ $(firewall-cmd --zone=trusted --list-sources | grep -c "$kira_coord") == 0 ]]; then
    logit "applyFirewallRules: Adding source $kira_coord to trusted zone"
    /usr/bin/firewall-cmd --permanent --zone=trusted --add-source=$kira_coord
  fi

  if [[ $(firewall-cmd --zone=trusted --list-sources | grep -c "$pg_host") == 0 ]]; then
    logit "applyFirewallRules: Adding source $pg_host to trusted zone"
    /usr/bin/firewall-cmd --permanent --zone=trusted --add-source=$pg_host
  fi

  # enable http & https in the public zone  
  if [[ $(firewall-cmd --zone=public --list-services | grep -c "http") == 0 ]]; then
    logit "applyFirewallRules: Adding service HTTP to public zone"
    /usr/bin/firewall-cmd --zone=public --permanent --add-service=http

    if [[ $(firewall-cmd --list-ports | grep -c "80/tcp") == 0 ]]; then
      logit "applyFirewallRules: Opening up HTTP Port 80"
      /usr/bin/firewall-cmd --add-port=80/tcp
      /usr/bin/firewall-cmd --permanent --add-port=80/tcp
    fi
  fi

  # enable http & https in the public zone  
  if [[ $(firewall-cmd --zone=public --list-services | grep -c "https") == 0 ]]; then
    logit "applyFirewallRules: Adding service HTTPS to public zone"
    /usr/bin/firewall-cmd --zone=public --permanent --add-service=https

    if [[ $(firewall-cmd --list-ports | grep -c "443/tcp") == 0 ]]; then
      logit "applyFirewallRules: Opening up HTTP Port 443"
        /usr/bin/firewall-cmd --add-port=443/tcp
        /usr/bin/firewall-cmd --permanent --add-port=443/tcp
    fi
  fi

  # reload firewall
  /usr/bin/firewall-cmd --reload

  logit "applyFirewallRules: Get updated Active Zones"
  /usr/bin/firewall-cmd --list-all-zones

  logit "applyFirewallRules: Done. Exit code: $?"
}

## Apply docker iptables
#######################
function applyDockerIptables {
  logit "applyDockerIptables: Applying Docker Iptables"

  # apply iptables for docker
  /usr/sbin/iptables --wait -t nat -A DOCKER -p tcp -d 0/0 --dport 4443 -j DNAT --to-destination 172.17.0.2:8443
  /usr/sbin/iptables -t nat -A DOCKER -p tcp --dport 443 -j DNAT --to-destination 172.17.0.2:8443
  /usr/sbin/iptables -t nat -A POSTROUTING -j MASQUERADE -p tcp --source 172.17.0.2 --destination 172.17.0.2 --dport 8443
  /usr/sbin/iptables -A DOCKER -j ACCEPT -p tcp --destination 172.17.0.2 --dport 8443 

  # list iptables for docker
  /usr/sbin/iptables -S | grep -i docker

  # restart firewwallD 
  systemctl restart firewalld.service

  logit "applyDockerIptables: Done. Exit code: $?"
}

#######################
## Main processing
#######################
logit `date '+RUN DATE: %m/%d/%y%nRUN TIME:%H:%M:%S'`
START=$(date +$SECONDS)
echo
echo "*** All output logged to $logdir/$logfile ***"
echo

applyFirewallRules        # call aapplyFirewallRules
applyDockerIptables       # call applyDockerIptables

logit "Final Return Code: $?"
# return exitcode
END=$(date +$SECONDS)
ELAPSED=$(($END-$START))
logit "*** Runtime: $(( $(($END-$START)) / 60)) mins:$(( $(($END-$START)) % 60)) sec."
logit "END RUN"

exit $?
