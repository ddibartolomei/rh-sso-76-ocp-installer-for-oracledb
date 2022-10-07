#!/bin/bash

source config.env

RHSSO_ORACLE_IMAGESTREAM_NAME="rhsso76-openshift-oracle"
RHSSO_ORACLE_IMAGESTREAM_TAG="latest"

if [[ $# -ne 0 ]]; then
    echo "Illegal number of parameters"
    exit 1
fi

echo "--------------------------------------------------------------------------"
echo "Target namespace is ${RHSSO_NAMESPACE}"

oc policy add-role-to-user view system:serviceaccount:${RHSSO_NAMESPACE}:default -n ${RHSSO_NAMESPACE}

# ---------------------------------------------
# Create custom RH-SSO 7.6 image for Oracle DB
# ---------------------------------------------
# create and run a build to create a new image with Oracle ojdbc7 driver and related configurations inside
echo "--------------------------------------------------------------------------"
echo "Generating a new Red Hat SSO 7.6 base image with Oracle DB required files"
cd rhsso76-oracle-image
oc new-build --name ${RHSSO_ORACLE_IMAGESTREAM_NAME} --binary --strategy docker -n ${RHSSO_NAMESPACE}
oc start-build ${RHSSO_ORACLE_IMAGESTREAM_NAME} --from-dir=. -n ${RHSSO_NAMESPACE} --follow
cd ..

read -p "Press enter to continue"

# ---------------------------------------
# Create Keystores secret
# ---------------------------------------
echo "--------------------------------------------------------------------------"
# Create the secret for the HTTPS keystore, JGroups keystore and Red Hat Single Sign-On server truststore (with related passwords)
echo "Creating a secret for the HTTPS/JGroups keystores and RH-SSO truststore (and their passwords)"
oc create secret generic rhsso-keystore-secret --from-file=./keystores/keystore.jks --from-file=./keystores/jgroups.jceks --from-file=./keystores/truststore.jks --from-literal=https_ks_password="${RHSSO_KEYSTORE_PASSWORD}" --from-literal=jgroups_ks_password="${RHSSO_JGROUPS_KEYSTORE_PASSWORD}" --from-literal=truststore_password="${RHSSO_KEYSTORE_PASSWORD}" -n ${RHSSO_NAMESPACE}
oc label secret rhsso-keystore-secret application=sso -n ${RHSSO_NAMESPACE}
# Link the secret to the default service account
echo "Linking the secret to the default Service Account"
oc secrets link default rhsso-keystore-secret -n ${RHSSO_NAMESPACE}

read -p "Press enter to continue"

# ---------------------------------------------------
# Create secret for database connection credentials
# ---------------------------------------------------
echo "--------------------------------------------------------------------------"
# Create a secret for database credentials
echo "Creating a secret for database credentials"
oc create secret generic rhsso-db-secret --from-literal=db_username="${DATABASE_USERNAME}" --from-literal=db_password="${DATABASE_PASSWORD}" -n ${RHSSO_NAMESPACE}
oc label secret rhsso-db-secret application=sso -n ${RHSSO_NAMESPACE}
# Link the secret to the default service account
echo "Linking the secret to the default Service Account"
oc secrets link default rhsso-db-secret -n ${RHSSO_NAMESPACE}

# ---------------------------------------------------
# Create a config map for the custom theme
# ---------------------------------------------------
echo "--------------------------------------------------------------------------"
echo "Creating a config map for the custom theme"
oc create configmap rhsso-themes-config --from-file=./${SSO_THEME_FILENAME} -n ${RHSSO_NAMESPACE}
oc label configmap rhsso-themes-config application=sso -n ${RHSSO_NAMESPACE}
read -p "Press enter to continue"

# ---------------------------------------
# Install RH-SSO
# ---------------------------------------
echo "--------------------------------------------------------------------------"
echo "Creating the custom installation template from sso76-https-oracledb.json"
oc apply -f sso76-https-oracledb.json -n ${RHSSO_NAMESPACE}

echo "Installing RH-SSO 7.6"
oc process sso76-https-oracledb \
 -p APPLICATION_NAME="sso" \
 -p HOSTNAME_HTTP="${HOSTNAME_HTTP}" \
 -p HOSTNAME_HTTPS="${HOSTNAME_HTTPS}" \
 -p HTTPS_SECRET="rhsso-keystore-secret" \
 -p HTTPS_KEYSTORE="keystore.jks" \
 -p HTTPS_NAME="jboss" \
 -p JGROUPS_ENCRYPT_SECRET="rhsso-keystore-secret" \
 -p JGROUPS_ENCRYPT_KEYSTORE="jgroups.jceks" \
 -p JGROUPS_ENCRYPT_NAME="secret-key" \
 -p SSO_TRUSTSTORE="truststore.jks" \
 -p SSO_TRUSTSTORE_SECRET="rhsso-keystore-secret" \
 -p SSO_ADMIN_USERNAME="${ADMIN_USERNAME}" \
 -p SSO_ADMIN_PASSWORD="${ADMIN_PASSWORD}" \
 -p SSO_REALM="${REALM_NAME}" \
 -p IMAGE_STREAM_NAMESPACE="${RHSSO_NAMESPACE}" \
 -p IMAGESTREAM_NAME="${RHSSO_ORACLE_IMAGESTREAM_NAME}" \
 -p IMAGESTREAM_TAG="${RHSSO_ORACLE_IMAGESTREAM_TAG}" \
 -p DB_JDBC_URL="${DATABASE_JDBC_URL}" \
 -p DB_MIN_POOL_SIZE="${DATABASE_MIN_POOL_SIZE}" \
 -p DB_MAX_POOL_SIZE="${DATABASE_MAX_POOL_SIZE}" \
 -p DB_CREDENTIALS_SECRET="rhsso-db-secret" \
 -p SSO_THEME_CONFIG_MAP="rhsso-themes-config" \
 -p SSO_THEME_FILENAME="${SSO_THEME_FILENAME}" \
 -n ${RHSSO_NAMESPACE} \
| oc create -n ${RHSSO_NAMESPACE} -f -

echo "--------------------------------------------------------------------------"
echo "Successfully installed (check dc/sso is starting the new RHSSO POD)"