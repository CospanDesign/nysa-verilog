import os
import sys
import cocotb
import logging
from cocotb.result import TestFailure
from cocotb.clock import Clock
import time
from array import array as Array
from cocotb.triggers import Timer, FallingEdge

from cocotb.drivers.amba import AXI4LiteMaster
from cocotb.drivers.amba import AXI4StreamMaster
from cocotb.drivers.amba import AXI4StreamSlave

CLK_PERIOD = 10

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "rtl")
MODULE_PATH = os.path.abspath(MODULE_PATH)


BIT_CONTROL_ENABLE    = 0
BIT_CONTROL_RESET     = 1

BIT_STATUS_ACTIVE     = 0



REG_CONTROL           = 0
REG_STATUS            = 1
REG_VERSION           = 2

REG_VIDEO_IN_SIZE     = 4
REG_VIDEO_IN_WIDTH    = 5
REG_VIDEO_IN_HEIGHT   = 6

REG_VIDEO_OUT_SIZE    = 8
REG_VIDEO_OUT_WIDTH   = 9
REG_VIDEO_OUT_HEIGHT  = 10

REG_VIDEO_IN_START_X  = 12
REG_VIDEO_IN_START_Y  = 13
REG_IN_FILL_PIXEL     = 14



MEM_ADR_RESET               = 0x01

"""
Functions Required for checking out PMOD TFT

1. Write to the controller chip internal register
2. Read from the controller chip internall register
3. Video Frame Successfully is sent from the memory
    to the controller chip
4. Video Frames are continually sent out
"""


WIDTH                = 8
HEIGHT               = 4
H_BLANK              = 40
V_BLANK              = 200
PIXEL_COUNT          = WIDTH * HEIGHT


@cocotb.coroutine
def axis_slave_listener(axis_slave):
    data = yield axis_slave.read()
    print ("read data: %s" % str(data))


def setup_dut(dut):
    cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())

@cocotb.test(skip = False)
def read_all_registers(dut):
    """
    Description:
        Read all registers from the core

    Test ID: 0

    Expected Results:
        A value is successfully written to the
        the register of the controller.

        This value should be readable from the test bench
    """
    dut.rst <= 1
    dut.test_id <= 0
    axim = AXI4LiteMaster(dut, "AXIML", dut.clk)
    video_out = AXI4StreamMaster(dut, "AXIMS", dut.clk, width=24)
    video_in = AXI4StreamSlave(dut, "AXISS", dut.clk, width=24)

    setup_dut(dut)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 1
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)

    dut.log.info("Ready")



    control = 0x02

    #Reset the LCD
    yield axim.write(REG_CONTROL, control)
    yield Timer(CLK_PERIOD * 10)

    control = 0x01

    #Reset the LCD
    yield axim.write(REG_CONTROL, control)
    yield Timer(CLK_PERIOD * 10)

    yield Timer(CLK_PERIOD * 100)

    #Read Back All the registers, make sure they make sense
    data = yield axim.read(REG_STATUS)
    yield Timer(CLK_PERIOD * 10)
    if data != control:
        raise TestFailure("REG_STATUS Register was not correct, should be: 0x%08 but read: 0x%08X" % control, data)

    data = yield axim.read(REG_VIDEO_IN_SIZE)
    yield Timer(CLK_PERIOD * 10)
    if data != (1280 * 720):
        raise TestFailure("REG_VIDEO_IN_SIZE Register was not correct, should be: 0x%08 but read: 0x%08X" % ((1280 * 720), data))

    data = yield axim.read(REG_VIDEO_IN_WIDTH)
    yield Timer(CLK_PERIOD * 10)
    if data != 1280:
        raise TestFailure("REG_VIDEO_IN_WIDTH Register was not correct, should be: 0x%08 but read: 0x%08X" % (1280, data))

    data = yield axim.read(REG_VIDEO_IN_HEIGHT)
    yield Timer(CLK_PERIOD * 10)
    if data != 720:
        raise TestFailure("REG_VIDEO_IN_HEIGHT Register was not correct, should be: 0x%08 but read: 0x%08X" % (720, data))


    data = yield axim.read(REG_VIDEO_OUT_SIZE)
    yield Timer(CLK_PERIOD * 10)
    if data != (1280 * 720):
        raise TestFailure("REG_VIDEO_OUT_SIZE Register was not correct, should be: 0x%08 but read: 0x%08X" % ((1280 * 720), data))

    data = yield axim.read(REG_VIDEO_OUT_WIDTH)
    yield Timer(CLK_PERIOD * 10)
    if data != 1280:
        raise TestFailure("REG_VIDEO_OUT_WIDTH Register was not correct, should be: 0x%08 but read: 0x%08X" % (1280, data))

    data = yield axim.read(REG_VIDEO_OUT_HEIGHT)
    yield Timer(CLK_PERIOD * 10)
    if data != 720:
        raise TestFailure("REG_VIDEO_OUT_HEIGHT Register was not correct, should be: 0x%08 but read: 0x%08X" % (720, data))

    data = yield axim.read(REG_VIDEO_IN_START_X)
    yield Timer(CLK_PERIOD * 10)
    if data != 0:
        raise TestFailure("REG_VIDEO_IN_START_X Register was not correct, should be: 0x%08 but read: 0x%08X" % (0, data))

    data = yield axim.read(REG_VIDEO_IN_START_Y)
    yield Timer(CLK_PERIOD * 10)
    if data != 0:
        raise TestFailure("REG_VIDEO_IN_START_Y Register was not correct, should be: 0x%08 but read: 0x%08X" % (0, data))

    data = yield axim.read(REG_IN_FILL_PIXEL)
    yield Timer(CLK_PERIOD * 10)
    if data != 0:
        raise TestFailure("REG_IN_FILL_PIXEL Register was not correct, should be: 0x%08 but read: 0x%08X" % (0, data))


