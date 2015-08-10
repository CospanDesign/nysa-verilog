#! /usr/bin/python


import sys
import os
import argparse
import math
from array import array as Array

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir)))

DESCRIPTION = "\n" \
              "\n" \
              "usage: crc [number]\n"

EPILOG = "\n" \
         "\n" \
         "Examples:\n" \
         "\tSomething\n" \
         "\n"

"""
This one is slightly different from the CRC 7 because the bit shifting of the
value needs to happen before the comparaison because the 16th bit is compared
not the 7th bit... this also means that within the verilog implementation the
output will happen once clock cycle earlier... it may not but just be aware
of this
"""
def crc16_gen(data_array):
    regval = 0
    index = 0
    bitcount = 0
    for short_index in range ((len(data_array) - 1), -1, -1):
        value = data_array[short_index]
        v = value
        print "%d:\t\t" % (index),
        index += 1
        for bit_index in range (16):
            bitcount += 1
            value = value << 1
            regval = regval << 1
            if ((value ^ regval) & 0x10000) > 0:
                regval = regval ^ 0x1021
                print "+",
            else:
                print "-",

        #regval = regval & 0xFFFF
        #print " Value: 0x%04X CRC Value: 0x%04X" % (v, regval)
        print " Value: 0x%04X CRC Value: 0x%04X" % (v, (regval & 0xFFFF))

        #regval = regval & 0x7FFF

       
    regval = regval & 0xFFFF
    print "Total bitcount: %d" % bitcount
    print "value: 0x%04X" % regval
    return regval
    

def main(argv):
    #Parse out command line options
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=DESCRIPTION,
        epilog=EPILOG
    )
    parser.add_argument("-d", "--debug",
                        action="store_true",
                        help="Enable Debug Messages")

    args = parser.parse_args()
    data = Array('H')
    for i in range (256):
        data.append(0xFFFF)

    value = crc16_gen(data) 

if __name__ == "__main__":
    main(sys.argv)

