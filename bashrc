#!/bin/bash

# Discover the directory where the software sits:
RELEASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# source the functions to discover SiteDB, HTCondor and CMS
# Dashboard information
source $RELEASE_DIR/sitedb_functions.sh
source $RELEASE_DIR/condor_functions.sh
source $RELEASE_DIR/dashboard_functions.sh

# set X509_USER_PROXY to be your valid CMS grid proxy:
export X509_USER_PROXY=/tmp/x509up_u500
