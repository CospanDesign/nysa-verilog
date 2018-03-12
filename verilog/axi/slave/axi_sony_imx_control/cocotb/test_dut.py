import os
import sys
import cocotb
import logging
from cocotb.result import TestFailure
from cocotb.clock import Clock
import time
from array import array as Array
from cocotb.triggers import Timer

from cocotb.drivers.amba import AXI4LiteMaster
from cocotb.drivers.amba import AXI4StreamSlave
from imx import IMX

CLK_PERIOD = 20
VDMA_PERIOD = 10

CAM_CLK_0_PERIOD = 30
CAM_CLK_1_PERIOD = 30
CAM_CLK_2_PERIOD = 30

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "rtl")
MODULE_PATH = os.path.abspath(MODULE_PATH)


PRE_VBLANK = 0
PRE_HBLANK = 4
POST_VBLANK = 0
POST_HBLANK = 4

IMAGE_WIDTH = (255 * 8) - PRE_HBLANK - POST_HBLANK
IMAGE_HEIGHT = 4 - PRE_VBLANK - POST_VBLANK

def setup_dut(dut):
    cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())

def setup_cam_clocks(dut):
    cocotb.fork(Clock(dut.i_cam_0_clk, CAM_CLK_0_PERIOD).start())
    cocotb.fork(Clock(dut.i_cam_1_clk, CAM_CLK_1_PERIOD).start())
    cocotb.fork(Clock(dut.i_cam_2_clk, CAM_CLK_2_PERIOD).start())

def setup_vdma_clock(dut):
    cocotb.fork(Clock(dut.vdma_clk, VDMA_PERIOD).start())


@cocotb.test(skip = False)
def boilerplate_test(dut):
    """
    Description:
        Very Basic Functionality

    Test ID: 0

    Expected Results:
        Read from the version register
    """

    PRE_VBLANK = 0
    PRE_HBLANK = 4
    POST_VBLANK = 0
    POST_HBLANK = 4

    IMAGE_WIDTH = (255 * 8) - PRE_HBLANK - POST_HBLANK
    IMAGE_HEIGHT = 4 - PRE_VBLANK - POST_VBLANK

    dut.rst <= 1
    imx = IMX(dut, False)
    setup_cam_clocks(dut);
    setup_vdma_clock(dut);
    vdma0_slave = AXI4StreamSlave(dut, "VDMA0_AXISS", dut.vdma_clk, width=64)
    #vdma0_slave = AXI4StreamSlave(dut, "VDMA0_AXISS", dut.vdma_clk, width=32)
    dut.test_id <= 0

    dut.hsync_high <= IMAGE_WIDTH
    dut.vsync_high_total_count <= IMAGE_HEIGHT


    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)

    #data = yield axim.write(0 << 2);

    yield imx.set_image_width(IMAGE_WIDTH)
    yield imx.set_image_height(IMAGE_HEIGHT)
    yield imx.set_pre_vblank(PRE_VBLANK)
    yield imx.set_pre_hblank(PRE_HBLANK)
    yield imx.set_post_vblank(POST_VBLANK)
    yield imx.set_post_hblank(POST_HBLANK)

    #Run through all the resets

    #Strobe the camera clear signal
    yield imx.reset_camera_enable(True)
    yield Timer(CLK_PERIOD * 10)
    yield imx.reset_camera_enable(False)

    #Asynchronously toggle the camera reset signal, this is needed for the IO Serdes
    yield imx.async_reset_enable(True)
    yield Timer(CLK_PERIOD * 10)
    yield imx.async_reset_enable(False)

    #After the clock is up and running strobe the synchronous controller, this also resets the internal SM
    yield imx.sync_reset_enable(True)
    yield Timer(CLK_PERIOD * 10)
    yield imx.sync_reset_enable(False)

    # Test out trigger setup and execute
    yield imx.setup_trigger(512, 32)

    # Enable Master Mode
    yield imx.enable_camera_power(0, True)
    yield imx.enable_camera_power(1, True)
    yield imx.enable_camera_power(2, True)

    camera_count = yield imx.get_camera_count()
    dut.log.info("Number of cameras: %d" % camera_count);

    lane_count = yield imx.get_lane_width()
    dut.log.info("Number of Lanes for each camera: %d" % lane_count)

    yield imx.set_tap_delay(0, 4)
    tap_delay = yield imx.get_tap_delay(0)

    #if (tap_delay != 4):
    #    print ("Failed to set tap delay! Should have been 4, but got: %d" % tap_delay)

    aligned_flags = yield imx.get_aligned_flags()
    dut.log.info("Aligned Flags for Camera 0: 0x%08X" % ((aligned_flags >>  0) & ((1 << lane_count) - 1)))
    dut.log.info("Aligned Flags for Camera 1: 0x%08X" % ((aligned_flags >> 16) & ((1 << lane_count) - 1)))
    dut.log.info("Aligned Flags for Camera 2: 0x%08X" % ((aligned_flags >> 32) & ((1 << lane_count) - 1)))


    read_thread = cocotb.fork(vdma0_slave.read(ignore_tlast=True))
    #yield Timer(CLK_PERIOD * 10000)
    yield Timer(CLK_PERIOD * 4000)
    #yield Timer(CLK_PERIOD * 1000)
    read_thread.join()

    dut.log.info("Length of read data (1 Row Length): %d" % len(vdma0_slave.data))
    data = yield imx.get_version();
    dut.log.info("Version: 0x%08X" % data)
    dut.log.info("Done")
    '''
    dut.log.info("Data:")
    for i in range(0, 64):
        dut.log.info("0x%0X" % vdma0_slave.data[i])

    for i in range(0, len(vdma0_slave.data), 16):
        dut.log.info("0x%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X" % 
                        (vdma0_slave.data[i + 0],
                         vdma0_slave.data[i + 1],
                         vdma0_slave.data[i + 2],
                         vdma0_slave.data[i + 3],
                         vdma0_slave.data[i + 4],
                         vdma0_slave.data[i + 5],
                         vdma0_slave.data[i + 6],
                         vdma0_slave.data[i + 7],
                         vdma0_slave.data[i + 8],
                         vdma0_slave.data[i + 9],
                         vdma0_slave.data[i + 10],
                         vdma0_slave.data[i + 11],
                         vdma0_slave.data[i + 12],
                         vdma0_slave.data[i + 13],
                         vdma0_slave.data[i + 14],
                         vdma0_slave.data[i + 15]))

    '''

