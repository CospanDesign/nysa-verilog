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
from dut_driver import axi_master_testDriver

SIM_CONFIG = "sim_config.json"


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
    #Use the folowing value to find the test in the simulation (It should show up as the yellow signal at the top of the waveforms)
    dut.test_id = 0
    print "module path: %s" % MODULE_PATH
    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    nysa.pretty_print_sdb()
    driver = axi_master_testDriver(nysa, nysa.find_device(axi_master_testDriver)[0])
    dut.log.info("Ready")

    #For a demo write a value to the control register (See the axi_master_testDriver for addresses)
    WRITE_VALUE = 0x01
    dut.log.info("Writing value: 0x%08X" % WRITE_VALUE)
    yield cocotb.external(driver.set_control)(WRITE_VALUE)
    yield (nysa.wait_clocks(100))
    dut.log.info("Reading value...")
    read_value = yield cocotb.external(driver.get_control)()
    dut.log.info("Control Register: 0x%08X" % read_value)

