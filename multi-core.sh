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


echo "    \"Partitionable glideins\": {"
echo "      \"header\": [\"State\",\"Activity\",\"glideins\"],"
echo "      \"data\": ["
condor_status -pool $COLLECTOR        \
-const '(SlotType=?="Partitionable")' \
-format '%s ' State -format '%s\n' Activity | sort | uniq -c | \
awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}' 
echo "        [null,null,0]"
echo "      ]"
echo "    },"


echo "    \"Partitionable glidein Cpus\": {"
echo "      \"header\": [\"State\",\"Activity\",\"Cpus\"],"
echo "      \"data\": ["
condor_status -pool $COLLECTOR        \
-const '(SlotType=?="Partitionable")' \
-format '%s ' Cpus  -format '%s ' State -format '%s\n' Activity | \
awk ' { for (i=$1; i>0; i--) { print $2 " " $3 } }' | sort | uniq -c | \
awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}' 
echo "        [null,null,0]"
echo "      ]"
echo "    },"


echo "    \"Partitionable retiring glideins\": {"
echo "      \"header\": [\"State\",\"Activity\",\"glideins\"],"
echo "      \"data\": ["
condor_status -pool $COLLECTOR        \
-const '(SlotType=?="Partitionable")' \
-const '(GLIDEIN_ToRetire=!=UNDEFINED)&&(CurrentTime>GLIDEIN_ToRetire)' \
-format '%s ' State -format '%s\n' Activity | sort | uniq -c | \
awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}' 
echo "        [null,null,0]"
echo "      ]"
echo "    },"


echo "    \"Partitionable retiring glidein Cpus\": {"
echo "      \"header\": [\"State\",\"Activity\",\"Cpus\"],"
echo "      \"data\": ["
condor_status -pool $COLLECTOR        \
-const '(SlotType=?="Partitionable")' \
-const '(GLIDEIN_ToRetire=!=UNDEFINED)&&(CurrentTime>GLIDEIN_ToRetire)' \
-format '%s ' Cpus  -format '%s ' State -format '%s\n' Activity | \
awk ' { for (i=$1; i>0; i--) { print $2 " " $3 } }' | sort | uniq -c | \
awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}' 
echo "        [null,null,0]"
echo "      ]"
echo "    },"


echo "    \"Dynamic glideins\": {"
echo "      \"header\": [\"State\",\"Activity\",\"glideins\"],"
echo "      \"data\": ["
condor_status -pool $COLLECTOR        \
-const '(SlotType=?="Dynamic")' \
-format '%s ' State -format '%s\n' Activity | sort | uniq -c | \
awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}' 
echo "        [null,null,0]"
echo "      ]"
echo "    },"


echo "    \"Dynamic glidein Cpus\": {"
echo "      \"header\": [\"State\",\"Activity\",\"Cpus\"],"
echo "      \"data\": ["
condor_status -pool $COLLECTOR        \
-const '(SlotType=?="Dynamic")' \
-format '%s ' Cpus  -format '%s ' State -format '%s\n' Activity | \
awk ' { for (i=$1; i>0; i--) { print $2 " " $3 } }' | sort | uniq -c | \
awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}' 
echo "        [null,null,0]"
echo "      ]"
echo "    },"


echo "    \"Dynamic retiring glideins\": {"
echo "      \"header\": [\"State\",\"Activity\",\"glideins\"],"
echo "      \"data\": ["
condor_status -pool $COLLECTOR        \
-const '(SlotType=?="Dynamic")' \
-const '(GLIDEIN_ToRetire=!=UNDEFINED)&&(CurrentTime>GLIDEIN_ToRetire)' \
-format '%s ' State -format '%s\n' Activity | sort | uniq -c | \
awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}' 
echo "        [null,null,0]"
echo "      ]"
echo "    },"


echo "    \"Dynamic retiring glidein Cpus\": {"
echo "      \"header\": [\"State\",\"Activity\",\"Cpus\"],"
echo "      \"data\": ["
condor_status -pool $COLLECTOR        \
-const '(SlotType=?="Dynamic")' \
-const '(GLIDEIN_ToRetire=!=UNDEFINED)&&(CurrentTime>GLIDEIN_ToRetire)' \
-format '%s ' Cpus  -format '%s ' State -format '%s\n' Activity | \
awk ' { for (i=$1; i>0; i--) { print $2 " " $3 } }' | sort | uniq -c | \
awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}' 
echo "        [null,null,0]"
echo "      ]"
echo "    },"


echo "    \"Static glideins\": {"
echo "      \"header\": [\"State\",\"Activity\",\"glideins\"],"
echo "      \"data\": ["
condor_status -pool $COLLECTOR        \
-const '(SlotType=?="Static")' \
-format '%s ' State -format '%s\n' Activity | sort | uniq -c | \
awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}' 
echo "        [null,null,0]"
echo "      ]"
echo "    },"


echo "    \"Static glidein Cpus\": {"
echo "      \"header\": [\"State\",\"Activity\",\"Cpus\"],"
echo "      \"data\": ["
condor_status -pool $COLLECTOR        \
-const '(SlotType=?="Static")' \
-format '%s ' Cpus  -format '%s ' State -format '%s\n' Activity | \
awk ' { for (i=$1; i>0; i--) { print $2 " " $3 } }' | sort | uniq -c | \
awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}' 
echo "        [null,null,0]"
echo "      ]"
echo "    },"


