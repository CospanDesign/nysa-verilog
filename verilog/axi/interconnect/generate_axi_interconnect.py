#! /usr/bin/env python

# Copyright (c) 2016 Dave McCoy (dave.mccoy@cospandesign.com)
#
# NAME is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# any later version.
#
# NAME is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with NAME; If not, see <http://www.gnu.org/licenses/>.


import sys
import os
import argparse
import json

#sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir)))

NAME = os.path.basename(os.path.realpath(__file__))

AXI_INTERCONNECT_TEMPLATE = os.path.abspath(os.path.join(os.path.dirname(__file__), "axi_interconnect.v"))

DESCRIPTION = "\n" \
              "\n" \
              "Generate an AXI interconnect\n" \
              "\n" \
              "usage: %s [options]\n" % NAME

EPILOG = "\n" \
         "\n" \
         "Examples:\n" \
         "\tSomething\n" \
         "\n"


def parse_json(filepath):
    f = open(filepath, 'r')
    d = json.loads(f.read())
    f.close()
    return d

def generate_interconnect(d, debug):
    print ("Json: %s" % str(d))
    print ("Address Width: %d" % d["address_width"])
    print ("Data Width: %d" % d["data_width"])
    for s in d["slaves"]:
        start = int(s["start"], 0)
        end = int(s["end"], 0)
        print ("Slave: %d" % d["slaves"].index(s))
        print ("\tSlave Start Address: 0x%08X" % start)
        print ("\tSlave End   Address: 0x%08X" % end)
        print ("")

    #Generate the ports
    #Generate the addresses
        

def main(argv):
    #Parse out the commandline arguments
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=DESCRIPTION,
        epilog=EPILOG
    )

    parser.add_argument("-t", "--test",
                        nargs=1,
                        default=["something"])

    parser.add_argument("-j", "--json",
                        nargs=1)

    parser.add_argument("-d", "--debug",
                        action="store_true",
                        help="Enable Debug Messages")

    args = parser.parse_args()
    print "Running Script: %s" % NAME

    d = {}
    if args.json is not None:
        filepath = args.json[0]
        d = parse_json(filepath)


    if args.debug:
        print "test: %s" % str(args.test[0])

    generate_interconnect(d, args.debug)


if __name__ == "__main__":
    main(sys.argv)


