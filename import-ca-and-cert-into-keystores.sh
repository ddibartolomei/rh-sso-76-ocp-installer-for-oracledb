#!/bin/bash

source config.env

if [[ $# -eq 0 ]]; then
    SCRIPT_NAME=`basename "$0"`
    echo "Usage:"
    echo "./$SCRIPT_NAME <signed-https-certificate-file> <ca1-certificate-file> <ca1-alias> [<ca2-certificate-file> <ca2-alias> ...]"
    echo ""
    echo "The certificate files are considered to be inside keystores directory so no relative path is required to be specified."
    echo ""
    echo "Usage example:"
    echo "./$SCRIPT_NAME mysso.crt root-ca.crt root-ca intermediate-ca.crt intermediate-ca"
    exit 0
fi

if [ $(($# % 2)) -eq 0 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

HTTPS_CERT_FILENAME=$1

CA_ARGS=("$@")

cd keystores
# ---------------------------------------
# HTTPS keystore 
# ---------------------------------------
# Import the CA certificates into the HTTPS keystore
echo "--------------------------------------------------------------------------"
echo "Importing the CA certificate(s) into the HTTPS keystore"
for (( j=1; j<$#; j=j+2 )); do
    echo "Importing ${CA_ARGS[j]} (${CA_ARGS[j+1]})"
    keytool -import -file ${CA_ARGS[j]} -alias ${CA_ARGS[j+1]} -keystore keystore.jks -noprompt -trustcacerts -storepass ${RHSSO_KEYSTORE_PASSWORD} -keypass ${RHSSO_KEYSTORE_PASSWORD}
done

# Import the signed certificate into the HTTPS keystore
echo "--------------------------------------------------------------------------"
echo "Importing the signed certificate into the HTTPS keystore"
keytool -import -file ${HTTPS_CERT_FILENAME} -alias jboss -keystore keystore.jks -noprompt -trustcacerts -storepass ${RHSSO_KEYSTORE_PASSWORD} -keypass ${RHSSO_KEYSTORE_PASSWORD}

# ---------------------------------------
# SSO TRUSTSTORE
# ---------------------------------------
# Import the CA certificate into a new Red Hat Single Sign-On server truststore
echo "--------------------------------------------------------------------------"
echo "Importing the CA certificate(s) into the truststore"
for (( j=1; j<$#; j=j+2 )); do
    echo "Importing ${CA_ARGS[j]} (${CA_ARGS[j+1]})"
    keytool -import -file ${CA_ARGS[j]} -alias ${CA_ARGS[j+1]} -keystore truststore.jks -noprompt -trustcacerts -keypass ${RHSSO_KEYSTORE_PASSWORD} -storepass ${RHSSO_KEYSTORE_PASSWORD}
done

cd ..

echo "--------------------------------------------------------------------------"
echo "Successfully imported CA certificate(s) and HTTPS certificate into HTTPS keystore and truststore (into keystores directory)"