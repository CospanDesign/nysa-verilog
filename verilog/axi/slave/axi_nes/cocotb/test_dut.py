import os
import sys
import cocotb
import logging
from cocotb.result import TestFailure
from cocotb.clock import Clock
import time
from array import array as Array
from cocotb.triggers import Timer, FallingEdge

from cocotb.drivers.amba import AXI4StreamSlave

from nes_hci_driver import NESHCI

CLK_PERIOD = 10

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "rtl")
MODULE_PATH = os.path.abspath(MODULE_PATH)

def setup_dut(dut):
    cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())

@cocotb.test(skip = True)
def first_test(dut):
    """
    Description:
        *

    Test ID: 0

    Expected Results:
        *
    """
    dut.rst <= 1
    dut.test_id <= 0
    #axim = AXI4LiteMaster(dut, "AXIML", dut.clk)
    nes = NESHCI(dut, "AXIML")
    video_in = AXI4StreamSlave(dut, "AXISS", dut.clk, width=24)

    setup_dut(dut)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)
    dut.log.info("Ready")

    yield nes.reset_hci()
    yield nes.reset_console()
    yield Timer(CLK_PERIOD * 10)

    #Go into debug mode
    yield nes.enter_debug()
    data = yield nes.is_debug_enabled()
    print "Debug enabled: %d" % data

    # Send NOP down to the core
    yield nes.nop()

    #Go into debug mode
    yield nes.exit_debug()

    data = yield nes.is_debug_enabled()
    print "Debug enabled: %d" % data
    yield Timer(CLK_PERIOD * 30)

    #Read a CPU Register
    REG_ADDR = 0x00
    yield nes.write_cpu_register(REG_ADDR, 0xAB)
    data = yield nes.read_cpu_register(REG_ADDR)
    print "CPU Register: 0x%02X: 0x%02X" % (REG_ADDR, data)

    #Write to cpu memory
    data_out = [0x00, 0x01, 0x02, 0x03]
    yield nes.write_cpu_mem(0x00, data_out)
    data = yield nes.read_cpu_mem(0x00, len(data_out))
    print "Data: ",
    for d in data:
        print "0x%02X " % d,
    print ""

    #Write to ppu memory
    data_out = [0x00, 0x01, 0x02, 0x03]
    yield nes.write_ppu_mem(0x00, data_out)
    data = yield nes.read_ppu_mem(0x00, len(data_out))
    print "Data: ",
    for d in data:
        print "0x%02X " % d,
    print ""

    yield Timer(CLK_PERIOD * 10)

    #yield nes.set_cart_config(0x01234567)
    yield nes.load_rom("./nestest.nes")

    yield Timer(CLK_PERIOD * 300)


@cocotb.test(skip = False)
def run_nestest(dut):
    """
    Description:
        *

    Test ID: 0

    Expected Results:
        *
    """
    dut.rst <= 1
    dut.test_id <= 0
    #axim = AXI4LiteMaster(dut, "AXIML", dut.clk)
    nes = NESHCI(dut, "AXIML")
    video_in = AXI4StreamSlave(dut, "AXISS", dut.clk, width=24)
    dut.log.info("Video in start...")

    setup_dut(dut)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)
    dut.log.info("Ready")

    yield nes.reset_hci()
    yield nes.reset_console()
    yield Timer(CLK_PERIOD * 10)
    dut.log.info("Start video in AXIS")

    cocotb.fork(video_in.read())

    dut.log.info("Load ROM")
    yield nes.load_rom("./nestest.nes")

    dut.log.info("Waiting")
    yield Timer(CLK_PERIOD * 1000)


