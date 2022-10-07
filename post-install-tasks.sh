#!/bin/bash

source config.env

if [[ $# -ne 0 ]]; then
    echo "Illegal number of parameters"
    exit 1
fi

echo "Removing SSO Admin username (SSO_ADMIN_USERNAME) and password (SSO_ADMIN_PASSWORD) env variables from dc/sso"
oc set env dc/sso -e SSO_ADMIN_USERNAME="" -e SSO_ADMIN_PASSWORD="" -n ${RHSSO_NAMESPACE}
# oc set env dc/sso SSO_ADMIN_USERNAME- SSO_ADMIN_PASSWORD- -n ${RHSSO_NAMESPACE}