@cocotb.test(skip = False)
def write_downsamled_top_left_frame(dut):
    """
    Description:
        Write a single frame

    Test ID: 1

    Expected Results:
        A value is successfully written to the
        the register of the controller.

        This value should be readable from the test bench
    """

    IMAGE_IN_WIDTH = 3
    IMAGE_IN_HEIGHT = 3
    IMAGE_IN_SIZE = IMAGE_IN_WIDTH * IMAGE_IN_HEIGHT

    IMAGE_OUT_WIDTH = 2
    IMAGE_OUT_HEIGHT = 2
    IMAGE_OUT_SIZE = IMAGE_OUT_WIDTH * IMAGE_OUT_HEIGHT

    IMAGE_IN_START_X = 0
    IMAGE_IN_START_Y = 0


    video = []
    for y in range(IMAGE_IN_HEIGHT):
        for x in range(IMAGE_IN_WIDTH):
            video.append((IMAGE_IN_WIDTH * y) + x)


    dut.rst <= 1
    dut.test_id <= 1
    axim = AXI4LiteMaster(dut, "AXIML", dut.clk)
    video_out = AXI4StreamMaster(dut, "AXIMS", dut.clk, width=24)
    video_in = AXI4StreamSlave(dut, "AXISS", dut.clk, width=24)

    setup_dut(dut)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 1
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)

    dut.log.info("Ready")


    cocotb.fork(axis_slave_listener(video_in))

    control = 0x02

    #Reset the LCD
    yield axim.write(REG_CONTROL, control)
    yield Timer(CLK_PERIOD * 10)



    yield axim.write(REG_VIDEO_IN_WIDTH, IMAGE_IN_WIDTH)
    yield Timer(CLK_PERIOD * 10)

    yield axim.write(REG_VIDEO_IN_HEIGHT, IMAGE_IN_HEIGHT)
    yield Timer(CLK_PERIOD * 10)

    yield axim.write(REG_VIDEO_IN_SIZE,  IMAGE_IN_SIZE)
    yield Timer(CLK_PERIOD * 10)



    yield axim.write(REG_VIDEO_OUT_WIDTH, IMAGE_OUT_WIDTH)
    yield Timer(CLK_PERIOD * 10)

    yield axim.write(REG_VIDEO_OUT_HEIGHT, IMAGE_OUT_HEIGHT)
    yield Timer(CLK_PERIOD * 10)

    yield axim.write(REG_VIDEO_OUT_SIZE, IMAGE_OUT_SIZE)
    yield Timer(CLK_PERIOD * 10)


    yield axim.write(REG_VIDEO_IN_START_X, IMAGE_IN_START_X)
    yield Timer(CLK_PERIOD * 10)

    yield axim.write(REG_VIDEO_IN_START_Y, IMAGE_IN_START_Y)
    yield Timer(CLK_PERIOD * 10)


    control = 0x01

    #Reset the LCD
    yield axim.write(REG_CONTROL, control)
    yield Timer(CLK_PERIOD * 10)

    yield video_out.write(video)
    yield Timer(CLK_PERIOD * 500)

