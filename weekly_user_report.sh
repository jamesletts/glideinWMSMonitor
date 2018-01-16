#!/bin/bash
if [ -z $glideinWMSMonitor_OUTPUT_DIR ] ; then
  echo "Error, glideinWMSMonitor_OUTPUT_DIR not defined!"
  exit 1
else
  source $glideinWMSMonitor_RELEASE_DIR/bashrc
fi
OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/weekly-report-user-2017.txt
dashboard_user_report 7 56 > $OUTFILE

OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/monthly-report-user-2017.txt
dashboard_user_report 31 1 2017-02-01            > $OUTFILE
dashboard_user_report 28 1 2017-03-01 | tail -1 >> $OUTFILE
dashboard_user_report 31 1 2017-04-01 | tail -1 >> $OUTFILE
dashboard_user_report 30 1 2017-05-01 | tail -1 >> $OUTFILE
dashboard_user_report 31 1 2017-06-01 | tail -1 >> $OUTFILE
dashboard_user_report 30 1 2017-07-01 | tail -1 >> $OUTFILE
dashboard_user_report 31 1 2017-08-01 | tail -1 >> $OUTFILE
dashboard_user_report 31 1 2017-09-01 | tail -1 >> $OUTFILE
dashboard_user_report 30 1 2017-10-01 | tail -1 >> $OUTFILE
dashboard_user_report 31 1 2017-11-01 | tail -1 >> $OUTFILE
dashboard_user_report 30 1 2017-12-01 | tail -1 >> $OUTFILE
dashboard_user_report 31 1 2018-01-01 | tail -1 >> $OUTFILE

exit
