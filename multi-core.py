#!/usr/bin/python26
import json
from pprint import pprint
FILE="/crabprod/CSstoragePath/Monitor-json/monitor-multicore-production-2014-10-15-Z19:28.json"
with open(FILE) as json_data:
    d = json.load(json_data)
    json_data.close()
    pprint(d)