@cocotb.test(skip = False)
def write_one_to_one_frame(dut):
    """
    Description:
        Write a single frame

    Test ID: 1

    Expected Results:
        A value is successfully written to the
        the register of the controller.

        This value should be readable from the test bench
    """

    IMAGE_IN_WIDTH = 3
    IMAGE_IN_HEIGHT = 3
    IMAGE_IN_SIZE = IMAGE_IN_WIDTH * IMAGE_IN_HEIGHT

    IMAGE_OUT_WIDTH = 3
    IMAGE_OUT_HEIGHT = 3
    IMAGE_OUT_SIZE = IMAGE_OUT_WIDTH * IMAGE_OUT_HEIGHT

    IMAGE_IN_START_X = 0
    IMAGE_IN_START_Y = 0


    video = []
    for y in range(IMAGE_IN_HEIGHT):
        for x in range(IMAGE_IN_WIDTH):
            video.append((IMAGE_IN_WIDTH * y) + x)


    dut.rst <= 1
    dut.test_id <= 2
    axim = AXI4LiteMaster(dut, "AXIML", dut.clk)
    video_out = AXI4StreamMaster(dut, "AXIMS", dut.clk, width=24)
    video_in = AXI4StreamSlave(dut, "AXISS", dut.clk, width=24)

    setup_dut(dut)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 1
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)

    dut.log.info("Ready")


    cocotb.fork(axis_slave_listener(video_in))

    control = 0x02

    #Reset the LCD
    yield axim.write(REG_CONTROL, control)
    yield Timer(CLK_PERIOD * 10)



    yield axim.write(REG_VIDEO_IN_WIDTH, IMAGE_IN_WIDTH)
    yield Timer(CLK_PERIOD * 10)

    yield axim.write(REG_VIDEO_IN_HEIGHT, IMAGE_IN_HEIGHT)
    yield Timer(CLK_PERIOD * 10)

    yield axim.write(REG_VIDEO_IN_SIZE,  IMAGE_IN_SIZE)
    yield Timer(CLK_PERIOD * 10)



    yield axim.write(REG_VIDEO_OUT_WIDTH, IMAGE_OUT_WIDTH)
    yield Timer(CLK_PERIOD * 10)

    yield axim.write(REG_VIDEO_OUT_HEIGHT, IMAGE_OUT_HEIGHT)
    yield Timer(CLK_PERIOD * 10)

    yield axim.write(REG_VIDEO_OUT_SIZE, IMAGE_OUT_SIZE)
    yield Timer(CLK_PERIOD * 10)


    yield axim.write(REG_VIDEO_IN_START_X, IMAGE_IN_START_X)
    yield Timer(CLK_PERIOD * 10)

    yield axim.write(REG_VIDEO_IN_START_Y, IMAGE_IN_START_Y)
    yield Timer(CLK_PERIOD * 10)


    control = 0x01

    #Reset the LCD
    yield axim.write(REG_CONTROL, control)
    yield Timer(CLK_PERIOD * 10)

    yield video_out.write(video)
    yield Timer(CLK_PERIOD * 500)


@cocotb.test(skip = False)
def write_bottom_right_frame(dut):
    """
    Description:
        Write a single frame

    Test ID: 1

    Expected Results:
        A value is successfully written to the
        the register of the controller.

        This value should be readable from the test bench
    """

    IMAGE_IN_WIDTH = 3
    IMAGE_IN_HEIGHT = 3
    IMAGE_IN_SIZE = IMAGE_IN_WIDTH * IMAGE_IN_HEIGHT

    IMAGE_OUT_WIDTH = 2
    IMAGE_OUT_HEIGHT = 2
    IMAGE_OUT_SIZE = IMAGE_OUT_WIDTH * IMAGE_OUT_HEIGHT

    IMAGE_IN_START_X = 1
    IMAGE_IN_START_Y = 1


    video = []
    for y in range(IMAGE_IN_HEIGHT):
        for x in range(IMAGE_IN_WIDTH):
            video.append((IMAGE_IN_WIDTH * y) + x)


    dut.rst <= 1
    dut.test_id <= 3
    axim = AXI4LiteMaster(dut, "AXIML", dut.clk)
    video_out = AXI4StreamMaster(dut, "AXIMS", dut.clk, width=24)
    video_in = AXI4StreamSlave(dut, "AXISS", dut.clk, width=24)

    setup_dut(dut)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 1
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)

    dut.log.info("Ready")


    cocotb.fork(axis_slave_listener(video_in))

    control = 0x02

    #Reset the LCD
    yield axim.write(REG_CONTROL, control)
    yield Timer(CLK_PERIOD * 10)



    yield axim.write(REG_VIDEO_IN_WIDTH, IMAGE_IN_WIDTH)
    yield Timer(CLK_PERIOD * 10)

    yield axim.write(REG_VIDEO_IN_HEIGHT, IMAGE_IN_HEIGHT)
    yield Timer(CLK_PERIOD * 10)

    yield axim.write(REG_VIDEO_IN_SIZE,  IMAGE_IN_SIZE)
    yield Timer(CLK_PERIOD * 10)



    yield axim.write(REG_VIDEO_OUT_WIDTH, IMAGE_OUT_WIDTH)
    yield Timer(CLK_PERIOD * 10)

    yield axim.write(REG_VIDEO_OUT_HEIGHT, IMAGE_OUT_HEIGHT)
    yield Timer(CLK_PERIOD * 10)

    yield axim.write(REG_VIDEO_OUT_SIZE, IMAGE_OUT_SIZE)
    yield Timer(CLK_PERIOD * 10)


    yield axim.write(REG_VIDEO_IN_START_X, IMAGE_IN_START_X)
    yield Timer(CLK_PERIOD * 10)

    yield axim.write(REG_VIDEO_IN_START_Y, IMAGE_IN_START_Y)
    yield Timer(CLK_PERIOD * 10)


    control = 0x01

    #Reset the LCD
    yield axim.write(REG_CONTROL, control)
    yield Timer(CLK_PERIOD * 10)

    yield video_out.write(video)
    yield Timer(CLK_PERIOD * 500)


