import os
import sys
import cocotb
import logging
from cocotb.result import TestFailure
from cocotb.clock import Clock
import time
from array import array as Array
from cocotb.triggers import Timer, FallingEdge, ReadWrite, NextTimeStep

from axi_master_if import CommandMaster
from cocotb.drivers.amba import AXI4Slave

CLK_PERIOD = 10

MEM_SIZE = 4096
#MEM_SIZE = 8196

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, os.pardir)
MODULE_PATH = os.path.abspath(MODULE_PATH)


def setup_dut(dut):
    cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())

import cocotb
from cocotb.triggers import Timer



@cocotb.test(skip = False)
def write_1_word_test(dut):
    """
    Description:
        *

    Test ID: 0

    Expected Results:
        *
    """
    dut.rst <= 1
    dut.test_id <= 0
    setup_dut(dut)
    memory = [0] * MEM_SIZE
    axim = AXI4Slave(dut, "AXIS", dut.clk, memory)
    axim.log.setLevel(logging.DEBUG)
    cm = CommandMaster(dut, "CMD", dut.clk)
    cm.log.setLevel(logging.DEBUG)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 1
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 40)
    yield cm.write(0x01, 0x01234567)
    yield Timer(CLK_PERIOD * 50)

@cocotb.test(skip = True)
def read_1_word_test(dut):
    """
    Description:
        *

    Test ID: 1

    Expected Results:
        *
    """
    dut.rst <= 1
    dut.test_id <= 1
    setup_dut(dut)
    ADDR = 0x00
    memory = Array('B', [0] * MEM_SIZE)
    memory[0] = 0x10
    memory[1] = 0x32
    memory[2] = 0x54
    memory[3] = 0x76
    #memory = [0] * MEM_SIZE
    #memory[0] = 0x7654321
    axim = AXI4Slave(dut, "AXIS", dut.clk, memory)
    axim.log.setLevel(logging.DEBUG)
    cm = CommandMaster(dut, "CMD", dut.clk)
    cm.log.setLevel(logging.DEBUG)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 1
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 40)
    data = yield cm.read(ADDR)
    yield Timer(CLK_PERIOD * 50)


