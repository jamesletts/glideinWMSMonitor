#!/bin/bash

if [ -z $glideinWMSMonitor_RELEASE_DIR ] ; then
  echo "ERROR: glideinWMSMonitor source code missing."
  exit 1
else
  source $glideinWMSMonitor_RELEASE_DIR/bashrc
fi

POOLNAME="glidein-collector-2.t2.ucsd.edu"

OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/monitor-anaops-history-`/bin/date +%F-Z%R -u`.txt
condor_history_dump $POOLNAME > ${OUTFILE}.tmp
mv ${OUTFILE}.tmp $OUTFILE

OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/latest-history.txt
$glideinWMSMonitor_RELEASE_DIR/condor_history_analyze.sh $POOLNAME > ${OUTFILE}.tmp
mv ${OUTFILE}.tmp $OUTFILE

exit
