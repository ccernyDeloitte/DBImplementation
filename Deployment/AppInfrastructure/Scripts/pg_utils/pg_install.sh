#!/bin/bash
#
#  pg_install.sh
#
# postgresql install and configure script
##########################################################################

#######################
## Script vars
#######################
scriptname=`basename ${BASH_SOURCE[0]}`
logdir="/mnt/resource"
logfile="$scriptname.log"
pg_lck=".pg_965.lck"
pg_home="/var/lib/pgsql"
# databases
pg_data="/var/pgdatabases"                       # pg_databases - disk 2; 512GB
# tran logs
pg_xlog="/var/pg_xlog"                           # pg_xlog - disk 3; 512GB
# archive
pg_ads="/var/pgads"                              # pg_bkp - disk 4; 512GB
# pg_log
pg_log="${pg_ads}/pg_log"
# pg_archive
pg_archive="${pg_ads}/pg_archive"
# pgtmpdir
pg_base="/var/pg_base/PostgreSQL/9.6"
# pg utils folder
udir="/var/pg_base/pg_utils"
bkpscript="pg_backup.sh"
pg_data_dir="$pg_base/data"
pg_service="postgresql-9.6.service"
pg_id='postgres'
ERR=1

export HOME="$pg_data_dir/tmp"
export TEMP="$pg_data_dir/tmp"
export TMPDIR="$pg_data_dir/tmp"

#######################
## Logger function
#######################
function logit {
  echo -e "$*"
  echo -e "$(date +%Y/%m/%d-%H:%M:%S) $*" | sudo /bin/tee -a $logdir/$logfile
}

#######################
## Verify file systems exist
#######################
function checkMounts {
  for jj in $(mount  | awk '{print $3}'); do 
    mntp+=("${jj}"); 
  done;
  for fs in $pg_data $pg_xlog $pg_ads; do
    if [[ $(printf '%s\n' ${mntp[@]} | grep -P "^${fs}$" |  wc -l) = "0" ]];  then
      logit "checkMounts: ERROR: file system $fs is not mounted"
      exit $ERR
    fi
  done
  logit "checkMounts: Done. Exit code: $?"
}

#######################
## Install Postgresql
#######################
function installPostgresql {

  if [[ ! -d $pg_data_dir ]] ; then 
    logit "installPostgresql: Creating dir: $pg_data_dir"
    mkdir -p $pg_data_dir
  fi
  
  yum install -y -q https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-redhat96-9.6-3.noarch.rpm  > /dev/null 2>&1
  # supplemental packages given by Blue Lock
  yum install -y -q https://yum.postgresql.org/9.6/redhat/rhel-7.3-x86_64/postgresql96-contrib-9.6.10-1PGDG.rhel7.x86_64.rpm > /dev/null 2>&1
  yum install -y -q https://yum.postgresql.org/9.6/redhat/rhel-7.3-x86_64/postgresql96-debuginfo-9.6.10-1PGDG.rhel7.x86_64.rpm > /dev/null 2>&1
  yum install -y -q https://yum.postgresql.org/9.6/redhat/rhel-7.3-x86_64/postgresql96-devel-9.6.10-1PGDG.rhel7.x86_64.rpm > /dev/null 2>&1
  yum install -y -q https://yum.postgresql.org/9.6/redhat/rhel-7.3-x86_64/postgresql96-docs-9.6.10-1PGDG.rhel7.x86_64.rpm > /dev/null 2>&1
  yum install -y -q https://yum.postgresql.org/9.6/redhat/rhel-7.3-x86_64/postgresql96-libs-9.6.10-1PGDG.rhel7.x86_64.rpm > /dev/null 2>&1
  yum install -y -q https://yum.postgresql.org/9.6/redhat/rhel-7.3-x86_64/postgresql96-server-9.6.10-1PGDG.rhel7.x86_64.rpm > /dev/null 2>&1

  # Install pg_repack - required by Kira
  yum install -y -q https://yum.postgresql.org/9.6/redhat/rhel-7.3-x86_64/pg_repack96-1.4.3-1.rhel7.x86_64.rpm  > /dev/null 2>&1
  
  logit "installPostgresql:   Installed: $(/usr/pgsql-9.6/bin/postgresql96-setup --version)"
  logit "installPostgresql: Done. Exit code: $?"
}

#######################
## init postgres
#######################
function init_pg {
  logit "init_pg: Initialize Postgres"
  ## init_db
  /usr/pgsql-9.6/bin/postgresql96-setup initdb

  logit "init_pg: pg_init log_loc: /var/lib/pgsql/9.6/initdb.log"
  logit "init_pg: Done. Exit code: $?"
}

#######################
## Enable postgres service
#######################
function enableService {
  logit "enableService: Initialize Postgres"
  ## enable postgres service
  cp /usr/lib/systemd/system/$pg_service /etc/systemd/system/$pg_service

  ## update PGDATA
  sed -i "s/PGDATA=.*/PGDATA=\/var\/pg_base\/PostgreSQL\/9.6\/data/g" /etc/systemd/system/$pg_service
  /bin/systemctl daemon-reload
  /bin/systemctl enable $pg_service

  logit "enableService: Done. Exit code: $?"
}

