#!/bin/bash

# source HTCondor commands
source /etc/profile.d/condor.sh

# glideinWMS Pool Central Manager:
export glideinWMS_COLLECTOR="vocms097.cern.ch"

# Location of the source code and output files for this monitor
export glideinWMSMonitor_OUTPUT_DIR="/crabprod/CSstoragePath/Monitor/json"
export glideinWMSMonitor_RELEASE_DIR="/home/letts/Monitor/glideinWMSMonitor"

################## MAKE CONFIGURATION CHANGES ABOVE THIS LINE ##################


# Create temporary file to dump HTCondor information
#TMPFILE=`mktemp -p $glideinWMSMonitor_OUTPUT_DIR -t HTCMon.tmp.XXXXXXXXXX`
TMPFILE=/crabprod/CSstoragePath/Monitor/json/HTCMon.tmp.srYclB9804


# Function to dump HTCondor information to the temporary file
GetCondorInfo() {
  condor_status -pool $glideinWMS_COLLECTOR \
    -format '%s,'  GLIDEIN_CMSSite     \
    -format '%s,'  SlotType            \
    -format '%s,'  GLIDEIN_ToRetire    \
    -format '%s,'  CPUs                \
    -format '%s,'  State               \
    -format '%s\n' Activity            \
  >$TMPFILE
  /bin/date +%s
}

NOW=`GetCondorInfo`
ALSONOW=`echo $NOW | awk '{print strftime("%F %R",$1)}'`
echo $TMPFILE has `cat $TMPFILE | wc -l` lines created at $ALSONOW.
#NOW=`/bin/date +%s`

# Function to extract from the temporary condor information file, for a
# particular site and slottype, the number of CPU cores devoted to each
# State=() and Activity=().
ExtractCondorInfo() {
  SITE=$1
  SLOTTYPE=$2
  #if [ $SITE=="All" ] ; then SITE="" ; fi
  #if [ $SLOTTYPE=="Total" ] ; then SLOTTYPE="" ; fi

  # check if retiring
  RETIRING=$3
  if [ -z $RETIRING ] ; then
    cat $TMPFILE | grep $SITE\,$SLOTTYPE | \
      awk -F\, '{print $4 " " $5 " " $6}' | \
      awk ' { for (i=$1; i>0; i--) { print $2 " " $3 } }' | sort | uniq -c | \
      awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}' 
  else
    cat $TMPFILE | grep $SITE,$SLOTTYPE | \
      awk -F\, -v NOW=$NOW '($3<NOW){print $4 " " $5 " " $6}' | \
      awk ' { for (i=$1; i>0; i--) { print $2 " " $3 } }' | sort | uniq -c | \
      awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}' 
  fi

}


WriteOutTable() {
  TITLE=$1
  echo "    \"$TITLE\": {"
  echo "      \"header\": [\"State\",\"Activity\",\"Cpus\"],"
  echo "      \"data\": ["
  ExtractCondorInfo $SITE $TITLE
  echo "        [null,null,0]"
  echo "      ]"
  echo "    },"
}


# function to write out a json file with the multi-core monitoring information
# one file per site
WriteOutJsonFile() {

  # Outfile json file for this site
  SITE=$1
  JSONFILE=${glideinWMSMonitor_OUTPUT_DIR}/monitor-${SITE}-${NOW}.json

  # Header of the json file
  echo "{"
  echo "  \"Multi-core pilot monitoring\": {"
  echo "    \"Collector\": \"$glideinWMS_COLLECTOR\","
  echo "    \"CMSSite\": \"$SITE\","
  echo "    \"Time\": $NOW,"

  # Write out the individual tables for the different types of glideins
  WriteOutTable "Partitionable"
  WriteOutTable "Partitionable Retiring"
  WriteOutTable "Dynamic"
  WriteOutTable "Dynamic Retiring"
  WriteOutTable "Static"
  WriteOutTable "Static Retiring"
  WriteOutTable "Total"
  WriteOutTable "Total Retiring" | sed -e "\$s/,//"

  # close the json file
  echo "  }"
  echo "}"
}


WriteOutJsonFile All

# Clean up
#rm $TMPFILE

exit
