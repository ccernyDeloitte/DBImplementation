#!/bin/bash
# setup_buildserver.sh
# Installs system prereqs and packages
# $1 = domain
# ex: setup_vmbaseconfig.sh
# $1 = DOMAIN=uscloudprod.us.deloitte.com
# $2 = ENVIRONMENTID=USAZUAUDDE
# $3 = STARSLIFECYCLE=Quality Assurance
# $4 = STARSPOD=POD
# ex: sh setup_buildserver.sh 'uscloudprod.us.deloitte.com' 'USAZUAUDDE' 'Quality Assurance' 'POD'
############################################# 

#######################
## Script vars
#######################
logdir="/mnt/resource"
logfile="setup_buildserver.log"
puppetinstalllogfile="puppet_install.log"
lckfile=".setup_buildserver.lck"
vgname="vgdata01"
vstslv="vstslv"
vstsmnt="/opt/vsts"

# supplemental dotnet installer
dotnetinstaller="/var/lib/waagent/custom-script/download/0/dotnet-install.sh"
# vsts agent install Script
agentsetupscript="/var/lib/waagent/custom-script/download/0/setup_installvstsagent.sh"
agenttarball="/var/lib/waagent/custom-script/download/0/vsts-agent-linux-x64-2.129.0.tar.gz"
installdir="/opt/vstsagents"
agentname="$(hostname)-agent"
agentcount=4

## Initialize variables to default values
domain=$1                                      # ex: usclouddev.us.deloitte.com
envid=$2                                       # ex: USAZUAUDDE
environment=$3                                     # ex: Quality Assurance
pod=$4                                         # ex: POD
rootdomain=$(echo $domain | cut -d'.' -f 2-4)  # ex: us.deloitte.com
subdomain=$(echo $domain | cut -d'.' -f 1)     # ex: usclouddev
os="Linux - Red Hat"
contact="CSD-CLIENTSOLUTIONS-AUDIT-DEVOPS"
facility="MS Azure Cloud (AZU)"
model="Virtual Machine"
osowner="STEAM"
description="LinuxVM"
shortdescription="VM for Argus"

# handle prod vs non-prd
if [[ $environment -eq "Production" ]]; then 
	pod="POD1" 
else # Set POD to POD2
	pod="POD2" 
fi

#######################
## Logger function
#######################
function logit {
  echo -e "$*"
  echo -e "$(date +%Y/%m/%d-%H:%M:%S) $*" >> $logdir/$logfile
}

#######################
## Check script setup
#######################
function checksetup {
  ## Verify User Executing Script is hyperic
  if [[ $EUID -ne 0 ]]; then
    logit "checksetup: Error: This script must be run as root" 1>&2
    exit $?
  fi
}

function updateProfile {
	logit "updateProfile: Update bash profile for user: $1."
	echo "# Add .NET Core 2.0 to my login environment \n source scl_source enable rh-dotnet20" >> /home/$1/.bash_profile
	logit "updateProfile: Done. Exit code: $?"
}

## Set deltarpm flag
function setdeltarpmflag {
	logit "setdeltarpmflag: Setting deltarpm config flag to -1."
	echo "deltarpm=-1" >> /etc/yum.conf
	logit "setdeltarpmflag: Done. Exit code: $?"
}

## updates 
function yumUpdates {
	logit "yumUpdates: Updating packages."
	yum update -y
	logit "yumUpdates: Done. Exit code: $?"
}