@cocotb.test(skip = False)
def write_center_frame(dut):
    """
    Description:
        Write a single frame

    Test ID: 4

    Expected Results:
        A value is successfully written to the
        the register of the controller.

        This value should be readable from the test bench
    """
    dut.test_id <= 4

    IMAGE_IN_WIDTH = 4
    IMAGE_IN_HEIGHT = 4
    IMAGE_IN_SIZE = IMAGE_IN_WIDTH * IMAGE_IN_HEIGHT

    IMAGE_OUT_WIDTH = 2
    IMAGE_OUT_HEIGHT = 2
    IMAGE_OUT_SIZE = IMAGE_OUT_WIDTH * IMAGE_OUT_HEIGHT

    IMAGE_IN_START_X = 1
    IMAGE_IN_START_Y = 1


    video = []
    for y in range(IMAGE_IN_HEIGHT):
        for x in range(IMAGE_IN_WIDTH):
            video.append((IMAGE_IN_WIDTH * y) + x)


    dut.rst <= 1
    axim = AXI4LiteMaster(dut, "AXIML", dut.clk)
    video_out = AXI4StreamMaster(dut, "AXIMS", dut.clk, width=24)
    video_in = AXI4StreamSlave(dut, "AXISS", dut.clk, width=24)

    setup_dut(dut)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 1
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)

    dut.log.info("Ready")


    cocotb.fork(axis_slave_listener(video_in))

    control = 0x02

    #Reset the LCD
    yield axim.write(REG_CONTROL, control)
    yield Timer(CLK_PERIOD * 10)



    yield axim.write(REG_VIDEO_IN_WIDTH, IMAGE_IN_WIDTH)
    yield Timer(CLK_PERIOD * 10)

    yield axim.write(REG_VIDEO_IN_HEIGHT, IMAGE_IN_HEIGHT)
    yield Timer(CLK_PERIOD * 10)

    yield axim.write(REG_VIDEO_IN_SIZE,  IMAGE_IN_SIZE)
    yield Timer(CLK_PERIOD * 10)



    yield axim.write(REG_VIDEO_OUT_WIDTH, IMAGE_OUT_WIDTH)
    yield Timer(CLK_PERIOD * 10)

    yield axim.write(REG_VIDEO_OUT_HEIGHT, IMAGE_OUT_HEIGHT)
    yield Timer(CLK_PERIOD * 10)

    yield axim.write(REG_VIDEO_OUT_SIZE, IMAGE_OUT_SIZE)
    yield Timer(CLK_PERIOD * 10)


    yield axim.write(REG_VIDEO_IN_START_X, IMAGE_IN_START_X)
    yield Timer(CLK_PERIOD * 10)

    yield axim.write(REG_VIDEO_IN_START_Y, IMAGE_IN_START_Y)
    yield Timer(CLK_PERIOD * 10)


    control = 0x01

    #Reset the LCD
    yield axim.write(REG_CONTROL, control)
    yield Timer(CLK_PERIOD * 10)

    yield video_out.write(video)
    yield Timer(CLK_PERIOD * 500)

