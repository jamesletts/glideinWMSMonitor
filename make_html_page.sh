#!/bin/bash
if [ -z $glideinWMSMonitor_OUTPUT_DIR ] ; then
  echo "Error, glideinWMSMonitor_OUTPUT_DIR not defined!"
  exit 1
else
  source $glideinWMSMonitor_RELEASE_DIR/bashrc
fi

OUTFILE=$glideinWMSMonitor_OUTPUT_DIR/test.html
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
  npools=`grep Total $file | awk '($1=="Total"){printf("%s,%s],\n",$2,$3)}' | wc -l`
  if [ $npools -eq 3 ] ; then
    basename $file | awk -FZ '{print $2}' | awk -F\. '{printf("          [\x27%s\x27,",$1)}' >>$OUTFILE
    grep Total $file | awk '($1=="Total"){printf("%s,%s],\n",$2,$3)}' | head -1 >>$OUTFILE
  fi
done
endchart Jobs 'Number of Running and Pending Jobs (Analysis Operations Pool - CRAB2)' >>$OUTFILE

beginchart GlobJobs Time Running_Jobs Pending_Jobs >>$OUTFILE
for file in $FILES ; do 
  npools=`grep Total $file | awk '($1=="Total"){printf("%s,%s],\n",$2,$3)}' | wc -l`
  if [ $npools -eq 3 ] ; then
    basename $file | awk -FZ '{print $2}' | awk -F\. '{printf("          [\x27%s\x27,",$1)}' >>$OUTFILE
    grep Total $file | awk '($1=="Total"){printf("%s,%s],\n",$2,$3)}' | tail -2 | head -1 >>$OUTFILE
  fi
done
endchart GlobJobs 'Number of Running and Pending Jobs (Global Pool - CRAB3)' >>$OUTFILE

beginchart ProdJobs Time Running_Jobs Pending_Jobs >>$OUTFILE
for file in $FILES ; do 
  npools=`grep Total $file | awk '($1=="Total"){printf("%s,%s],\n",$2,$3)}' | wc -l`
  if [ $npools -eq 3 ] ; then
    basename $file | awk -FZ '{print $2}' | awk -F\. '{printf("          [\x27%s\x27,",$1)}' >>$OUTFILE
    grep Total $file | awk '($1=="Total"){printf("%s,%s],\n",$2,$3)}' | tail -1 >>$OUTFILE
  fi
done
endchart ProdJobs 'Number of Running and Pending Jobs (Monte Carlo Production Pool)' >>$OUTFILE

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

schedd_chart(){
  CHART_NAME=$1
  SCHEDD_NAME=$2
  cat <<EOF
      google.setOnLoadCallback(drawChart${CHART_NAME});
      function drawChart${CHART_NAME}() {
        var data = google.visualization.arrayToDataTable([
          [ 'Time', 'Running Jobs', 'Pending Jobs' ],
EOF
  for file in $FILES ; do
    basename $file | awk -FZ '{print $2}' | awk -F\. '{printf("          [\x27%s\x27,",$1)}'
    string=`grep $SCHEDD_NAME $file | head -1`
    if [ "X$string" == "X" ] ; then
      printf "0,0],\n"
    else
      echo $string | awk '{printf("%s,%s],\n",$3,$4)}'
    fi
  done
  cat <<EOF
        ]);

        var options = {
          title: 'Pending and Running Jobs on $SCHEDD_NAME',
          hAxis: {title: 'Last 24h',  titleTextStyle: {color: '#333'}},
          vAxis: {minValue: 0}
        };

        var chart = new google.visualization.AreaChart(document.getElementById('chart_${CHART_NAME}'));
        chart.draw(data, options);
      }
EOF
}

schedd_chart sub4  submit-4       >>$OUTFILE
schedd_chart sub5  submit-5       >>$OUTFILE
schedd_chart sub6  submit-6       >>$OUTFILE
schedd_chart unl   hcc-crabserver >>$OUTFILE
schedd_chart vo20  vocms20        >>$OUTFILE
schedd_chart vo83  vocms83        >>$OUTFILE
schedd_chart vo95  crab3test-2    >>$OUTFILE
schedd_chart vo96  crab3test-3    >>$OUTFILE
schedd_chart v109  crab3test-4    >>$OUTFILE
schedd_chart v114  crab3test-5    >>$OUTFILE

cat >>$OUTFILE <<EOF
    </script>
  </head>
  <body>
  <header>
  <h1 style="background-color:green;">CMS Analysis Monitoring for glideinWMS (remoteGlidein)</h1>
  </header>
  <div>
    <div id="chart_Jobs"     style="width: 700px; height: 300px;"></div>
    <div id="chart_GlobJobs" style="width: 700px; height: 300px;"></div>
    <div id="chart_ProdJobs" style="width: 700px; height: 300px;"></div>
  </div>
  <pre>
EOF

cat $INFILE >>$OUTFILE

cat >>$OUTFILE <<EOF
  </pre>
  <div>
    <div id="chart_Nego" style="width: 600px; height: 300px;"></div>
    <div id="chart_Coll" style="width: 600px; height: 300px;"></div>
    <div id="chart_unl"  style="width: 600px; height: 300px;"></div>
    <div id="chart_sub4" style="width: 600px; height: 300px;"></div>
    <div id="chart_sub6" style="width: 600px; height: 300px;"></div>
    <div id="chart_vo20" style="width: 600px; height: 300px;"></div>
    <div id="chart_vo83" style="width: 600px; height: 300px;"></div>
    <div id="chart_sub5" style="width: 600px; height: 300px;"></div>
    <div id="chart_vo95" style="width: 600px; height: 300px;"></div>
    <div id="chart_vo96" style="width: 600px; height: 300px;"></div>
    <div id="chart_v109" style="width: 600px; height: 300px;"></div>
    <div id="chart_v114" style="width: 600px; height: 300px;"></div>
  </div>
  </body>
</html>
EOF

exit 0