@cocotb.test(skip = False)
def standard_hblank_test(dut):
    """
    Description:
        Very Basic Functionality

    Test ID: 0

    Expected Results:
        Read from the version register
    """

    PRE_VBLANK = 0
    PRE_HBLANK = 8
    POST_VBLANK = 0
    POST_HBLANK = 8

    IMAGE_WIDTH = (255 * 8) - PRE_HBLANK - POST_HBLANK
    IMAGE_HEIGHT = 4 - PRE_VBLANK - POST_VBLANK

    dut.rst <= 1
    imx = IMX(dut, False)
    setup_cam_clocks(dut);
    setup_vdma_clock(dut);
    vdma0_slave = AXI4StreamSlave(dut, "VDMA0_AXISS", dut.vdma_clk, width=64)
    #vdma0_slave = AXI4StreamSlave(dut, "VDMA0_AXISS", dut.vdma_clk, width=32)
    dut.test_id <= 0

    dut.hsync_high <= IMAGE_WIDTH
    dut.vsync_high_total_count <= IMAGE_HEIGHT


    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)

    #data = yield axim.write(0 << 2);

    yield imx.set_image_width(IMAGE_WIDTH)
    yield imx.set_image_height(IMAGE_HEIGHT)
    yield imx.set_pre_vblank(PRE_VBLANK)
    yield imx.set_pre_hblank(PRE_HBLANK)
    yield imx.set_post_vblank(POST_VBLANK)
    yield imx.set_post_hblank(POST_HBLANK)

    #Run through all the resets

    #Strobe the camera clear signal
    yield imx.reset_camera_enable(True)
    yield Timer(CLK_PERIOD * 10)
    yield imx.reset_camera_enable(False)

    #Asynchronously toggle the camera reset signal, this is needed for the IO Serdes
    yield imx.async_reset_enable(True)
    yield Timer(CLK_PERIOD * 10)
    yield imx.async_reset_enable(False)

    #After the clock is up and running strobe the synchronous controller, this also resets the internal SM
    yield imx.sync_reset_enable(True)
    yield Timer(CLK_PERIOD * 10)
    yield imx.sync_reset_enable(False)

    # Test out trigger setup and execute
    yield imx.setup_trigger(512, 32)

    # Enable Master Mode
    yield imx.enable_camera_power(0, True)
    yield imx.enable_camera_power(1, True)
    yield imx.enable_camera_power(2, True)

    camera_count = yield imx.get_camera_count()
    dut.log.info("Number of cameras: %d" % camera_count);

    lane_count = yield imx.get_lane_width()
    dut.log.info("Number of Lanes for each camera: %d" % lane_count)

    yield imx.set_tap_delay(0, 4)
    tap_delay = yield imx.get_tap_delay(0)

    #if (tap_delay != 4):
    #    print ("Failed to set tap delay! Should have been 4, but got: %d" % tap_delay)

    aligned_flags = yield imx.get_aligned_flags()
    dut.log.info("Aligned Flags for Camera 0: 0x%08X" % ((aligned_flags >>  0) & ((1 << lane_count) - 1)))
    dut.log.info("Aligned Flags for Camera 1: 0x%08X" % ((aligned_flags >> 16) & ((1 << lane_count) - 1)))
    dut.log.info("Aligned Flags for Camera 2: 0x%08X" % ((aligned_flags >> 32) & ((1 << lane_count) - 1)))


    read_thread = cocotb.fork(vdma0_slave.read(ignore_tlast=True))
    #yield Timer(CLK_PERIOD * 10000)
    yield Timer(CLK_PERIOD * 4000)
    #yield Timer(CLK_PERIOD * 1000)
    read_thread.join()
    dut.log.info("Length of read data (1 Row Length): %d" % len(vdma0_slave.data))
    data = yield imx.get_version();
    dut.log.info("Version: 0x%08X" % data)
    dut.log.info("Done")

