#!/bin/bash

# ---------------------------------------------------
# USE THIS SCRIPT ONLY-FOR-SELF-SIGNED CERTIFICATES
# ---------------------------------------------------

source config.env

if [[ $# -ne 0 ]]; then
    echo "Illegal number of parameters"
    exit 1
fi

cd keystores
# Generate a CA certificate
echo "--------------------------------------------------------------------------"
echo "Generating local CA"
openssl req -new -newkey rsa:4096 -x509 -keyout xpaas.key -out xpaas.crt -days 3650 -subj "/CN=xpaas-sso.ca" -passin pass:${CA_PASSWORD} -passout pass:${CA_PASSWORD}

# Sign the certificate sign request with the CA certificate
echo "--------------------------------------------------------------------------"
echo "Self-Signing the certificate sign request for the HTTPS keystore"
openssl x509 -trustout -req -CA xpaas.crt -CAkey xpaas.key -in sso.csr -out sso.crt -days 3650 -CAcreateserial -passin pass:${CA_PASSWORD}

cd ..

echo "--------------------------------------------------------------------------"
echo "Successfully created CA, self-signed HTTPS certificate from CSR (into keystores directory)"