echo "    \"Static retiring glideins\": {"
echo "      \"header\": [\"State\",\"Activity\",\"glideins\"],"
echo "      \"data\": ["
condor_status -pool $COLLECTOR        \
-const '(SlotType=?="Static")' \
-const '(GLIDEIN_ToRetire=!=UNDEFINED)&&(CurrentTime>GLIDEIN_ToRetire)' \
-format '%s ' State -format '%s\n' Activity | sort | uniq -c | \
awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}' 
echo "        [null,null,0]"
echo "      ]"
echo "    },"


echo "    \"Static retiring glidein Cpus\": {"
echo "      \"header\": [\"State\",\"Activity\",\"Cpus\"],"
echo "      \"data\": ["
condor_status -pool $COLLECTOR        \
-const '(SlotType=?="Static")' \
-const '(GLIDEIN_ToRetire=!=UNDEFINED)&&(CurrentTime>GLIDEIN_ToRetire)' \
-format '%s ' Cpus  -format '%s ' State -format '%s\n' Activity | \
awk ' { for (i=$1; i>0; i--) { print $2 " " $3 } }' | sort | uniq -c | \
awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}' 
echo "        [null,null,0]"
echo "      ]"
echo "    },"


echo "    \"Static multi-core glideins\": {"
echo "      \"header\": [\"State\",\"Activity\",\"glideins\"],"
echo "      \"data\": ["
condor_status -pool $COLLECTOR        \
-const '(SlotType=?="Static")' \
-format '%s ' Name  -format '%s ' State -format '%s\n' Activity | \
grep ^slot[0-9]*\@ | awk '{print $2 " " $3 }' | sort | uniq -c | \
awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}' 
echo "        [null,null,0]"
echo "      ]"
echo "    },"


echo "    \"Static multi-core glidein Cpus\": {"
echo "      \"header\": [\"State\",\"Activity\",\"Cpus\"],"
echo "      \"data\": ["
condor_status -pool $COLLECTOR        \
-const '(SlotType=?="Static")' \
-format '%s ' Name  -format '%s ' Cpus -format '%s ' State -format '%s\n' Activity | \
grep ^slot[0-9]*\@ | awk '{print $2 " " $3 " " $4 }' | \
awk ' { for (i=$1; i>0; i--) { print $2 " " $3 } }' | sort | uniq -c | \
awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}' 
echo "        [null,null,0]"
echo "      ]"
echo "    },"


echo "    \"Static multi-core retiring glideins\": {"
echo "      \"header\": [\"State\",\"Activity\",\"glideins\"],"
echo "      \"data\": ["
condor_status -pool $COLLECTOR        \
-const '(SlotType=?="Static")' \
-const '(GLIDEIN_ToRetire=!=UNDEFINED)&&(CurrentTime>GLIDEIN_ToRetire)' \
-format '%s ' Name  -format '%s ' State -format '%s\n' Activity | \
grep ^slot[0-9]*\@ | awk '{print $2 " " $3 }' | sort | uniq -c | \
awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}' 
echo "        [null,null,0]"
echo "      ]"
echo "    },"


echo "    \"Static multi-core retiring glidein Cpus\": {"
echo "      \"header\": [\"State\",\"Activity\",\"Cpus\"],"
echo "      \"data\": ["
condor_status -pool $COLLECTOR        \
-const '(SlotType=?="Static")' \
-const '(GLIDEIN_ToRetire=!=UNDEFINED)&&(CurrentTime>GLIDEIN_ToRetire)' \
-format '%s ' Name  -format '%s ' Cpus -format '%s ' State -format '%s\n' Activity | \
grep ^slot[0-9]*\@ | awk '{print $2 " " $3 " " $4 }' | \
awk ' { for (i=$1; i>0; i--) { print $2 " " $3 } }' | sort | uniq -c | \
awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}' 
echo "        [null,null,0]"
echo "      ]"
echo "    },"


echo "    \"Total glideins\": {"
echo "      \"header\": [\"State\",\"Activity\",\"glideins\"],"
echo "      \"data\": ["
condor_status -pool $COLLECTOR \
-format '%s ' State -format '%s\n' Activity \
| sort |uniq -c \
| awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}'
echo "        [null,null,0]"
echo "      ]"
echo "    },"


echo "    \"Total Cpus\": {"
echo "      \"header\": [\"State\",\"Activity\",\"Cpus\"],"
echo "      \"data\": ["
condor_status -pool $COLLECTOR \
-format '%s ' Cpus  -format '%s ' State -format '%s\n' Activity \
| awk ' { for (i=$1; i>0; i--) { print $2 " " $3 } }' | sort |uniq -c \
| awk '{printf("        [\"%s\",\"%s\",%i],\n",$2,$3,$1)}'
echo "        [null,null,0]"
echo "      ]"
echo "    }"


echo "  }"
echo "}"


return
}

JSONFILE=${glideinWMSMonitor_OUTPUT_DIR}-json/monitor-multicore-global-`/bin/date +%F-Z%R -u`.json
writeoutjsonfile vocms097.cern.ch > $JSONFILE

exit
