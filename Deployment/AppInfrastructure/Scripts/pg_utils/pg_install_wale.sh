#!/bin/bash
# 
# pg_install_wale
# 
# This script installs wal-e for back-up & restore
# Usage: pg_install_wale.sh -k <AZ-STORAGE-ACCT-KEY> -a <STORAGE-ACCT-NAME> -p <STORAGE-ACCT-PREFIX>"
#######################
## Script vars
#######################
scriptname=`basename ${BASH_SOURCE[0]}`
logdir="/tmp"
logfile="$scriptname.log"
wale_dir="/opt/wal-e"
wale_env="/etc/wal-e.d/env"
wabs_pre="WALE_WABS_PREFIX"
wabs_acct="WABS_ACCOUNT_NAME"
wabs_key="WABS_ACCESS_KEY"
wabs_sysident="WALE_SYSLOG_IDENT"
wabs_syslog="WALE_SYSLOG_FACILITY"
wabs_log="WALE_LOG_DESTINATION"

# Initialize variables to default values
#######################
usage=false
argsnum=$#
AZKEY=k
AZACCT=a
PRFX=p

## Logger function
#######################
function logit {
  echo -e "$*"
  echo -e "$(date +%Y/%m/%d-%H:%M:%S) $*" | sudo /bin/tee -a $logdir/$logfile
}

## Check number of arguments; 3 pairs expected
#######################
function checkargs {
    if [ $argsnum -ne 6 ]; then
        echo -e \\n"Invalid Number of arguments"\\n
        usage 
        exit 2;
    fi
}

## helper function
#######################
function usage {
    /usr/bin/sudo echo -e "Usage: pg_install_wale.sh -k <AZ-STORAGE-ACCT-KEY> -a <STORAGE-ACCT-NAME> -p <STORAGE-ACCT-PREFIX>"
}

## Install Wal-e and dependencies
#######################
function installPythonEnv {
  logit "installPythonEnv: Installing Python Env"
  
  yum install -y python34-libs.x86_64
	yum install -y rh-python34-python-setuptools.noarch
	yum install -y rh-python34-python-pip.noarch 
  yum install -y python34-pip.noarch
  yum install -y python-virtualenv.noarch
  yum install -y python-devel.x86_64
  yum install -y pv.x86_64
	yum install -y lzop.x86_64

  logit "installPythonEnv: Done. Exit code: $?"
}

## Install Wal-e[azure]
## https://github.com/wal-e/wal-e#azure-blob-store
#######################
function installWale {

  # Install Wal-E (requires a python env)
  logit "installWale: Installing azure python libs"

  # install azure libs
  python3 -m install azure

  logit "installWale: Installing wale[azure]"
  # install wal-e[azure]
  python3 -m pip install wal-e[azure]

  # create wal-e dir
  mkdir -p ${wale_dir}
  logit "installWale: Creating wale directory: ${wale_dir}"

  # setup virtual env
  python3 -m venv ${wale_dir}
  logit "installWale: Creating python virtual: ${wale_dir}"

  # get wal-e version
  $wale_ver = ${wale_dir}/bin/wal-e version
  logit "installWale: Getting wal-e version: ${wale_ver}"

  logit "installWale: Done. Exit code: $?"
}


## updateWale Wal-e[azure]
## https://github.com/wal-e/wal-e#azure-blob-store
#######################
function updateWale {

  # update Wal-e
  logit "updateWale: Updating Wal-e"
  # pin python version
  python3 -m venv  ${wale_dir}

  #Upgrade pip
  logit "updateWale: Updating Wal-e"
  $wale_dir/bin/pip install --upgrade pip
  
  logit "updateWale: Upgrading wal-e to v1.1.0, from master"
  # upgrading wal-e to v1.1.0, from master
  $wale_dir/bin/pip install git+https://github.com/wal-e/wal-e.git --upgrade

  #install envdir
  $wale_dir/bin/pip3 install envdir
  logit "updateWale: Creating python virtual: ${wale_dir}"

  # get wal-e version
  $wale_ver1 = ${wale_dir}/bin/wal-e version
  logit "updateWale: Getting wal-e version: $wale_ver1"

  logit "updateWale: Done. Exit code: $?"
}


## Setup Wal-e env
## https://github.com/wal-e/wal-e#azure-blob-store
## 
## /etc/wal-e.d/env/
## ├── WABS_ACCESS_KEY
## ├── WABS_ACCOUNT_NAME
## ├── WALE_LOG_DESTINATION
## ├── WALE_SYSLOG_FACILITY
## ├── WALE_SYSLOG_IDENT
## └── WALE_WABS_PREFIX
## overwrites file contents each time
#######################
function setupWaleEnv {

  # Install Wal-E (requires a python env)
  logit "setupWaleEnv: Setup wale env"
  # create wal-e dir
  mkdir -p ${wale_env}
  # add keys  
  echo "${AZKEY}" > ${wale_env}/${wabs_key}
  echo "${AZACCT}" > ${wale_env}/${wabs_acct}
  echo "wabs://${PRFX}" > ${wale_env}/${wabs_pre}
  echo "wal-e" > ${wale_env}/${wabs_sysident}
  echo "LOCAL7" > ${wale_env}/${wabs_syslog}
  echo "syslog,stderr" > ${wale_env}/${wabs_log}
  logit "setupWaleEnv: Done. Exit code: $?"
}

# test Azure Hook
#######################
function testWale {

  # get -wal-e version
  logit "testWale: Run wal-e get version"
  $wale_dir/bin/envdir $wale_env env $wale_dir/bin/wal-e version

  # test Azure hook
  logit "testWale: Testing Azure Hook"
  $wale_dir/bin/envdir $wale_env env $wale_dir/bin/wal-e backup-list

  logit "testWale: Done. Exit code: $?"
}

#######################
## Main processing
#######################
logit `date '+RUN DATE: %m/%d/%y%nRUN TIME:%H:%M:%S'`
START=$(date +$SECONDS)
echo
echo "*** All output logged to $logdir/$logfile ***"
echo

## getopts
#######################
while getopts :k:a:p FLAG; do
    case $FLAG in 
        k) AZKEY=$OPTARG ;;
        a) AZACCT=$OPTARG ;;
        p) PRFX=$OPTARG ;;
        h) usage ;;
        \?) echo -e \\n"Invalid Option"
            usage 
            break
            ;;
    esac
done

checkargs                       # check args
installPythonEnv                # installs python env
installWale                     # installs Wal-E[azure]
setupWaleEnv                    # setup wal-e env
updateWale                      # update wal-e 
testWale                        # Test wal-e 

logit "Final Return Code: $?"

# return exitcode
END=$(date +$SECONDS)
ELAPSED=$(($END-$START))
logit "*** Runtime: $(( $(($END-$START)) / 60)) mins:$(( $(($END-$START)) % 60)) sec."
logit "END RUN"

exit $?