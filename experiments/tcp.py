#!/usr/bin/env python2

import SocketServer

addr = ('0.0.0.0', 12366)

class service(SocketServer.BaseRequestHandler):

    def handle(self):
        print "Connected: ", self.client_address

        # Receive header
        hdata = self.request.recv(256)
        print hdata

        # Get content length from header
        length = int(hdata.split(': ')[1])
        data = self.request.recv(length)
        print data

        self.request.close()

class ThreadedTCPServer(SocketServer.ThreadingMixIn, SocketServer.TCPServer):
    pass

if __name__ == "__main__":
    t = ThreadedTCPServer(addr, service)
    print "Listening on", addr
    t.serve_forever()
