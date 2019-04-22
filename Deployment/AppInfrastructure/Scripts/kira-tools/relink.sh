#!/bin/bash
# Target NODE: ALL NODES
################################################################
# KIRA PROVIDED SOFTWARE
################################################################

# change directory to /opt/kira/jars/
cd /opt/kira/jars/

for module in de.doc-converter de.jamie de.scheduler de.web kira.configuration kira.cmd kira.sdk kira-deloitte-stats de.app-collector
do
    target=`ls -1 | grep "^${module}-.*-standalone\.jar$" | sort -V | tail -1`
    [ -z "${target}" ] && continue
    echo Setting active version of ${module} to ${target}

    ln -sf ${target} ${module}.jar
done

# set kira.config to kira.configuration-1.0-deloitte.jar
ln -sf kira.configuration-1.0.jar kira.configuration-1.0-deloitte.jar
ln -sf kira.configuration-1.0-deloitte.jar kira.configuration.jar

# Make the kira user owner of all files for consistency 
chown -R kira: /opt/kira/jars/
# restore SELinux contexts
restorecon -Rv /opt/kira/jars