# Simple tests for an adder module
import os
import sys
import cocotb
import logging
from cocotb.result import TestFailure
from nysa.host.sim.sim_host import NysaSim
from cocotb.clock import Clock
import time
from array import array as Array
from dut_driver import pf_hi_testerDriver

SIM_CONFIG = "sim_config.json"


CLK_PERIOD = 10

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "rtl")
MODULE_PATH = os.path.abspath(MODULE_PATH)


def setup_dut(dut):
    cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())

@cocotb.coroutine
def wait_ready(nysa, dut):

    #while not dut.hd_ready.value.get_value():
    #    yield(nysa.wait_clocks(1))

    #yield(nysa.wait_clocks(100))
    pass

@cocotb.test(skip = True)
def write_test(dut):
    """
    Description:
        Very Basic Functionality
            Startup Nysa

    Test ID: 0

    Expected Results:
        Write to all registers
    """


    dut.test_id = 0
    print "module path: %s" % MODULE_PATH
    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    nysa.pretty_print_sdb()
    driver = pf_hi_testerDriver(nysa, nysa.find_device(pf_hi_testerDriver)[0])
    print "here!"
    yield cocotb.external(driver.set_control)(0x01)
    yield (nysa.wait_clocks(100))
    v = yield cocotb.external(driver.get_control)()
    dut.log.info("V: %d" % v)
    dut.log.info("DUT Opened!")
    dut.log.info("Ready")
    yield (nysa.wait_clocks(100))

    DATA_OUT_SIZE = 6
    data_out = Array('B')
    for i in range (DATA_OUT_SIZE * 4):
        data_out.append(i % 256)

    print "Length: %d" % len(data_out)
    yield cocotb.external(driver.write)(0x00, data_out)
    yield (nysa.wait_clocks(100))


@cocotb.test(skip = True)
def read_test(dut):
    """
    Description:
        Very Basic Functionality
            Startup Nysa

    Test ID: 0

    Expected Results:
        Write to all registers
    """


    dut.test_id = 1
    print "module path: %s" % MODULE_PATH
    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    nysa.pretty_print_sdb()
    driver = pf_hi_testerDriver(nysa, nysa.find_device(pf_hi_testerDriver)[0])
    yield (nysa.wait_clocks(100))

    DATA_IN_SIZE = 10
    yield cocotb.external(driver.read)(0x00, DATA_IN_SIZE)
    yield (nysa.wait_clocks(100))

    DATA_IN_SIZE = 20
    yield cocotb.external(driver.read)(0x00, DATA_IN_SIZE)
    yield (nysa.wait_clocks(100))

@cocotb.test(skip = False)
def interrupt_test(dut):
    """
    Description:
        Very Basic Functionality
            Startup Nysa

    Test ID: 2

    Expected Results:
        Write to all registers
    """


    dut.test_id = 2
    print "module path: %s" % MODULE_PATH
    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    nysa.pretty_print_sdb()
    driver = pf_hi_testerDriver(nysa, nysa.find_device(pf_hi_testerDriver)[0])
    yield (nysa.wait_clocks(100))
    yield cocotb.external(driver.write)(0x001000, [0x00, 0x00, 0x00, 0x01])
    yield (nysa.wait_clocks(100))



