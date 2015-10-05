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
from dut_driver import wb_sdio_deviceDriver

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


    dut.test_id = 0
    print "module path: %s" % MODULE_PATH
    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    nysa.pretty_print_sdb()
    driver = wb_sdio_deviceDriver(nysa, nysa.find_device(wb_sdio_deviceDriver)[0])
    print "here!"
    yield cocotb.external(driver.set_control)(0x01)
    v = yield cocotb.external(driver.get_control)()
    dut.log.info("V: %d" % v)
    dut.log.info("DUT Opened!")
    dut.log.info("Ready")
    data_in = Array('B', [0x00, 0x01, 0x02, 0x03])
    yield cocotb.external(driver.write_local_buffer)(0x00, data_in)
    data_out = yield cocotb.external(driver.read_local_buffer)(0x00, (len(data_in) / 4))
    print "data out: %s" % print_hex_array(data_out)

def print_hex_array(a):
    s = None
    for i in a:
        if s is None:
            s = "["
        else:
            s += ", "

        s += "0x%02X" % i

    s += "]"

    return s


