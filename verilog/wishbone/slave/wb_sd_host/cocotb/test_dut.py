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
from dut_driver import wb_sd_hostDriver

SIM_CONFIG = "sim_config.json"


CLK_PERIOD = 10

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "rtl")
MODULE_PATH = os.path.abspath(MODULE_PATH)


def setup_dut(dut):
    cocotb.fork(Clock(dut.in_clk, CLK_PERIOD).start())

@cocotb.coroutine
def wait_ready(nysa, dut):

    #while not dut.hd_ready.value.get_value():
    #    yield(nysa.wait_clocks(1))

    #yield(nysa.wait_clocks(100))
    pass

@cocotb.test(skip = True)
def first_test(dut):
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
    driver = wb_sd_hostDriver(nysa, nysa.find_device(wb_sd_hostDriver)[0])
    yield cocotb.external(driver.set_control)(0x01)
    yield (nysa.wait_clocks(100))
    v = yield cocotb.external(driver.get_control)()
    dut.log.info("V: %d" % v)
    dut.log.info("DUT Opened!")
    dut.log.info("Ready")
    test_data = [0x00, 0x01, 0x02, 0x03]
    yield cocotb.external(nysa.write_memory)(0x00, test_data)
    yield (nysa.wait_clocks(10))
    dut.log.info("Wrote %s to memory" % (test_data))
    data = yield cocotb.external(nysa.read_memory)(0x00, 1)
    dut.log.info("Read back %s from memory" % test_data)


@cocotb.test(skip = False)
def send_simple_command(dut):
    """
    Description:
        Initiate an SD transaction

    Test ID: 1

    Expected Results:
        Enable an SD Transaction
    """
    dut.test_id = 1
    print "module path: %s" % MODULE_PATH
    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    nysa.pretty_print_sdb()
    driver = wb_sd_hostDriver(nysa, nysa.find_device(wb_sd_hostDriver)[0])
    yield cocotb.external(driver.set_control)(0x01)
    yield (nysa.wait_clocks(100))
    #yield cocotb.external(driver.send_command)(0x05, 0x01234)
    yield cocotb.external(driver.send_command)(0x05, 0x00000)
    yield (nysa.wait_clocks(1000))

