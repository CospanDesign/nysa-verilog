#! /usr/bin/python


import sys
import os
import argparse
import math

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir)))

DESCRIPTION = "\n" \
              "\n" \
              "usage: crc [number]\n"

EPILOG = "\n" \
         "\n" \
         "Examples:\n" \
         "\tSomething\n" \
         "\n"

def crc7_gen(number, bit_count):
    byte_index = 0
    crc = 0
    regval = 0
    byte_val = 0
    byte_index = 0
    for i in range (bit_count, 0, -8):
        shift_val = i - 8
        byte_val = (number >> shift_val) & 0xFF
        for bit_index in range (8):
            regval = regval << 1
            if ((byte_val ^ regval) & 0x80) > 0:
                regval = regval ^ 9
            byte_val = (byte_val << 1) & 0xFF
            
        regval = (regval & 0x7F)

    value = regval
       
    final_val = (regval << 1) + 1
    print "value: 0x%02X" % value
    print "final: 0x%02X" % final_val
    return (regval & 0x7F)
    

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
    #value = crc_generator(0x4000000000, 40) 
    value = crc7_gen(0x4000000000, 40) 
    value = crc7_gen(0x5100000000, 40)
    value = crc7_gen(0x1100000900, 40)



if __name__ == "__main__":
    main(sys.argv)

