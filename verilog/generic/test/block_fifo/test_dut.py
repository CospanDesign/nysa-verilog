import os
import sys
import cocotb
import logging
from cocotb.result import TestFailure
from cocotb.clock import Clock
import time
from array import array as Array
from cocotb.triggers import Timer, FallingEdge, ReadWrite, NextTimeStep

from block_fifo_driver import BlockFIFOWritePath
from block_fifo_driver import BlockFIFOReadPath


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
    writer = BlockFIFOWritePath(dut, "WR", dut.WR_CLK)
    reader = BlockFIFOReadPath(dut, "RD", dut.RD_CLK)
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


@cocotb.test(skip = False)
def write_256_word_test(dut):
    """
    Description:
        *

    Test ID: 1

    Expected Results:
        *
    """
    CLK_WR_PERIOD = 10
    CLK_RD_PERIOD = 10
    COUNT = 0x100
    #COUNT = 0x101
    #COUNT = 10

    dut.rst <= 1
    dut.test_id <= 1
    cocotb.fork(Clock(dut.WR_CLK, CLK_WR_PERIOD).start())
    cocotb.fork(Clock(dut.RD_CLK, CLK_RD_PERIOD).start())
    writer = BlockFIFOWritePath(dut, "WR", dut.WR_CLK)
    reader = BlockFIFOReadPath(dut, "RD", dut.RD_CLK)
    yield Timer(CLK_WR_PERIOD * 10)
    dut.rst <= 1
    yield Timer(CLK_WR_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_WR_PERIOD * 10)

    data_out = []
    for i in range(COUNT):
        data_out.append(i)

    yield writer.write(data_out)
    yield Timer(CLK_WR_PERIOD * 100)
    data = yield reader.read(COUNT)
    yield Timer(CLK_WR_PERIOD * 200)
    #print "Data:"
    #for d in data:
    #    print "0x%08X" % d


@cocotb.test(skip = False)
def write_257_word_test(dut):
    """
    Description:
        *

    Test ID: 2

    Expected Results:
        *
    """
    CLK_WR_PERIOD = 10
    CLK_RD_PERIOD = 10
    COUNT = 0x101

    dut.rst <= 1
    dut.test_id <= 2
    cocotb.fork(Clock(dut.WR_CLK, CLK_WR_PERIOD).start())
    cocotb.fork(Clock(dut.RD_CLK, CLK_RD_PERIOD).start())
    writer = BlockFIFOWritePath(dut, "WR", dut.WR_CLK)
    reader = BlockFIFOReadPath(dut, "RD", dut.RD_CLK)
    yield Timer(CLK_WR_PERIOD * 10)
    dut.rst <= 1
    yield Timer(CLK_WR_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_WR_PERIOD * 10)

    data_out = []
    for i in range(COUNT):
        data_out.append(i)

    yield writer.write(data_out)
    yield Timer(CLK_WR_PERIOD * 100)
    data = yield reader.read(COUNT)
    yield Timer(CLK_WR_PERIOD * 200)
    #print "Data:"
    #for d in data:
    #    print "0x%08X" % d


@cocotb.test(skip = False)
def write_758_word_test(dut):
    """
    Description:
        *

    Test ID: 2

    Expected Results:
        *
    """
    CLK_WR_PERIOD = 10
    CLK_RD_PERIOD = 10
    COUNT = 0x300

    dut.rst <= 1
    dut.test_id <= 2
    cocotb.fork(Clock(dut.WR_CLK, CLK_WR_PERIOD).start())
    cocotb.fork(Clock(dut.RD_CLK, CLK_RD_PERIOD).start())
    writer = BlockFIFOWritePath(dut, "WR", dut.WR_CLK)
    reader = BlockFIFOReadPath(dut, "RD", dut.RD_CLK)
    cocotb.fork(reader.read())
    yield Timer(CLK_WR_PERIOD * 10)
    dut.rst <= 1
    yield Timer(CLK_WR_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_WR_PERIOD * 10)

    data_out = []
    for i in range(COUNT):
        data_out.append(i)

    yield writer.write(data_out)
    yield Timer(CLK_WR_PERIOD * 400)
    #data = yield reader.read(COUNT)
    #yield Timer(CLK_WR_PERIOD * 200)
    #print "Data:"
    #for d in data:
    #    print "0x%08X" % d