#######################
## cloudscript domain join
#######################
function cloudscript {
	logit "cloudscript: Incoming script Params:"
	logit "cloudscript: script input;pos1:  '$domain'"
	logit "cloudscript: script input;pos3:  '$environment'"
	logit "cloudscript: script input;pos4:  '$pod'"
	logit "cloudscript: "
	logit "cloudscript: Cloudscript Input Params:"
	logit "cloudscript: rootdomain........'$rootdomain'"
	logit "cloudscript: OS Verion.........'$os'"
	logit "cloudscript: Contact...........'$contact'"
	logit "cloudscript: Patch.............'$pod'"
	logit "cloudscript: Environment.......'$environment'"
	logit "cloudscript: Description.......'$description'"
	logit "cloudscript: ShortDescription..'$shortdescription'"

	logit "cloudscript: Running cloudscript."
	curl -sS -k "https://usstocrmitsbx.blob.core.windows.net/cloudtemplates/scripts/prodcloudscript.sh?sp=r&st=2018-07-20T22:48:31Z&se=2021-07-21T06:48:31Z&spr=https&sv=2017-11-09&sig=QZ8IDDJ9V%2BP2baqE1vyfq77qJOe12A%2FLAkms4a4JWCw%3D&sr=b" | bash -s install "$domain" root "$contact" "$contact" "$environment" "$contact" "$pod"  "$os" "$description" "$shortdescription" >> $logdir/$puppetinstalllogfile
	logit "cloudscript: Done. Exit code: $?"
}

#######################
## install prereqs
#######################
 function installPreReqs {
   logit "installPreReqs: Installing base packages"
   yum install -y samba-client 
   yum install -y samba-common 
   yum install -y cifs-utils
   yum install -y telnet
   yum install -y java-1.8.0-openjdk.x86_64 
   yum install -y lvm2 
   yum install -y tree
   yum install -y psmisc
   yum install -y screen.x86_64
   yum install -y icu
   yum install -y deltarpm
   yum install -y curl-devel 
   yum install -y expat-devel 
   yum install -y gettext-devel
   yum install -y openssl-devel
   yum install -y zlib-devel
   yum install -y gcc
   yum install -y perl-ExtUtils-MakeMaker
     
   logit "installPreReqs: Done. Exit code: $?"
}

#######################
## DotNetCore
## https://www.microsoft.com/net/download/linux-package-manager/rhel/sdk-current
#######################
function enableDotNetCore {
	logit "enableDotNetCore: Enabling dotnet core packages."
	# https://docs.microsoft.com/en-us/dotnet/core/linux-prerequisites?tabs=netcore2x
	# https://github.com/dotnet/core-setup
	# packages
	yum install rh-dotnet21 -y                           
	scl enable rh-dotnet21 bash
	
	logit "enableDotNetCore: Done. Exit code: $?"
}


#######################
## Set deltarpm flag
#######################
function setdeltarpmflag {
	logit "setdeltarpmflag: Setting deltarpm config flag to -1."
	echo "deltarpm=-1" >> /etc/yum.conf
	logit "setdeltarpmflag: Done. Exit code: $?"
}

#######################
## Setup default partitions
#######################
function partitionDisk {
	logit "partitionDisk: Partioning disk."
	
	# Eliminate /dev/sda and /dev/sdb for volume creation
	local devsdc=`lsscsi -d | grep /dev/sd | grep -v 'dev/sd[ab]' | awk '{print $7}' ORS=' '`
	local cnt=$(echo $devsdc | wc -w)
	
	# output results
	echo $cnt
	echo $devsdc
	logit "partitionDisk: Found: $devsdc. Strpes count: $cnt."

	# creating mount dir
	logit "partitionDisk: Creating mount directory."
	mkdir -p $vstsmnt 

	# Init /dev/sbc as an LVM physical volume
	logit "partitionDisk: Creating Physical volume group."
	pvcreate $devsdc 
	pvscan >> $logdir/$logfile
	
	# create volume group
	logit "partitionDisk: Creating volume group."
	vgcreate $vgname $devsdc
	vgscan >> $logdir/$logfile

	# create logical Volumes
	logit "partitionDisk: Creating logical volumes."
	lvcreate --extents 100%FREE --stripes $cnt --name $vstslv $vgname -y
	lvscan >> $logdir/$logfile

	# create filesys
	logit "partitionDisk: Creating filesystems."
	mkfs -t ext4 /dev/$vgname/$vstslv >> $logdir/$logfile

	#update fstab
	logit "partitionDisk: Update fstab."
	cp -p /etc/fstab /etc/fstab.bkp

	#echo "/dev/$vgname/$vstslv                $vstsmnt   ext4   defaults   1 2" >> /etc/fstab
	# replace using uuid: https://docs.microsoft.com/en-us/azure/virtual-machines/linux/add-disk
	uuid=`blkid | grep vgdata | awk '{print $2}' | sed -e 's/"//g'`
	echo "$uuid                $vstsmnt   ext4   defaults   1 2" >> /etc/fstab

	#mount fs
	logit "partitionDisk: Mount filesystems."
	#mount /dev/$vgname/$vstslv $vstsmnt

	# mount all
	mount -a >> $logdir/$logfile	
	
	if [ $? -ne 0 ] ; then
		logit  "partitionDisk: ERROR: Unable to create and mount the Volume ...error in volume creation command."
		exit 1
	else
		touch "$logdir/.partioned"
		logit "partitionDisk: Done. Exit code: $?"
	fi
}

