#!/bin/bash
if [ -z $glideinWMSMonitor_OUTPUT_DIR ] ; then
  echo "Error, glideinWMSMonitor_OUTPUT_DIR not defined!"
  exit 1
else
  source $glideinWMSMonitor_RELEASE_DIR/bashrc
fi
OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/weekly-report-jobs-`/bin/date +%Y-%m-%d`.txt
OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/weekly-report-jobs-test.txt
dashboard_job_report 7 1 > $OUTFILE
exit
