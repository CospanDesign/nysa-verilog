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

@cocotb.test(skip = False)
def boiler_plate_test(dut):
    """
    Description:
        *

    Test ID: 0

    Expected Results:
        *
    """
    dut.rst <= 1
    dut.test_id <= 0
    dut.i_interrupts <= 0
    setup_dut(dut)
    memory = [0] * MEM_SIZE
    cm = CommandMaster(dut, "CMD", dut.clk)
    cm.log.setLevel(logging.DEBUG)

    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 1
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 100)



@cocotb.test(skip = True)
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
    yield cm.write(0x01, [0x01234567])
    yield Timer(CLK_PERIOD * 40)


@cocotb.test(skip = True)
def write_2_words_test(dut):
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
    yield cm.write(0x01, [0x01234567,
                          0x89ABCDEF])
    yield Timer(CLK_PERIOD * 40)


@cocotb.test(skip = True)
def write_256_words_test(dut):
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
    memory = [0] * MEM_SIZE
    data = []
    for i in range(256):
        data.append(i)

    axim = AXI4Slave(dut, "AXIS", dut.clk, memory)
    axim.log.setLevel(logging.DEBUG)
    cm = CommandMaster(dut, "CMD", dut.clk)
    cm.log.setLevel(logging.DEBUG)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 1
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 40)
    yield cm.write(0x01, data)
    yield Timer(CLK_PERIOD * 400)


@cocotb.test(skip = True)
def write_256_words_with_backpreassure_test(dut):
    """
    Description:
        *

    Test ID: 3

    Expected Results:
        *
    """
    dut.rst <= 1
    dut.test_id <= 3
    ADDR = 0x04
    setup_dut(dut)
    memory = [0] * MEM_SIZE
    data_in = []
    for i in range(256):
        data_in.append(i)

    axim = AXI4Slave(dut, "AXIS", dut.clk, memory)
    axim.log.setLevel(logging.DEBUG)
    cm = CommandMaster(dut, "CMD", dut.clk)
    cm.log.setLevel(logging.DEBUG)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 1
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 40)
    cocotb.fork(cm.write(ADDR, data_in))

    yield Timer(CLK_PERIOD * 300)
    dut.test_id <= 0
    yield axim.delay(100)
    dut.test_id <= 3


    yield Timer(CLK_PERIOD * 800)
    byte_data_out = memory[ADDR: ADDR + len(data_in) * 4]

    data_out = [0] * len(data_in)
    for i in range(0, len(data_in)):
        data_out[i] =   (byte_data_out[(i * 4) + 3] << 24) |    \
                        (byte_data_out[(i * 4) + 2] << 16) |    \
                        (byte_data_out[(i * 4) + 1] <<  8) |    \
                        (byte_data_out[(i * 4) + 0] <<  0)

    for i in range(len(data_out)):
        if data_out[i] != data_in[i]:
            print "[% 4d]: 0x%08X != 0x%08X" % (i, data_in[i], data_out[i])



@cocotb.test(skip = True)
def read_1_word_test(dut):
    """
    Description:
        *

    Test ID: 4

    Expected Results:
        *
    """
    dut.rst <= 4
    dut.test_id <= 0
    setup_dut(dut)
    MEM_SIZE = 4096
    #COUNT = 10
    COUNT = 1
    ADDR = 0x00
    memory = Array('B', [0] * MEM_SIZE)
    for i in range(len(memory)):
        #memory[i] = i % 256
        memory[i] = (255 - i) % 256

    axim = AXI4Slave(dut, "AXIS", dut.clk, memory)
    axim.log.setLevel(logging.DEBUG)
    cm = CommandMaster(dut, "CMD", dut.clk)
    cm.log.setLevel(logging.DEBUG)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 1
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 40)
    #yield cm.read(0x02, 2)
    yield cm.read(ADDR, COUNT)
    yield Timer(CLK_PERIOD * 1000)


@cocotb.test(skip = True)
def read_512_word_test(dut):
    """
    Description:
        *

    Test ID: 4

    Expected Results:
        *
    """
    dut.rst <= 4
    dut.test_id <= 0
    setup_dut(dut)
    MEM_SIZE = 4096
    #COUNT = 10
    COUNT = 512
    ADDR = 0x00
    memory = Array('B', [0] * MEM_SIZE)
    for i in range(len(memory)):
        #memory[i] = i % 256
        memory[i] = (255 - i) % 256

    axim = AXI4Slave(dut, "AXIS", dut.clk, memory)
    axim.log.setLevel(logging.DEBUG)
    cm = CommandMaster(dut, "CMD", dut.clk)
    cm.log.setLevel(logging.DEBUG)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 1
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 40)
    #yield cm.read(0x02, 2)
    yield cm.read(ADDR, COUNT)
    yield Timer(CLK_PERIOD * 1000)