## add cron entry to kick off other scripts
function adddontnetinstallercronjob {
	logit "adddontnetinstallercronjob: Scheduling script to run after reboot."
	(crontab -l ; echo "@reboot /var/lib/waagent/custom-script/download/0/dotnet-install.sh") | crontab -
	logit "adddontnetinstallercronjob: Done. Exit code: $?"
}

## add cron entry to kick off other scripts
function addvstsagentsetupcronjob {
	logit "addvstsagentsetupcronjob: Scheduling script to run after reboot."
	(crontab -l ; echo "@reboot /var/lib/waagent/custom-script/download/0/setup_installvstsagent.sh") | crontab -
	logit "addvstsagentsetupcronjob: Done. Exit code: $?"

	touch "$logdir/.croned"
}

## add cron entry to kick off other scripts
function cleanupcronjob {
	logit "cleanupcronjob: Scheduling script to run after reboot."
	(crontab -l ; echo "@reboot /var/lib/waagent/custom-script/download/0/setup_cleanupcron.sh") | crontab -
	logit "cleanupcronjob: Done. Exit code: $?"

	touch "$logdir/.croned"
}

## install azure-cli
## https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-yum?view=azure-cli-latest
function installAzureCLI {
	# Import the Microsoft repository key
	/usr/bin/rpm --import https://packages.microsoft.com/keys/microsoft.asc
	# Create local azure-cli repository information
	/usr/bin/sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
	/usr/bin/yum install -y azure-cli
}

#######################
## Install AZCopy
#######################
function installAZCopy {
	logit "installAZCopy: Installing AZCopy."
	wget -O azcopy.tar.gz https://aka.ms/downloadazcopyprlinux
	mkdir -p /opt/azcopy
	tar -xzvf azcopy.tar.gz -C /opt/azcopy
	logit "installAZCopy: Done. Exit code: $?"
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
installPreReqs                              # install prereq packages
setdeltarpmflag                             # set deltarpm config
enableDotNetCore                            # install dotnetcore
adddontnetinstallercronjob                  # schedules dotnet-install.sh
addvstsagentsetupcronjob                    # schedules setup_installvstsagent.sh
installAzureCLI                             # install Azure CLI
installAZCopy                               # install AzCopy

## partion datadisk w/ retry
if [ ! -f "$logdir/.partioned" ] ; then
	partitionDisk                           # partition disk
fi

sleep 15
cloudscript                                # domain join     

## Reboot to kick off child scripts
if [ ! -f "$logdir/.croned" ] ; then
	shutdown -r now                        # reboot
fi

logit "Final Return Code: $?"

# return exitcode
END=$(date +$SECONDS)
ELAPSED=$(($END-$START))
logit "*** Runtime: $(( $(($END-$START)) / 60)) mins:$(( $(($END-$START)) % 60)) sec."
logit "END RUN"

exit $?