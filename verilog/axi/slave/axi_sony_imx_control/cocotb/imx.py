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

MAX_CAMERA_COUNT        = 3
MAX_LANE_WIDTH          = 16

CAMERA_COUNT            = 1
LANE_WIDTH              = 8

REG_CONTROL               = 0  << 2
REG_STATUS                = 1  << 2
REG_TRIGGER_PULSE_WIDTH   = 2  << 2
REG_TRIGGER_PERIOD        = 3  << 2
REG_CAMERA_COUNT          = 4  << 2
REG_LANE_WIDTH            = 5  << 2
REG_ALIGNED_FLAG_LOW      = 6  << 2
REG_ALIGNED_FLAG_HIGH     = 7  << 2
REG_FRAME_WIDTH           = 8  << 2
REG_FRAME_HEIGHT          = 9  << 2
REG_PRE_VERTICAL_BLANK    = 10 << 2
REG_PRE_HORIZONTAL_BLANK  = 11 << 2
REG_POST_VERTICAL_BLANK   = 12 << 2
REG_POST_HORIZONTAL_BLANK = 13 << 2

REG_TAP_DELAY_START       = 16 << 2
SIZE_TAP_DELAY            = MAX_CAMERA_COUNT * MAX_LANE_WIDTH

REG_TAP_ERROR_START       = REG_TAP_DELAY_START + SIZE_TAP_DELAY
REG_VERSION               = REG_TAP_ERROR_START + (SIZE_TAP_DELAY << 2)




CTRL_BIT_CLEAR_EN           = 0;
CTRL_BIT_TRIGGER_EN         = 1;
CTRL_BIT_CAM_ASYNC_RST_EN   = 2;
CTRL_BIT_CAM_SYNC_RST_EN    = 3;
CTRL_BIT_DETECT_ERROR_EN    = 4;

CTRL_BIT_POWER_EN0          = 12
CTRL_BIT_POWER_EN1          = 13
CTRL_BIT_POWER_EN2          = 14






class IMX (Driver):
    def __init__(self, dut, debug = False):
        super(IMX, self).__init__(dut, dut.clk, debug=debug)

    def __del__(self):
        pass

    @cocotb.coroutine
    def get_version(self):
        data = yield self.read_register(REG_VERSION)
        raise ReturnValue(data)

    @cocotb.coroutine
    def get_status(self):
        status = yield self.read_register(REG_STATUS)
        raise ReturnValue(status)

    @cocotb.coroutine
    def set_image_width(self, width):
        yield self.write_register(REG_FRAME_WIDTH, width)

    @cocotb.coroutine
    def get_image_width(self):
        data = yield self.read_register(REG_FRAME_WIDTH)
        raise ReturnValue(data)

    @cocotb.coroutine
    def set_image_height(self, height):
        yield self.write_register(REG_FRAME_HEIGHT, height)

    @cocotb.coroutine
    def get_image_height(self):
        data = yield self.read_register(REG_FRAME_HEIGHT)
        raise ReturnValue(data)

    @cocotb.coroutine
    def set_pre_vblank(self, pre_vblank):
        yield self.write_register(REG_PRE_VERTICAL_BLANK, pre_vblank) 

    @cocotb.coroutine
    def set_pre_hblank(self, pre_hblank):
        yield self.write_register(REG_PRE_HORIZONTAL_BLANK, pre_hblank) 

    @cocotb.coroutine
    def set_post_vblank(self, post_vblank):
        yield self.write_register(REG_POST_VERTICAL_BLANK, post_vblank) 

    @cocotb.coroutine
    def set_post_hblank(self, post_hblank):
        yield self.write_register(REG_POST_HORIZONTAL_BLANK, post_hblank) 

    @cocotb.coroutine
    def setup_trigger(self, period, pulse_width):
        yield self.write_register(REG_TRIGGER_PERIOD, period)
        yield self.sleep(10)
        yield self.write_register(REG_TRIGGER_PULSE_WIDTH, pulse_width)

    @cocotb.coroutine
    def get_camera_count(self):
        count = yield self.read_register(REG_CAMERA_COUNT)
        raise ReturnValue(count)

    @cocotb.coroutine
    def get_lane_width(self):
        count = yield self.read_register(REG_LANE_WIDTH)
        raise ReturnValue(count)

    @cocotb.coroutine
    def get_aligned_flags(self):
        flags = 0
        data_low = yield self.read_register(REG_ALIGNED_FLAG_LOW)
        yield self.sleep(10)
        data_high = yield self.read_register(REG_ALIGNED_FLAG_HIGH)
        flags = (data_high << 32) | data_low
        raise ReturnValue(flags)

    @cocotb.coroutine
    def async_reset_enable(self, enable):
        yield self.enable_register_bit(REG_CONTROL, CTRL_BIT_CAM_ASYNC_RST_EN, enable)

    @cocotb.coroutine
    def enable_detect_errors(self, enable):
        yield self.enable_register_bit(REG_CONTROL, CTRL_BIT_DETECT_ERROR_EN, enable)

    @cocotb.coroutine
    def sync_reset_enable(self, enable):
        #Self Clearing
        yield self.enable_register_bit(REG_CONTROL, CTRL_BIT_CAM_SYNC_RST_EN, enable);

    @cocotb.coroutine
    def reset_camera_enable(self, enable):
        #Self Clearing
        yield self.enable_register_bit(REG_CONTROL, CTRL_BIT_CLEAR_EN, enable);

    @cocotb.coroutine
    def enable_camera_power(self, cam_index, enable):
        yield self.enable_register_bit(REG_CONTROL, CTRL_BIT_POWER_EN0 + cam_index, enable)

    @cocotb.coroutine
    def enable_cam_trigger(self, enable):
        yield self.enable_register_bit(REG_CONTROL, CTRL_BIT_TRIGGER_EN, enable)

    @cocotb.coroutine
    def set_tap_delay(self, index, delay):
        addr = REG_TAP_DELAY_START + (index << 2)
        print ("Address: %d, 0x%02X" % (addr, addr))
        yield self.write_register(addr, delay)

    @cocotb.coroutine
    def get_tap_delay(self, index):
        addr = REG_TAP_DELAY_START + (index << 2)
        print ("Address: %d, 0x%02X" % (addr, addr))
        data = yield self.read_register(addr)
        raise ReturnValue(data)

    @cocotb.coroutine
    def get_tap_error(self, index):
        addr = REG_TAP_ERROR_START + (index << 2)
        print ("Address: %d, 0x%02X" % (addr, addr))
        data = yield self.read_register(addr)
        raise ReturnValue(data)

