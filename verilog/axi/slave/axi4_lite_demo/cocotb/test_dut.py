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
    axim = AXI4LiteMaster(dut, "AXIML", dut.clk)
    setup_dut(dut)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0

    dut.log.info("Ready")
    dut.log.info("read from address 0x00")
    yield Timer(CLK_PERIOD * 10)
    data = yield axim.read(0x00);
    dut.log.info("Data from Address 0x00: 0x%08X" % data)
    yield Timer(CLK_PERIOD * 10)


    dut.log.info("write to address 0x00")
    yield axim.write(0x00, 0x10)
    yield Timer(CLK_PERIOD * 10)

    dut.log.info("read from address 0x00")
    yield Timer(CLK_PERIOD * 10)
    data = yield axim.read(0x00);
    dut.log.info("Data from Address 0x00: 0x%08X" % data)
    yield Timer(CLK_PERIOD * 10)

    dut.log.info("read from address 0x01")
    yield Timer(CLK_PERIOD * 10)
    data = yield axim.read(0x01);
    dut.log.info("Data from Address 0x01: 0x%08X" % data)
    yield Timer(CLK_PERIOD * 10)

    '''
    dut.log.info("This should fail!")
    yield axim.write(0x01, 0x00);
    '''
    yield Timer(CLK_PERIOD * 100)
    dut.log.info("Done")



