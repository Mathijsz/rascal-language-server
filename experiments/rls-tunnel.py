#!/usr/bin/env python

'''
    This script is a stop-gap solution that hands incoming LSP messages to the
    (HTTP) web server. Communication with the LSP client goes via stdin/stdout.

    Usage: ./rls-tunnel.py <language name>

    Note: this script should be started by the LSP client.
'''

from sys import stdin, stdout, stderr, argv, exit
import requests

rascal_web_addr = "http://127.0.0.1:12366/"

# Use this as header towards the web server for now
header = {"Content-Type": "application/json"}

def get_length(line):
    try:
        return int(line.split(': ')[1])
    except ValueError:
        print "Content-Length not a number"
    except IndexError:
        print "No length given"


def read_msg():
    length = 0
    line = stdin.readline()

    if not line:
        return

    if "Content-Length: " in line:
        length = get_length(line)

    # Read remaining lines until separator of header lines and content
    while line.strip() != "":
        line = stdin.readline()

    return stdin.read(length)


if __name__ == "__main__":

    rascal_web_addr += argv[1] if len(argv) == 2 else "rascal"

    while True:
        msg = read_msg()

        if not msg:
            continue

        resp = requests.post(rascal_web_addr, headers=header, data=msg)

        if resp.status_code != requests.codes.ok:
            stderr.write("Could not deliver response to", rascal_web_addr)
            break

        # Might need a manual Content-Length prefix in the body
        stdout.write(resp.text)

        # Hack: shut down tunnel after the shutdown message has been delivered
        # to the Rascal web server.
        if "\"method\":\"shutdown\"" in msg:
            exit(0)
