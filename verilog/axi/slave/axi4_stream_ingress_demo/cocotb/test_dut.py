import os
import sys
import cocotb
import logging
from cocotb.result import TestFailure
from cocotb.clock import Clock
import time
from array import array as Array
from cocotb.triggers import Timer

from cocotb.drivers.amba import AXI4StreamMaster

CLK_PERIOD = 10

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "rtl")
MODULE_PATH = os.path.abspath(MODULE_PATH)


def setup_dut(dut):
    cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())


@cocotb.test(skip = False)
def first_test(dut):
    """
    Description:
        Very Basic Functionality
            Startup Nysa

    Test ID: 0

    Expected Results:
        Write to all registers
    """

    dut.rst <= 1
    axim = AXI4StreamMaster(dut, "AXIMS", dut.clk)
    setup_dut(dut)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0

    yield Timer(CLK_PERIOD * 10)

    dut.log.info("Write 2 32-bits of data")
    data = [0x00000000, 0x00000001]
    yield axim.write(data)
    yield Timer(CLK_PERIOD * 100)

    dut.log.info("Done")



