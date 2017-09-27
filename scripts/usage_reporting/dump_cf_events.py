#!/usr/bin/env python

import subprocess
import json

def dump_events(kind, per_page):
    events = []

    url = "/v2/%s_usage_events?results-per-page=%s&page=1" % (kind, per_page)
    while url:
        print("Fetching %s" % url)
        response = subprocess.check_output(['cf', 'curl', url])
        data = json.loads(response)
        url = data['next_url']
        events.extend(data['resources'])
        print(len(events))

    with open("cf_%s_events.json" % kind, 'w') as f:
        f.write(json.dumps(events, sort_keys=True, indent=4, separators=(',', ': ')))

dump_events('app', 10000)
dump_events('service', 100)
