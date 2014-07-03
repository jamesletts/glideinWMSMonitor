#!/bin/sh
source /home/letts/Monitor/glideinWMSMonitor/dev/bashrc

OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/monitor-summary-global-`/bin/date +%F-Z%R -u`.json
monitor_pool_json_summary_table vocms097.cern.ch vocms099.cern.ch global > $OUTFILE
ln -sf $OUTFILE $glideinWMSMonitor_OUTPUT_DIR/latest-summary-global.json

OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/monitor-site-global-`/bin/date +%F-Z%R -u`.json
monitor_pool_json_site_table vocms097.cern.ch vocms099.cern.ch global > $OUTFILE
ln -sf $OUTFILE $glideinWMSMonitor_OUTPUT_DIR/latest-site-global.json

exit

OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/monitor-global-`/bin/date +%F-Z%R -u`.json
monitor_pool_json_table glidein-collector.t2.ucsd.edu glidein-collector-2.t2.ucsd.edu  analysisops > $OUTFILE

OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/monitor-produc-`/bin/date +%F-Z%R -u`.json
monitor_pool_json_table vocms97.cern.ch               cmssrv119.fnal.gov               production  > $OUTFILE
