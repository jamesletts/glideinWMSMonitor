#!/bin/bash
if [ -z $glideinWMSMonitor_OUTPUT_DIR ] ; then
  echo "Error, glideinWMSMonitor_OUTPUT_DIR not defined!"
  exit 1
else
  source $glideinWMSMonitor_RELEASE_DIR/bashrc
fi

OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/test2.html
INFILE=$glideinWMSMonitor_OUTPUT_DIR/latest.txt
FILES=`find $glideinWMSMonitor_OUTPUT_DIR -type f -name 'monitor-anaops-2014*.txt' -mtime -1 | sort`

# Reference: https://developers.google.com/chart/interactive/docs/gallery/areachart

# beginning of the html file:
cat >$OUTFILE <<EOF
<html>
  <head>
    <script type="text/javascript" src="https://www.google.com/jsapi"></script>
    <script type="text/javascript">
      google.load("visualization", "1", {packages:["corechart"]});
EOF

# function to write the beginning of a chart function:
beginchart() {
  NAME=$1
  shift
  cat <<EOF
      google.setOnLoadCallback(drawChart${NAME});
      function drawChart${NAME}() {
        var data = google.visualization.arrayToDataTable([
EOF
  printf "          ["
  while [ $# -gt 1 ] ; do
    printf "\'%s\'," $1 | tr '_' ' '  
    shift
  done
  printf "\'%s\'],\n" $1 | tr '_' ' '
  return
}

endchart() {
  NAME=$1
  shift
  cat <<EOF
        ]);

        var options = {
          title: '$@',
          hAxis: {title: 'Last 24h',  titleTextStyle: {color: '#333'}},
          vAxis: {minValue: 0}
        };

        var chart = new google.visualization.AreaChart(document.getElementById('chart_${NAME}'));
        chart.draw(data, options);
      }
EOF
  return
}

beginchart Jobs Time Running_Jobs Pending_Jobs >>$OUTFILE
for file in $FILES ; do 
  basename $file | awk -FZ '{print $2}' | awk -F\. '{printf("          [\x27%s\x27,",$1)}' >>$OUTFILE
  grep Total $file | awk '($1=="Total"){printf("%s,%s],\n",$2,$3)}' | head -1 >>$OUTFILE
done
endchart Jobs 'Number of Running and Pending Jobs (Analysis Operations Pool)' >>$OUTFILE


beginchart Nego Time Nego_Cycle_\(s\) >>$OUTFILE
for file in $FILES ; do 
  basename $file | awk -FZ '{print $2}' | awk -F\. '{printf("          [\x27%s\x27,",$1)}' >>$OUTFILE
  grep Nego  $file | head -1 | awk '(NF==7){print $NF}' | sed 's/s$//' | awk '{printf("%s],\n",$1)}' >>$OUTFILE
done
endchart Nego 'Negotiation Cycle Time (Analysis Operations Pool)' >>$OUTFILE


beginchart Coll Time Job_Difference >>$OUTFILE
for file in $FILES ; do 
  basename $file | awk -FZ '{print $2}' | awk -F\. '{printf("          [\x27%s\x27,",$1)}' >>$OUTFILE
  grep Difference  $file | head -1 | awk '(NF==13){print $NF}' | awk '{printf("%s],\n",$1)}' >>$OUTFILE
done
endchart Coll 'Running Job Difference Between HA Collectors (Analysis Operations Pool)' >>$OUTFILE

beginchart UNL  Time Running_Jobs Pending_Jobs >>$OUTFILE
for file in $FILES ; do 
  basename $file | awk -FZ '{print $2}' | awk -F\. '{printf("          [\x27%s\x27,",$1)}' >>$OUTFILE
  string=`grep hcc-crabserver  $file | head -1`
  if [ "X$string" == "X" ] ; then
    printf "0,0],\n" >>$OUTFILE
  else 
    echo $string | awk '{printf("%s,%s],\n",$3,$4)}' >>$OUTFILE
  fi
done
endchart UNL  'Number of Running and Pending Jobs (hcc-crabserver.unl.edu)' >>$OUTFILE


beginchart sub6  Time Running_Jobs Pending_Jobs >>$OUTFILE
for file in $FILES ; do 
  basename $file | awk -FZ '{print $2}' | awk -F\. '{printf("          [\x27%s\x27,",$1)}' >>$OUTFILE
  string=`grep submit-6  $file | head -1`
  if [ "X$string" == "X" ] ; then
    printf "0,0],\n" >>$OUTFILE
  else 
    echo $string | awk '{printf("%s,%s],\n",$3,$4)}' >>$OUTFILE
  fi
done
endchart sub6  'Number of Running and Pending Jobs (submit-6.t2.ucsd.edu)' >>$OUTFILE


beginchart sub4  Time Running_Jobs Pending_Jobs >>$OUTFILE
for file in $FILES ; do 
  basename $file | awk -FZ '{print $2}' | awk -F\. '{printf("          [\x27%s\x27,",$1)}' >>$OUTFILE
  string=`grep submit-4  $file | head -1`
  if [ "X$string" == "X" ] ; then
    printf "0,0],\n" >>$OUTFILE
  else 
    echo $string | awk '{printf("%s,%s],\n",$3,$4)}' >>$OUTFILE
  fi
done
endchart sub4  'Number of Running and Pending Jobs (submit-4.t2.ucsd.edu)' >>$OUTFILE



cat >>$OUTFILE <<EOF
    </script>
  </head>
  <body>
  <header>
  <h1 style="background-color:green;">CMS Analysis Monitoring for glideinWMS (remoteGlidein)</h1>
  </header>
  <div>
    <div id="chart_Jobs" style="width: 600px; height: 300px;"></div>
    <div id="chart_Nego" style="width: 600px; height: 300px;"></div>
    <div id="chart_Coll" style="width: 600px; height: 300px;"></div>
    <div id="chart_UNL"  style="width: 600px; height: 300px;"></div>
    <div id="chart_sub4" style="width: 600px; height: 300px;"></div>
    <div id="chart_sub6" style="width: 600px; height: 300px;"></div>
  </div>
  <pre>
EOF

cat $INFILE >>$OUTFILE

cat >>$OUTFILE <<EOF
  </pre>
  </body>
</html>
EOF

exit 0
