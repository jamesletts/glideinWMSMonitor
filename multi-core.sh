#!/bin/sh

if [ -z $glideinWMSMonitor_RELEASE_DIR ] ; then
  echo "ERROR: glideinWMSMonitor source code missing."
  exit 1
else
  source $glideinWMSMonitor_RELEASE_DIR/bashrc
fi


writeoutjsonfile() {

COLLECTOR=$1

echo "{"
echo "  \"Multi-core pilot monitoring\": {"
echo "    \"Collector\": \"$COLLECTOR\","
echo "    \"Time\": `/bin/date +%s`,"
echo "    \"Partitionable\": {"
echo "      \"header\": [\"State\",\"Activity\",\"Count\"],"
echo "      \"data\": ["

condor_status -pool $COLLECTOR        \
-const '(SlotType=?="Partitionable")' \
-format '%s ' State -format '%s\n' Activity | sort | uniq -c | \
awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}' 

echo "      ]"
echo "    }"
echo "    \"Partitionable, CurrentTime>GLIDEIN_ToRetire\": {"
echo "      \"header\": [\"State\",\"Activity\",\"Count\"],"
echo "      \"data\": ["

condor_status -pool $COLLECTOR        \
-const '(SlotType=?="Partitionable")' \
-const '(GLIDEIN_ToRetire=!=UNDEFINED)&&(CurrentTime>GLIDEIN_ToRetire)' \
-format '%s ' State -format '%s\n' Activity | sort | uniq -c | \
awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}'


echo "      ]"
echo "    }"
echo "    \"Dynamic\": {"
echo "      \"header\": [\"State\",\"Activity\",\"Count\"],"
echo "      \"data\": ["

condor_status -pool $COLLECTOR        \
-const '(SlotType=?="Dynamic")' \
-format '%s ' State -format '%s\n' Activity | sort | uniq -c | \
awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}'

echo "      ]"
echo "    }"
echo "    \"Static\": {"
echo "      \"header\": [\"State\",\"Activity\",\"Count\"],"
echo "      \"data\": ["

condor_status -pool $COLLECTOR \
-const '(SlotType=?="Static")' \
-format '%s ' State -format '%s\n' Activity | sort | uniq -c \
| awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}'


echo "      ]"
echo "    }"
echo "    \"Static Multi-core\": {"
echo "      \"header\": [\"State\",\"Activity\",\"Count\"],"
echo "      \"data\": ["

condor_status -pool $COLLECTOR \
-const '(SlotType=?="Static")' \
-format '%s ' Name  -format '%s ' State -format '%s\n' Activity \
| grep ^slot[0-9]*\@ | awk '{print $2 " " $3 }' | sort | uniq -c \
| awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}'


echo "      ]"
echo "    }"
echo "    \"Static Multi-core, CurrentTime>GLIDEIN_ToRetire\": {"
echo "      \"header\": [\"State\",\"Activity\",\"Count\"],"
echo "      \"data\": ["

condor_status -pool $COLLECTOR \
-const '(SlotType=?="Static")' \
-const '(GLIDEIN_ToRetire=!=UNDEFINED)&&(CurrentTime>GLIDEIN_ToRetire)' \
-format '%s ' Name  -format '%s ' State -format '%s\n' Activity \
| grep ^slot[0-9]*\@ | awk '{print $2 " " $3 }' | sort | uniq -c \
| awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}'


echo "      ]"
echo "    }"
echo "    \"Total Cpus\": {"
echo "      \"header\": [\"State\",\"Activity\",\"Count\"],"
echo "      \"data\": ["

condor_status -pool $COLLECTOR \
-format '%s ' Cpus  -format '%s ' State -format '%s\n' Activity \
| awk ' { for (i=$1; i>0; i--) { print $2 " " $3 } }' | sort |uniq -c \
| awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}'

echo "      ]"
echo "    }"
echo "    \"Totals\": {"
echo "      \"header\": [\"State\",\"Activity\",\"Count\"],"
echo "      \"data\": ["

condor_status -pool $COLLECTOR \
-format '%s ' State -format '%s\n' Activity \
| sort |uniq -c \
| awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}'

echo "      ]"
echo "    }"
echo "  }"
echo "}"

echo
echo condor_status -total -pool $COLLECTOR
condor_status -total -pool $COLLECTOR

}

JSONFILE=${glideinWMSMonitor_OUTPUT_DIR}-json/monitor-multicore-anaops-`/bin/date +%F-Z%R -u`.json
writeoutjsonfile glidein-collector.t2.ucsd.edu > $JSONFILE

JSONFILE=${glideinWMSMonitor_OUTPUT_DIR}-json/monitor-multicore-global-`/bin/date +%F-Z%R -u`.json
writeoutjsonfile vocms097.cern.ch > $JSONFILE

JSONFILE=${glideinWMSMonitor_OUTPUT_DIR}-json/monitor-multicore-production-`/bin/date +%F-Z%R -u`.json
writeoutjsonfile vocms97.cern.ch > $JSONFILE

exit
