import os
import sys
import cocotb
import logging
from cocotb.result import TestFailure
from cocotb.clock import Clock
import time
from array import array as Array
from cocotb.triggers import Timer, FallingEdge, ReadWrite, NextTimeStep

from ppfifo_driver import PPFIFOWritePath
from ppfifo_driver import PPFIFOReadPath


MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, os.pardir)
MODULE_PATH = os.path.abspath(MODULE_PATH)

@cocotb.test(skip = False)
def write_1_word_test(dut):
    """
    Description:
        *

    Test ID: 0

    Expected Results:
        *
    """
    CLK_WR_PERIOD = 10
    CLK_RD_PERIOD = 10

    dut.rst <= 1
    dut.test_id <= 0
    cocotb.fork(Clock(dut.WR_CLK, CLK_WR_PERIOD).start())
    cocotb.fork(Clock(dut.RD_CLK, CLK_RD_PERIOD).start())
    writer = PPFIFOWritePath(dut, "WR", dut.WR_CLK)
    reader = PPFIFOReadPath(dut, "RD", dut.RD_CLK)
    yield Timer(CLK_WR_PERIOD * 10)
    dut.rst <= 1
    yield Timer(CLK_WR_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_WR_PERIOD * 10)

    yield writer.write([0x00, 0x01, 0x02, 0x03])
    yield Timer(CLK_WR_PERIOD * 20)
    data = yield reader.read(4)
    yield Timer(CLK_WR_PERIOD * 20)
    print "Data:"
    for d in data:
        print "0x%08X" % d



