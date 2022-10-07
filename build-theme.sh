#!/bin/bash

source config.env

if [[ $# -ne 0 ]]; then
    echo "Illegal number of parameters"
    exit 1
fi

echo "Generating ${SSO_THEME_FILENAME} using content in theme-src directory"
cd theme-src
jar cMf ../${SSO_THEME_FILENAME} *
cd ..
