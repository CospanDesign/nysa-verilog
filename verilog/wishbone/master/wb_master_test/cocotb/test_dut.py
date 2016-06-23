# Simple tests for an adder module
import os
import sys
import cocotb
import logging
from cocotb.result import TestFailure
#from cocotb.triggers import ClockCycles
from cocotb.triggers import RisingEdge
from cocotb.triggers import ReadOnly

from cocotb.clock import Clock
import time
from array import array as Array
from dut_driver import wb_master_testDriver
from ppfifo_bus import PPFIFOIngress
from ppfifo_bus import PPFIFOEgress
from sim_host import NysaSim

SIM_CONFIG = "sim_config.json"


CLK_PERIOD = 10

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "rtl")
MODULE_PATH = os.path.abspath(MODULE_PATH)


def setup_dut(dut):
    cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())

@cocotb.coroutine
def ClockCycles(clock, num_cycles):
    for i in range (num_cycles):
        yield RisingEdge(clock)
        yield ReadOnly()

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


    '''
    cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())
    ingress = PPFIFOIngress(dut, "ingress", dut.clk)
    egress = PPFIFOEgress(dut, "egress", dut.clk)
    dut.test_id <= 0
    dut.rst     <= 0
    yield ClockCycles(dut.clk, 10)
    dut.rst     <= 1
    dut.log.info("Started")
    yield ClockCycles(dut.clk, 10)
    dut.rst     <= 0
    yield ClockCycles(dut.clk, 10)
    '''

    dut.test_id <= 0


    print "module path: %s" % MODULE_PATH
    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    nysa.pretty_print_sdb()
    driver = wb_master_testDriver(nysa, nysa.find_device(wb_master_testDriver)[0])
    yield cocotb.external(driver.set_control)(0x01)
    yield (nysa.wait_clocks(100))
    v = yield cocotb.external(driver.get_control)()
    dut.log.info("V: %d" % v)
    dut.log.info("DUT Opened!")
    dut.log.info("Ready")
    LENGTH = 100
    DATA = Array('B')
    for i in range (LENGTH):
        DATA.append(i % 256)

    while len(DATA) % 4 != 0:
        DATA.append(0)

    yield cocotb.external(nysa.write_memory)(0x00, DATA)


@cocotb.test(skip = False)
def memory_read_write_test(dut):

    dut.test_id <= 1

    print "module path: %s" % MODULE_PATH
    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    nysa.pretty_print_sdb()
    driver = wb_master_testDriver(nysa, nysa.find_device(wb_master_testDriver)[0])
    yield (nysa.wait_clocks(10))
    dut.log.info("Ready")
    LENGTH = 100
    DATA = Array('B')
    for i in range (LENGTH):
        DATA.append(i % 256)

    while len(DATA) % 4 != 0:
        DATA.append(0)

    yield cocotb.external(nysa.write_memory)(0x00000, DATA)
    data = yield cocotb.external(nysa.read_memory)(0x00000, (len(DATA) / 4))
    for i in range (len(DATA)):
        if DATA[i] != data[i]:
            log.error("Failed at Address: %04d: 0x%02X != 0x%02X" % (i, DATA[i], data[i]))

@cocotb.test(skip = False)
def long_memory_read_write_test(dut):

    dut.test_id <= 2

    print "module path: %s" % MODULE_PATH
    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    nysa.pretty_print_sdb()
    driver = wb_master_testDriver(nysa, nysa.find_device(wb_master_testDriver)[0])
    yield (nysa.wait_clocks(10))
    dut.log.info("Ready")
    LENGTH = 1024
    DATA = Array('B')
    for i in range (LENGTH):
        DATA.append(i % 256)

    while len(DATA) % 4 != 0:
        DATA.append(0)

    yield cocotb.external(nysa.write_memory)(0x00000, DATA)
    data = yield cocotb.external(nysa.read_memory)(0x00000, (len(DATA) / 4))
    for i in range (len(DATA)):
        if DATA[i] != data[i]:
            log.error("Failed at Address: %04d: 0x%02X != 0x%02X" % (i, DATA[i], data[i]))


@cocotb.test(skip = False)
def interrupt_test(dut):
    """
    Description:
        Initiate an interrupt

    Test ID: 3

    Expected Results:
        Detect an interrupt
    """

    dut.test_id <= 3


    print "module path: %s" % MODULE_PATH
    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    nysa.pretty_print_sdb()
    driver = wb_master_testDriver(nysa, nysa.find_device(wb_master_testDriver)[0])
    yield cocotb.external(driver.set_control)(0x02)

    yield (nysa.wait_clocks(1000))


