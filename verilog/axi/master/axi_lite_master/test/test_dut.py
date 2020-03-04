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
#from cocotb.drivers.amba import AXI4Slave
#from cocotb.drivers.amba import AXI4Slave
from amba import AXI4Slave

CLK_PERIOD = 10

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
    test_data = 0x01234567
    test_addr = 0x04
    test_mem_size = 1024
    dut.rst <= 1
    dut.test_id <= 0
    setup_dut(dut)
    memory = bytearray([0] * test_mem_size)
    axim = AXI4Slave(dut, "AXIS", dut.clk, memory)
    axim.log.setLevel(logging.DEBUG)
    cm = CommandMaster(dut, "CMD", dut.clk)
    cm.log.setLevel(logging.DEBUG)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 1
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 40)
    yield cm.write(test_addr, [test_data])
    yield Timer(CLK_PERIOD * 50)
    read_data = int.from_bytes(memory[test_addr:test_addr + 4], byteorder = "little", signed = False)
    print ("Read Data: 0x%08X" % read_data)
    if int(read_data) != test_data:
        print ("Data read from slave does not match the data that was written: \
                (written) 0x%08X != (read) 0x%08X" % (test_data, read_data))
        raise TestFailure()


@cocotb.test(skip = False)
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
    test_data = 0x89ABCDEF
    test_addr = 0x08
    test_mem_size = 1024
    memory = bytearray([0] * test_mem_size)

    memory[test_addr + 0] = (test_data >> 24) & 0xFF
    memory[test_addr + 1] = (test_data >> 16) & 0xFF
    memory[test_addr + 2] = (test_data >>  8) & 0xFF
    memory[test_addr + 3] = (test_data >>  0) & 0xFF


    #print ("Memory :%s" % str(memory[test_addr:test_addr + 4]))
    axim = AXI4Slave(dut, "AXIS", dut.clk, memory)
    axim.log.setLevel(logging.DEBUG)
    cm = CommandMaster(dut, "CMD", dut.clk)
    cm.log.setLevel(logging.DEBUG)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 1
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 40)
    write_data = yield cm.read(test_addr)
    yield Timer(CLK_PERIOD * 50)
    write_data = int(write_data[0])
    print ("Data: 0x%08X\n" % write_data)
    if write_data != test_data:
        print("Data written to slave does not match the data that was read: \
               (Injected) 0x%08X != (Read) 0x%08X" % (test_data, write_data))
        raise TestFailure()

@cocotb.test(skip = False)
def read_1_word_test_error(dut):
    """
    Description:
        *

    Test ID: 2

    Expected Results:
        *
    """
    dut.rst <= 1
    dut.test_id <= 2
    setup_dut(dut)
    test_data = 0x89ABCDEF
    test_addr = 32
    test_mem_size = 32
    memory = bytearray([0] * test_mem_size)

    axim = AXI4Slave(dut, "AXIS", dut.clk, memory)
    axim.log.setLevel(logging.DEBUG)
    cm = CommandMaster(dut, "CMD", dut.clk)
    cm.log.setLevel(logging.DEBUG)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 1
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 40)
    write_data = yield cm.read(test_addr)
    yield Timer(CLK_PERIOD * 50)
    status = yield cm.get_read_status()
    yield Timer(CLK_PERIOD * 50)
    if status != 0x02:
        print ("Failed to read the Slave Error!\n");
        raise TestFailure()

@cocotb.test(skip = False)
def write_1_word_test_error(dut):
    """
    Description:
        *

    Test ID: 3

    Expected Results:
        *
    """
    test_addr = 32
    test_data = 0x01234567
    test_mem_size = 32
    dut.rst <= 1
    dut.test_id <= 3
    setup_dut(dut)
    memory = bytearray([0] * test_mem_size)
    axim = AXI4Slave(dut, "AXIS", dut.clk, memory)
    axim.log.setLevel(logging.DEBUG)
    cm = CommandMaster(dut, "CMD", dut.clk)
    cm.log.setLevel(logging.DEBUG)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 1
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 40)
    yield cm.write(test_addr, [test_data])
    yield Timer(CLK_PERIOD * 50)

    status = yield cm.get_read_status()
    yield Timer(CLK_PERIOD * 50)
    if status != 0x02:
        print ("Failed to read the Slave Error!\n");
        raise TestFailure()