#######################
## Set permissions on the file systems
#######################
function setPermFs {
  logit "setPermFs: Postgres layout"
  for dir in "$pg_archive" "$pg_data_dir" "$pg_log"; do
    logit "$dir: creation"
    mkdir -p $dir  ||  logit "cannot create $dir" 
    chmod 700 $dir || logit "cannot set 700 permissions on $dir" 
    chown $pg_id:$pg_id $dir || logit "cannot set $pg_id ownership on $dir" 
  done  

  # pg_ads -- controlled in postgresql.conf
  logit "setPermFs:  Set permissions on Links: $pg_data, $pg_xlog & $pg_log"
  for lnki in "$pg_data" "$pg_xlog" "$pg_log" "$pg_ads"; do
    /usr/bin/sudo chown ${pg_id}:${pg_id} -R "${lnki}" || logit "cannot set $pg_id ownership on ${lnki}" 
  done

  # set perms
  /usr/bin/sudo chown ${pg_id}:${pg_id} -R $pg_base
  /usr/bin/sudo chown ${pg_id}:${pg_id} -R $pg_ads
  /usr/bin/sudo chmod 600 $pg_data_dir -R
  /usr/bin/sudo find  $pg_data_dir -type d -exec chmod 700 {} \;   #/var/pg_base/PostgreSQL/9.6/data

  logit "setPermFs: Done. Exit code: $?"
}

#######################
## Mount-Bind PG_Dirs
## $pg_data_dir/base -> /var/pgdatabases     <-- the pgdatabases
## $pg_data_dir/pg_log -> /var/pgads/pg_log  <-- the pg_log
## $pg_data_dir/pg_xlog -> /var/pg_xlog      <-- the pg_xlog
#######################
function pg_mount {
  logit "pg_mount: Mount-bind postgresql layout"

  mkdir -p $pg_data_dir                             
  chmod 700 $pg_data_dir                            
  chown $pg_id:$pg_id $pg_data_dir                 
  mkdir -p $pg_log                                  
  
  logit "pg_mount:   Adding PG_DATA/BASE to FSTAB"
  #/var/pg_base/PostgreSQL/9.6/data/base --> /var/pgdatabases
  grep -q "${pg_data_dir}/base" /etc/fstab || echo "${pg_data}        ${pg_data_dir}/base   none    bind    0       0" >> /etc/fstab

  logit "pg_mount:   Adding PG_XLOG to FSTAB"
  #/var/pg_base/PostgreSQL/9.6/data/pg_xlog --> /var/pg_xlog
  grep -q "$pg_data_dir/pg_xlog" /etc/fstab || echo "${pg_xlog}    $pg_data_dir/pg_xlog        none    bind    0       0" >> /etc/fstab
  
  logit "pg_mount:   Adding PG_LOG to FSTAB"
  #/var/pg_base/PostgreSQL/9.6/data/pg_log --> /var/pgads/pg_log
  grep -q " $pg_data_dir/pg_xlog" /etc/fstab || echo "${pg_log}       $pg_data_dir/pg_log     none    bind    0       0" >> /etc/fstab

  # pg_ads -- controlled in postgresql.conf
  /usr/bin/sudo chown ${pg_id}:${pg_id} -R $pg_data
  /usr/bin/sudo chown ${pg_id}:${pg_id} -R $pg_xlog
  /usr/bin/sudo chown ${pg_id}:${pg_id} -R $pg_log

  # set perms
  /usr/bin/sudo chown ${pg_id}:${pg_id} -R $pg_base
  /usr/bin/sudo chmod 600 $pg_data_dir -R
  /usr/bin/sudo find  $pg_data_dir -type d -exec chmod 700 {} \;   #/var/pg_base/PostgreSQL/9.6/data

  logit "pg_mount: Done. Exit code: $?"
}

## add cron-entry for postgres base backup job
#######################
function add_cron_priv {
    # this entry only gets added once. ignored on subsequent runs
    crontab -l -u $pg_id 2>/dev/null | grep -q "$bkpscript" || su - $pg_id -c "(crontab -l 2>/dev/null ; echo \"0 4 * * * ${udir}/${bkpscript}\") | crontab -" 2>/dev/null
}

#######################
## Main processing
#######################
logit `date '+RUN DATE: %m/%d/%y%nRUN TIME:%H:%M:%S'`
START=$(date +$SECONDS)
echo
echo "*** All output logged to $logdir/$logfile ***"
echo

umask 022                                   # set umask

# check for previous runs
if [[ ! -f $pg_data_dir/$pg_lck ]] ; then
  installPostgresql                                # install Postgresql
  init_pg                                          # initialize postgres
  sleep 10                                         # wait for initdb
  pg_mount                                         # reorg the file systems
  checkMounts                                      # Ensure file systems are mounted
  setPermFs                                        # setting permissions
  /bin/touch  $pg_data_dir/$pg_lck                 # create lck file
else
    logit "$scriptname: Postgres is already installed. Nothing to do."
fi

enableService                                    # Enable Service
add_cron_priv                                    # Enabling postgres base backup job

logit "Final Return Code: $?"
# return exitcode
END=$(date +$SECONDS)
ELAPSED=$(($END-$START))
logit "*** Runtime: $(( $(($END-$START)) / 60)) mins:$(( $(($END-$START)) % 60)) sec."
logit "END RUN"

exit $?
