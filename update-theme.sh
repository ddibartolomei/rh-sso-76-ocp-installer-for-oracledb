#!/bin/bash

source config.env

if [[ $# -ne 0 ]]; then
    echo "Illegal number of parameters"
    exit 1
fi


echo "Replacing ${SSO_THEME_FILENAME} in configmap rhsso-themes-config and overriting related volume settings on dc/sso"

oc delete configmap rhsso-themes-config -n ${RHSSO_NAMESPACE} && oc create configmap rhsso-themes-config --from-file=./${SSO_THEME_FILENAME} -n ${RHSSO_NAMESPACE}
oc set volume dc/sso --add --overwrite --name=rhsso-themes-config --mount-path=/opt/eap/standalone/deployments/${SSO_THEME_FILENAME} --sub-path=${SSO_THEME_FILENAME} -t configmap --configmap-name=rhsso-themes-config -n ${RHSSO_NAMESPACE}