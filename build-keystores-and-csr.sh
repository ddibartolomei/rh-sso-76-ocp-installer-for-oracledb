#!/bin/bash

source config.env

if [[ $# -ne 0 ]]; then
    echo "Illegal number of parameters"
    exit 1
fi

rm -rf keystores
mkdir keystores

cd keystores
# ---------------------------------------
# JGROUPS keystore 
# ---------------------------------------
# Generate a secure key for the JGroups keystore
echo "--------------------------------------------------------------------------"
echo "Generating a secure key for the JGroups keystore"
keytool -genseckey -alias secret-key -storetype JCEKS -keystore jgroups.jceks -storepass ${RHSSO_JGROUPS_KEYSTORE_PASSWORD} -keypass ${RHSSO_JGROUPS_KEYSTORE_PASSWORD} 

# ---------------------------------------
# HTTPS keystore 
# ---------------------------------------
# Generate a private key for the HTTPS keystore
echo "--------------------------------------------------------------------------"
echo "Generating private key for the HTTPS keystore"
keytool -genkeypair -keyalg RSA -keysize 2048 -dname "CN=${HOSTNAME_HTTPS}" -storepass ${RHSSO_KEYSTORE_PASSWORD} -keypass ${RHSSO_KEYSTORE_PASSWORD} -alias jboss -keystore keystore.jks

# Generate a certificate sign request for the HTTPS keystore (SAN certificate)
echo "--------------------------------------------------------------------------"
echo "Generating a certificate sign request for the HTTPS keystore (./keystores/sso.csr)"
keytool -certreq -keyalg rsa -alias jboss -keystore keystore.jks -ext "SAN=DNS:${HOSTNAME_HTTPS}" -file sso.csr -storepass ${RHSSO_KEYSTORE_PASSWORD} -keypass ${RHSSO_KEYSTORE_PASSWORD}

cd ..

echo "--------------------------------------------------------------------------"
echo "Successfully created JGroups keystore, HTTPS keystore and HTTPS Certificate Sign request (into keystores directory)"