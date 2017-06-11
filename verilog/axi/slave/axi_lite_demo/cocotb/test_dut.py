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

CLK_PERIOD = 10

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "rtl")
MODULE_PATH = os.path.abspath(MODULE_PATH)


def setup_dut(dut):
    cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())


@cocotb.test(skip = False)
def write_test(dut):
    """
    Description:
        Very Basic Functionality
            Startup Nysa

    Test ID: 0

    Expected Results:
        Write to the control register
    """

    dut.rst <= 1
    dut.test_id <= 0
    axim = AXI4LiteMaster(dut, "AXIML", dut.clk)
    setup_dut(dut)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)

    #data = yield axim.write(0 << 2);
    data = yield axim.write(0x00 << 2, 0x01234567);
    yield Timer(CLK_PERIOD * 100)
    dut.log.info("Done")

@cocotb.test(skip = False)
def read_test(dut):
    """
    Description:
        Very Basic Functionality
            Startup Nysa

    Test ID: 1

    Expected Results:
        Read from the version register
    """

    dut.rst <= 1
    dut.test_id <= 1
    axim = AXI4LiteMaster(dut, "AXIML", dut.clk)
    setup_dut(dut)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)

    #data = yield axim.write(0 << 2);
    data = yield axim.read(0x02 << 2);
    yield Timer(CLK_PERIOD * 100)
    dut.log.info("Done")

