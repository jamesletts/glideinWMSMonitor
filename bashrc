#!/bin/bash

# set X509_USER_PROXY to be your valid CMS grid proxy:
export X509_USER_PROXY=/tmp/x509up_u500

# source HTCondor commands
source /etc/profile.d/condor.sh

# place for the output files
export  glideinWMSMonitor_OUTPUT_DIR="/crabprod/CSstoragePath/Monitor"

#################### MACE CHANGES ABOVE THIS LINE #################### 

# Discover the directory where the software sits:
export  glideinWMSMonitor_RELEASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo $glideinWMSMonitor_RELEASE_DIR

# source the functions to discover SiteDB, HTCondor and CMS Dashboard information
source $glideinWMSMonitor_RELEASE_DIR/sitedb_functions.sh
source $glideinWMSMonitor_RELEASE_DIR/condor_functions.sh
source $glideinWMSMonitor_RELEASE_DIR/dashboard_functions.sh
