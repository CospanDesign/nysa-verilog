# Simple tests for an adder module
import os
import sys
import cocotb
import logging
from cocotb.result import TestFailure
from nysa.host.sim.sim_host import NysaSim
from nysa.host.sim.sim_uart_host import NysaSimUart
from cocotb.clock import Clock
import time
from array import array as Array
from dut_driver import uart_if_testerDriver
from cocotb_uart_if import UART
from nysa.host.driver.utils import *
from nysa.common.print_utils import *
import binascii

SIM_CONFIG = "sim_config.json"


CLK_PERIOD = 10

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "rtl")
MODULE_PATH = os.path.abspath(MODULE_PATH)

@cocotb.test(skip = True)
def ping_test(dut):
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
    uart = UART(dut, "uart", dut.clk)
    nysa = NysaSimUart(dut, uart, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH], status = None)
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    nysa.pretty_print_sdb()

    data = Array('B', "L0000000000000000000000000000000")
    yield uart.write(data)
    yield uart.read(32)
    data = uart.get_data()
    print "Response: %s" % list_to_hex_string(data)
    yield (nysa.wait_clocks(100))

@cocotb.test(skip = True)
def write_test(dut):
    """
    Description:
        Very Basic Functionality
            Startup Nysa

    Test ID: 1

    Expected Results:
        Write to all registers
    """
    dut.test_id = 1
    print "module path: %s" % MODULE_PATH
    uart = UART(dut, "uart", dut.clk)
    nysa = NysaSimUart(dut, uart, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH], status = None)
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    nysa.pretty_print_sdb()

    address = 0x01000000
    data = Array('B', [0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF])

    length = (len(data) / 4)
    write_cmd = "L%0.7X00000001%0.8X"
    write_cmd = (write_cmd) % (length, address)
    #write_cmd += binascii.hexlify(bytearray(data))
    #write_cmd = Array('B', write_cmd)
    for d in data:
        write_cmd += "%X" % ((d >> 4) & 0xF)
        write_cmd += "%X" % (d & 0xF)

    #print "Write Command: %s" % write_cmd
    write_cmd = Array('B', write_cmd)
    #print "Write Command: %s" % list_to_hex_string(write_cmd)
    yield uart.write(write_cmd)
    yield uart.read(32)

    data = uart.get_data()
    #print "Response: %s" % list_to_hex_string(data)
    yield (nysa.wait_clocks(1000))


@cocotb.test(skip = False)
def read_test(dut):
    """
    Description:
        Very Basic Functionality
            Startup Nysa

    Test ID: 1

    Expected Results:
        Write to all registers
    """
    dut.test_id = 1
    print "module path: %s" % MODULE_PATH
    uart = UART(dut, "uart", dut.clk)
    nysa = NysaSimUart(dut, uart, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH], status = None)
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    nysa.pretty_print_sdb()

    address = 0x01000000
    length = 3
    write_cmd = "L%0.7X00000002%0.8X00000000"
    write_cmd = (write_cmd) % (length, address)

    write_cmd = Array('B', write_cmd)
    #print "Write Command: %s" % list_to_hex_string(write_cmd)
    yield uart.write(write_cmd)
    yield uart.read(24 + (length * 8))
    strdata = uart.get_data()
    #print "Data: %s" % strdata.tostring()
    data = Array('B', strdata[24:].tostring().decode("hex"))
    print "Data: %s" % list_to_hex_string(data)

    yield (nysa.wait_clocks(1000))

    address = 0x01000000
    length = 4
    write_cmd = "L%0.7X00000002%0.8X00000000"
    write_cmd = (write_cmd) % (length, address)

    write_cmd = Array('B', write_cmd)
    #print "Write Command: %s" % list_to_hex_string(write_cmd)
    yield uart.write(write_cmd)
    yield uart.read(24 + (length * 8))

    strdata = uart.get_data()
    #print "Data: %s" % strdata.tostring()
    data = Array('B', strdata[24:].tostring().decode("hex"))
    print "Data: %s" % list_to_hex_string(data)

    yield (nysa.wait_clocks(3000))

