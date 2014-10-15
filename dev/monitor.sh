#!/bin/sh

source /home/letts/Monitor/glideinWMSMonitor/dev/bashrc

run() {

  COLLECTOR1=$1
  COLLECTOR2=$2
  NAME=$3
  
  export TMPDIR=$glideinWMSMonitor_OUTPUT_DIR/tmp_$$
  mkdir $TMPDIR
  
  OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/monitor-summary-${NAME}-`/bin/date +%F-Z%R -u`.json
  monitor_pool_json_summary_table $COLLECTOR1 $COLLECTOR2 $NAME > $OUTFILE
  ln -sf $OUTFILE $glideinWMSMonitor_OUTPUT_DIR/latest-summary-${NAME}.json
  
  OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/monitor-site-${NAME}-`/bin/date +%F-Z%R -u`.json
  monitor_pool_json_site_table $COLLECTOR1 $COLLECTOR2 $NAME > $OUTFILE
  ln -sf $OUTFILE $glideinWMSMonitor_OUTPUT_DIR/latest-site-${NAME}.json
  
  rmdir $TMPDIR

}

run vocms097.cern.ch vocms099.cern.ch global
run glidein-collector.t2.ucsd.edu glidein-collector-2.t2.ucsd.edu  analysisops  
#run vocms97.cern.ch cmssrv119.fnal.gov production

exit
