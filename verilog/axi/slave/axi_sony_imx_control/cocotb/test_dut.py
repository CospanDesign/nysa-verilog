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
from imx import IMX

CLK_PERIOD = 20

CAM_CLK_0_PERIOD = 10
CAM_CLK_1_PERIOD = 12
CAM_CLK_2_PERIOD = 10

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "rtl")
MODULE_PATH = os.path.abspath(MODULE_PATH)


def setup_dut(dut):
    cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())

def setup_cam_clocks(dut):
    cocotb.fork(Clock(dut.i_cam_0_clk, CAM_CLK_0_PERIOD).start())
    cocotb.fork(Clock(dut.i_cam_1_clk, CAM_CLK_1_PERIOD).start())
    cocotb.fork(Clock(dut.i_cam_2_clk, CAM_CLK_2_PERIOD).start())


@cocotb.test(skip = False)
def boilerplate_test(dut):
    """
    Description:
        Very Basic Functionality

    Test ID: 0

    Expected Results:
        Read from the version register
    """

    dut.rst <= 1
    imx = IMX(dut, False)
    dut.test_id <= 0
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)

    #data = yield axim.write(0 << 2);

    setup_cam_clocks(dut);

    #Run through all the resets
    
    #Strobe the camera clear signal
    yield imx.reset_camera()

    #Asynchronously toggle the camera reset signal, this is needed for the IO Serdes
    yield imx.reset_async_cam_clock()

    #After the clock is up and running strobe the synchronous controller, this also resets the internal SM
    yield imx.reset_sync_cam_clock_domain()

    # Test out trigger setup and execute
    yield imx.setup_trigger(512, 32)

    # Enable Master Mode
    yield imx.enable_camera_power(0, True)
    yield imx.enable_camera_power(1, True)
    yield imx.enable_camera_power(2, True)

    # Reset the TAP Delay controller
    yield imx.reset_tap_delay()

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


    yield Timer(CLK_PERIOD * 1000)
    data = yield imx.get_version();
    dut.log.info("Version: 0x%08X" % data)
    dut.log.info("Done")

