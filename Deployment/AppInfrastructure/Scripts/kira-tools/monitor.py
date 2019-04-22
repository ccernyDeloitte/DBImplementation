#!/usr/bin/env python
#
# Script that reads node's role and hostnames for db, rabbitmq, zookeeper and will:
# 1) try to connect to db, rabitmq, zookeeper, logging to a file if there's a connection failure.
# 2) checks if the container is Up
# 3) check docker logs for critical errors (like OOM)
# (script needs to be in same dir as node.conf, common.conf)
################################################################
# KIRA PROVIDED SOFTWARE
# JCL: Monitoring moved to Azure. Docker logs are redirected. 
################################################################

version = "1.7"

import ConfigParser
import os
import socket
import logging
import smtplib
from email.mime.text import MIMEText
from smtplib import SMTPException
import shlex, subprocess

# Constants
TIMEOUT = 3 # socket timeout, ideally a bit less than app connections timeouts
LOGFILE = '/opt/kira/log/monitor.log'
EMAIL_ALERT = True
EMAIL_SERVER = 'smtp.us.deloitte.com'
EMAIL_SUBJECT = 'Kira Monitor: Alert in Deloitte Servers'
EMAIL_RECEIVERS = ['usauditdevopsame@deloitte.com']

# set up logging to a file
logging.basicConfig(format='%(asctime)s %(message)s', filename=LOGFILE, level=logging.INFO)
#logging.info('Hello, this is monitor')

# read common.conf and node.conf to get what type of node I am and where rabbit, zokeeper and db hosts are
config = ConfigParser.SafeConfigParser()
config.read(os.path.join(os.path.abspath(os.path.dirname(__file__)),'common.conf'))
config.read(os.path.join(os.path.abspath(os.path.dirname(__file__)),'node.conf'))

def sendmail(body):
    msg = MIMEText(body)
    msg['Subject'] = EMAIL_SUBJECT
    msg['To'] = ", ".join(EMAIL_RECEIVERS)
    res = subprocess.Popen(['hostname'], stdout = subprocess.PIPE)
    hostname = res.stdout.read().strip()
    EMAIL_SENDER = 'root@' + hostname
    msg['From'] = EMAIL_SENDER

    try:
       smtpObj = smtplib.SMTP(EMAIL_SERVER)
       smtpObj.sendmail(EMAIL_SENDER, EMAIL_RECEIVERS, msg.as_string())
    except SMTPException as e:
       subprocess.call(["logger", "ERROR: monitor.py SMTPException: %s" % e.strerror])

# Check connectivity -----------------------------------------------------------
def connect(service, type='host'):
    ' tries to connects to a service, defined as a tuple: (host_str, port_int) '
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(TIMEOUT)
    try:
        s.connect(service)
    except Exception, e:
        message = "ERROR connecting to %s %s:%s :%s" % (type, service[0], service[1], e)
        logging.critical(message)
        if EMAIL_ALERT:
            sendmail(message)

def check_database():
    ' checks db connection (socket level only) '
    uri = config.get('postgresql','uri')
    Luri = uri.split(':')
    dbhost = Luri[0][2:]
    dbport = int(Luri[1])
    dbservice = dbhost, dbport
    connect(dbservice, 'database')

def check_rabbitmq():
    ' checks connection to all rabbitmq nodes (socket level only) '
    rabbits = config.get('rabbitmq','nodes')
    Lrabbits = rabbits.split(',')
    for rhost in Lrabbits:
        rservice = rhost, 5672
        connect(rservice, 'rabbitmq')

def check_rabbitmq_cluster():
    ' checks connection to the other rabbitmq node (socket level only) '
    rabbits = config.get('rabbitmq','nodes')
    Lrabbits = rabbits.split(',')
    me = config.get('general','hostname')
    for rhost in Lrabbits:
        if rhost == me:
            continue
        rservice = rhost, 4369
        connect(rservice, 'rabbitmq_cluster')

def check_zookeeper():
    ' checks connection to all zookeeper nodes (socker level only) '
    zoos = config.get('zookeeper','nodes')
    Lzoos = zoos.split(',')
    for zhost in Lzoos:
        zservice = zhost, 2181
        connect(zservice, 'zookeeper')

# check connectivity to rabbitmq, database and zookeeper if you are not any of those:
if not config.getboolean('postgresql','enabled') and not config.getboolean('rabbitmq','enabled'):
    # check database connection
    check_database()
    # check rabbitmq connection
    check_rabbitmq()
    # check zookeeper connection
    check_zookeeper()

# for rabbitmq node, check cluster & queue
if config.getboolean('rabbitmq','enabled'):
    check_rabbitmq_cluster()

# Check Logs -------------------------------------------------------------------
# execute a Linux command
def execute_command(command):
    ' executes Linux command, returns output '
    args = shlex.split(command)
    res = subprocess.Popen(args, stdout = subprocess.PIPE)
    out = res.stdout.read().strip()
    return out

def docker_logs(container):
    ' reads: docker logs container'
    log = execute_command('docker logs ' + container)
    if 'OutOfMemoryError' in log:
        message = 'ERROR OutOfMemoryError, check ' + container
        logging.critical(message)
        if EMAIL_ALERT:
            sendmail(message)

def container_up(container):
    ' checks woth docker ps if container is Up '
    dps = execute_command('docker ps')
    if not 'Up' in dps or not container in dps:
        message = 'WARN Docker container down, check ' + container
        logging.critical(message)
        if EMAIL_ALERT:
            sendmail(message)

def docker_logs_restart(container):
    ' reads: docker logs container'
    log = execute_command('docker logs ' + container)
    if 'OutOfMemoryError' in log:
        message = 'ERROR OutOfMemoryError, restarting ' + container
        logging.critical(message)
        command = '/opt/kira/config/de clean ' + container
        logging.critical(execute_command(command))
        command = '/opt/kira/config/de init ' + container
        logging.critical(execute_command(command))
        if EMAIL_ALERT:
            sendmail(message)
    #elif 'IllegalArgumentException' in log:
    #    message = 'ERROR IllegalArgumentException, restarting ' + container
    #    logging.critical(message)
    #    command = '/opt/kira/config/de clean ' + container
    #    logging.critical(execute_command(command))
    #    command = '/opt/kira/config/de init ' + container
    #    logging.critical(execute_command(command))
    #    if EMAIL_ALERT:
    #        sendmail(message)

try:
    # check logs for errors
    # restart scheduler, web, jamie-learn
    if config.getboolean('scheduler','enabled'):
        container_up('scheduler')
        docker_logs_restart('scheduler')

    if config.getboolean('web','enabled'):
        container_up('web')
        docker_logs_restart('web')

    if config.getboolean('jamie-learn','enabled'):
        container_up('jamie-learn')
        docker_logs_restart('jamie-learn')

    # alert for other containers
    if config.getboolean('jamie-export','enabled'):
        container_up('jamie-export')
        docker_logs('jamie-export')

    if config.getboolean('doc-converter','enabled'):
        container_up('doc-converter')
        docker_logs('doc-converter')

    if config.getboolean('jamie','enabled'):
        container_up('jamie')
        docker_logs('jamie')

    if config.getboolean('rabbitmq','enabled'):
        container_up('rabbitmq')

    if config.getboolean('zookeeper','enabled'):
        container_up('zookeeper')
        # don't docker logs zookeeper, log is superbig and timesout

    if config.getboolean('cluster','enabled'):
        container_up('cluster')
        docker_logs('cluster')

except Exception as e:
    logging.critical('Monitor error: ' + str(e))