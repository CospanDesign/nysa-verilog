# Simple tests for an adder module
import os
import sys
import cocotb
import logging
from cocotb.result import TestFailure
from nysa.host.driver.sdio_device_driver import SDIODeviceDriver
from nysa.host.sim.sim_host import NysaSim
from cocotb.clock import Clock
import time
from array import array as Array

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
def test_local_buffer(dut):
    """
    Description:
        Very Basic Functionality
            Startup Nysa

    Test ID: 0

    Expected Results:
        Write to the local buffer
        Read from the local buffer
    """
    dut.test_id = 0
    print "module path: %s" % MODULE_PATH
    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    nysa.pretty_print_sdb()
    driver = SDIODeviceDriver(nysa, nysa.find_device(SDIODeviceDriver)[0])

    #Enable SDIO
    yield cocotb.external(driver.enable_sdio_device)(True)
    v = yield cocotb.external(driver.is_sdio_device_enabled)()

    dut.log.info("Is SDIO Enabled: %s" % str(v))
    #Enable Interrupts
    yield cocotb.external(driver.enable_interrupt)(True)
    v = yield cocotb.external(driver.is_sdio_device_enabled)()

    dut.log.info("Is SDIO Interrupt Enabled: %s" % str(v))

    #Send an Interrupt to host
    yield cocotb.external(driver.enable_interrupt_to_host)(True)
    v = yield cocotb.external(driver.is_interrupt_to_host_enabled)()
    
    dut.log.info("Is SDIO Interrupt to host enabled: %s" % str(v))

    #Disable Interrupt to host
    yield cocotb.external(driver.enable_interrupt_to_host)(False)
    v = yield cocotb.external(driver.is_interrupt_to_host_enabled)()
    
    dut.log.info("Is SDIO Interrupt to host enabled: %s" % str(v))


    dut.log.info("DUT Opened!")
    dut.log.info("Ready")
    data_in = Array('B', [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07])
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


