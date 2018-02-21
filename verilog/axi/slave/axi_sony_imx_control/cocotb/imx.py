#Distributed under the MIT licesnse.
#Copyright (c) 2011 Dave McCoy (dave.mccoy@cospandesign.com)

#Permission is hereby granted, free of charge, to any person obtaining a copy of
#this software and associated documentation files (the "Software"), to deal in
#the Software without restriction, including without limitation the rights to
#use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
#of the Software, and to permit persons to whom the Software is furnished to do
#so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.


__author__ = 'dave.mccoy@cospandesign.com (Dave McCoy)'

import sys
import os
import time
from driver import Driver

from array import array as Array

import cocotb
from cocotb.result import ReturnValue
from cocotb.drivers.amba import AXI4LiteMaster
from cocotb.triggers import Timer

CAMERA_COUNT            = 1
LANE_WIDTH              = 8

REG_CONTROL             = 0 << 2
REG_STATUS              = 1 << 2
REG_CLEAR_PULSE_WIDTH   = 2 << 2
REG_TRIGGER_PULSE_WIDTH = 3 << 2
REG_TRIGGER_PERIOD      = 4 << 2
REG_CAMERA_COUNT        = 5 << 2
REG_LANE_WIDTH          = 6 << 2

REG_TAP_DELAY_START     = 16 << 2
SIZE_TAP_DELAY          = LANE_WIDTH * CAMERA_COUNT
REG_VERSION             = REG_TAP_DELAY_START + (SIZE_TAP_DELAY << 2)



class IMX (Driver):
    def __init__(self, dut, debug = False):
        super(IMX, self).__init__(dut, dut.clk, debug=debug)

    def __del__(self):
        pass

    @cocotb.coroutine
    def get_version(self):
        data = yield self.read_register(REG_VERSION)
        raise ReturnValue(data)




