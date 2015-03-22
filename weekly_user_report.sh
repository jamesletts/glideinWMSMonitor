#!/bin/bash
if [ -z $glideinWMSMonitor_OUTPUT_DIR ] ; then
  echo "Error, glideinWMSMonitor_OUTPUT_DIR not defined!"
  exit 1
else
  source $glideinWMSMonitor_RELEASE_DIR/bashrc
fi
OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/weekly-report-user-`/bin/date +%Y-%m-%d`.txt
#dashboard_user_report 7 30 > $OUTFILE

OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/monthly-report-user-2014.txt
dashboard_user_report 31 1 2014-02-01            > $OUTFILE
dashboard_user_report 28 1 2014-03-01 | tail -1 >> $OUTFILE
dashboard_user_report 31 1 2014-04-01 | tail -1 >> $OUTFILE
dashboard_user_report 30 1 2014-05-01 | tail -1 >> $OUTFILE
dashboard_user_report 31 1 2014-06-01 | tail -1 >> $OUTFILE
dashboard_user_report 30 1 2014-07-01 | tail -1 >> $OUTFILE
dashboard_user_report 31 1 2014-08-01 | tail -1 >> $OUTFILE
dashboard_user_report 31 1 2014-09-01 | tail -1 >> $OUTFILE
dashboard_user_report 30 1 2014-10-01 | tail -1 >> $OUTFILE
dashboard_user_report 31 1 2014-11-01 | tail -1 >> $OUTFILE
dashboard_user_report 30 1 2014-12-01 | tail -1 >> $OUTFILE
dashboard_user_report 31 1 2015-01-01 | tail -1 >> $OUTFILE

exit
