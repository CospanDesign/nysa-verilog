import os
import sys
import cocotb
import logging
from cocotb.result import TestFailure
from cocotb.clock import Clock
import time
from array import array as Array
from cocotb.triggers import Timer
from cocotb.drivers.amba import AXI4LiteMaster
from i2c import *

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "rtl")
MODULE_PATH = os.path.abspath(MODULE_PATH)

CLK_PERIOD = 10

'''
@cocotb.test(skip = False)
def first_test(dut):
    """
    Description:
        Very Basic Functionality
            Startup Nysa

    Test ID: 0

    Expected Results:
        Write to the control register
    """

    dut.rst <= 1
    dut.test_id <= 0
    i2c = I2C(dut, "AXIML")
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)
    control = yield i2c.get_control()
    control = int(control)
    dut.log.info ("Control: 0x%08X" % control)
    i2c.print_control(control)
'''



@cocotb.test(skip = False)
def send_data(dut):
    """
    Description:
        Very Basic Functionality
            Startup Nysa

    Test ID: 1

    Expected Results:
        Write to the control register
    """

    dut.rst <= 1
    dut.test_id <= 1
    i2c = I2C(dut, "AXIML")
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 100)
    dut.test_id <= 1
    #control = yield i2c.get_control()
    #control = int(control)
    #dut.log.info("Attempt to reset the core")
    #yield i2c.reset_i2c_core()
    #dut.log.info("Finished Resetting the core")
    #yield Timer(CLK_PERIOD * 100)

    dut.log.info("Configure the interrupts")
    yield i2c.enable_transfer_complete_interrupt(True)
    yield Timer(CLK_PERIOD * 100)
    #d = yield i2c.is_interrupt_set(INT_TRANSFER_FINISHED)
    #dut.log.info("Transfer Complte: %s" % d)
    #yield i2c.set_speed_to_400khz()
    yield i2c.set_custom_speed(1000000)
    yield i2c.enable_i2c(True)
    yield i2c.reset_i2c_core()
    yield Timer(CLK_PERIOD * 1000)
    yield i2c.write_to_i2c(0x30, [2, 0x55])
    yield Timer(CLK_PERIOD * 1000)

    


@cocotb.test(skip = True)
def read_data(dut):
    """
    Description:
        Very Basic Functionality
            Startup Nysa

    Test ID: 1

    Expected Results:
        Write to the control register
    """

    dut.rst <= 1
    dut.test_id <= 2
    i2c = I2C(dut, "AXIML")
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 100)
    dut.test_id <= 2
    #control = yield i2c.get_control()
    #control = int(control)
    #dut.log.info("Attempt to reset the core")
    #yield i2c.reset_i2c_core()
    #dut.log.info("Finished Resetting the core")
    #yield Timer(CLK_PERIOD * 100)

    dut.log.info("Configure the interrupts")
    yield i2c.enable_transfer_complete_interrupt(True)
    yield Timer(CLK_PERIOD * 100)
    #d = yield i2c.is_interrupt_set(INT_TRANSFER_FINISHED)
    #dut.log.info("Transfer Complte: %s" % d)
    #yield i2c.set_speed_to_400khz()
    yield i2c.set_custom_speed(1000000)
    yield i2c.enable_i2c(True)
    yield i2c.reset_i2c_core()
    yield Timer(CLK_PERIOD * 100)
    yield i2c.read_from_i2c(0x30, 2)
    yield Timer(CLK_PERIOD * 100)

    







