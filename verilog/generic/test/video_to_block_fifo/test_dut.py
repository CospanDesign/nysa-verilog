import os
import sys
import cocotb
import logging
from cocotb.result import TestFailure
from cocotb.clock import Clock
import time
from array import array as Array
from cocotb.triggers import Timer, FallingEdge, ReadWrite, NextTimeStep

from nes_ppu import NESPPU
from cocotb.drivers.amba import AXI4StreamSlave


MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, os.pardir)
MODULE_PATH = os.path.abspath(MODULE_PATH)

@cocotb.coroutine
def read_video(dut, axi_stream):
    while True:
        axi_stream.read()

@cocotb.test(skip = False)
def first_test(dut):
    """
    Description:
        *

    Test ID: 0

    Expected Results:
        *
    """
    CLK_WR_PERIOD = 10
    CLK_RD_PERIOD = 10

    dut.rst.setimmediatevalue(1)
    dut.i_enable.setimmediatevalue(0)
    dut.test_id.setimmediatevalue(0)
    cocotb.fork(Clock(dut.clk, CLK_WR_PERIOD).start())
    cocotb.fork(Clock(dut.rd_clk, CLK_RD_PERIOD).start())
    ppu = NESPPU(dut, "PPU", dut.clk, width = 480, height=272)
    video_out = AXI4StreamSlave(dut, "AXISS", dut.clk, width=24)


    yield Timer(CLK_WR_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_WR_PERIOD * 10)
    dut.rst <= 1
    yield Timer(CLK_WR_PERIOD * 10)
    dut.i_enable    <=  1
    cocotb.fork(ppu.run())
    #cocotb.fork(read_video(dut, video_out))
    cocotb.fork(video_out.read())

    yield Timer(CLK_WR_PERIOD * 80000)
    #yield Timer(CLK_WR_PERIOD * 100)


