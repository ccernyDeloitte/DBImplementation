#!/bin/bash
# Generate SAML key-store
# Target NODE: WEBAPI
################################################################
# KIRA PROVIDED SOFTWARE
################################################################

clear

pemfile=/etc/ssl/certs/latham_app_kirasystems_com.pem

if [ ! -f ${pemfile} ]; then
        echo "The file ${pemfile} does not exist, please check the create_pemfile.readme"
        exit -1
fi

echo "Generating SAML Key-Store"
echo
echo "Value for password must be a diceware password at least 3 words long, and stored in secure manner."
echo
echo "Use the same generated password for the 2 password prompts."
echo
read -p "Enter password: " -r password
echo
read -p "Re-Enter password: " -r password1

if [ "${password}" != "${password1}" ]
 then
   echo
   echo
   echo "Passwords do not match!"
   echo -ne '\007'
   exit -1
fi

if [ ! -d /opt/kira/ssl ]; then
        mkdir /opt/kira/ssl
        cd /opt/kira/ssl
        chown kira:kira /opt/kira/ssl
        chmod 700 /opt/kira/ssl
fi

cd /opt/kira/ssl
awk 'BEGIN{k=1}/BEGIN/&&/KEY/{k=!k}k{print}' "${pemfile}" > chain.pem
awk 'BEGIN{k=0}/BEGIN/&&/KEY/{k=!k}k{print}' "${pemfile}" > key.pem
echo "${password}" | openssl pkcs12 -export -out keystore.pkcs12 -in chain.pem -inkey key.pem -password stdin
keytool -importkeystore -srckeystore keystore.pkcs12 -srcstoretype pkcs12 -destkeystore keystore.jks -deststoretype jks -keypass "${password}" -storepass "${password}" -srcstorepass "${password}"
cd

chmod 600 /opt/kira/ssl/keystore.jks
rm -f /opt/kira/ssl/chain.pem
rm -f /opt/kira/ssl/key.pem
rm -f /opt/kira/ssl/keystore.pkcs12

echo "" >> /opt/kira/config/common.conf
echo "# Single Sign On (SAML)"  >> /opt/kira/config/common.conf
echo "SAML_KEYSTORE=/home/de/ssl/keystore.jks"  >> /opt/kira/config/common.conf
echo "SAML_KEYSTORE_PWD=${password}" >> /opt/kira/config/common.conf
