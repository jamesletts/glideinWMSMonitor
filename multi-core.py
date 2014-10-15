#!/usr/bin/python26
import json
from pprint import pprint
FILE="data/monitor-multicore-production-2014-10-15-Z15:25.json"
with open(FILE) as json_data:
    d = json.load(json_data)
    json_data.close()
    pprint(d)
