# Simple tests for an adder module
import os
import sys
import cocotb
import logging
from cocotb.result import TestFailure
from nysa.host.sim.sim_host import NysaSim
from nysa.host.driver.logic_analyzer import LogicAnalyzer
from nysa.host.driver.utils import *
from cocotb_uart_if import UARTCommWriter
from cocotb_uart_if import UARTCommReader
from cocotb_uart_if import UART
from uart_logic_analyzer import UARTLogicAnalyzer
from cocotb.clock import Clock
import time
from uart_logic_analyzer import UARTLogicAnalyzer
from array import array as Array
#from dut_driver import wb_logic_analyzerDriver

SIM_CONFIG = "sim_config.json"


CLK_PERIOD = 10

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "rtl")
MODULE_PATH = os.path.abspath(MODULE_PATH)


def setup_dut(dut):
    cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())

@cocotb.test(skip = True)
def simple_capture(dut):
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
    #uw = UARTCommWriter(dut, "uart", dut.clk)
    #ur = UARTCommReader(dut, "uart", dut.clk)
    uart = UART(dut, "uart", dut.clk)
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    nysa.pretty_print_sdb()
    driver = yield cocotb.external(LogicAnalyzer)(nysa, nysa.find_device(LogicAnalyzer)[0])
    yield cocotb.external(driver.reset)()
    yield cocotb.external(driver.enable_uart_control)(False)
    yield cocotb.external(driver.set_trigger)(0x00000001)
    yield cocotb.external(driver.set_trigger_mask)(0x00000001)
    yield cocotb.external(driver.set_trigger_edge)(0x00000001)
    yield cocotb.external(driver.set_trigger_after)(0)
    yield cocotb.external(driver.set_repeat_count)(0)
    yield cocotb.external(driver.enable_interrupts)(True)
    yield cocotb.external(driver.enable)(True)
    yield (nysa.wait_clocks)(100)
    finished = yield cocotb.external(driver.is_finished)()
    if finished:
        dut.log.info("Finished!")

    data = yield cocotb.external(driver.read_raw_data)()
    #dut.log.info("Data: %s" % str(data))
    for i in range (0, len(data), 4):
        dut.log.info("\t0x%08X" % array_to_dword(data[i: i + 4]))

    value = yield cocotb.external(driver.get_start_pos)()
    dut.log.info("Start: 0x%08X" % value)


@cocotb.test(skip = True)
def test_repeat_capture(dut):
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
    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    uw = UARTCommWriter(dut, "uart", dut.clk)
    ur = UARTCommReader(dut, "uart", dut.clk)

    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    nysa.pretty_print_sdb()
    driver = yield cocotb.external(LogicAnalyzer)(nysa, nysa.find_device(LogicAnalyzer)[0])
    yield cocotb.external(driver.reset)()
    yield cocotb.external(driver.enable_uart_control)(False)
    yield cocotb.external(driver.set_trigger)(0x00000002)
    yield cocotb.external(driver.set_trigger_mask)(0x00000002)
    yield cocotb.external(driver.set_trigger_edge)(0x00000002)
    yield cocotb.external(driver.set_trigger_after)(0)
    yield cocotb.external(driver.set_repeat_count)(2)
    yield cocotb.external(driver.enable_interrupts)(True)
    yield cocotb.external(driver.enable)(True)
    yield (nysa.wait_clocks)(100)
    finished = yield cocotb.external(driver.is_finished)()
    if finished:
        dut.log.info("Finished!")

    data = yield cocotb.external(driver.read_raw_data)()
    #dut.log.info("Data: %s" % str(data))
    for i in range (0, len(data), 4):
        dut.log.info("\t[%04X] 0x%08X" % ((i / 4), array_to_dword(data[i: i + 4])))

    value = yield cocotb.external(driver.get_start_pos)()
    dut.log.info("Start: 0x%08X" % value)


@cocotb.test(skip = True)
def test_trigger_after_capture(dut):
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
    uw = UARTCommWriter(dut, "uart", dut.clk)
    ur = UARTCommReader(dut, "uart", dut.clk)

    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    nysa.pretty_print_sdb()
    driver = yield cocotb.external(LogicAnalyzer)(nysa, nysa.find_device(LogicAnalyzer)[0])
    yield cocotb.external(driver.reset)()
    yield cocotb.external(driver.enable_uart_control)(False)
    yield cocotb.external(driver.set_trigger)           (0x00000200)
    yield cocotb.external(driver.set_trigger_mask)      (0x00000200)
    yield cocotb.external(driver.set_trigger_edge)      (0x00000200)
    yield cocotb.external(driver.set_trigger_after)(4)
    yield cocotb.external(driver.set_repeat_count)(0)
    yield cocotb.external(driver.enable_interrupts)(True)
    yield cocotb.external(driver.enable)(True)
    yield (nysa.wait_clocks)(1000)
    finished = yield cocotb.external(driver.is_finished)()
    if finished:
        dut.log.info("Finished!")

    data = yield cocotb.external(driver.read_data)()
    #dut.log.info("Data: %s" % str(data))
    for i in range (0, len(data), 1):
        #dut.log.info("\t[%04X] 0x%08X" % ((i / 4), array_to_dword(data[i: i + 4])))
        dut.log.info("\t[%04X] 0x%08X" % (i, data[i]))

    value = yield cocotb.external(driver.get_start_pos)()
    dut.log.info("Start: 0x%08X" % value)


@cocotb.test(skip = True)
def test_uart_simple(dut):
    """
    Description:
        Very Basic Functionality
            Startup Nysa

    Test ID: 3

    Expected Results:
        Write to all registers
    """
    dut.test_id = 3
    print "module path: %s" % MODULE_PATH
    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    #uw = UARTCommWriter(dut, "uart", dut.clk)
    #ur = UARTCommReader(dut, "uart", dut.clk)
    uart = UART(dut, "uart", dut.clk)
    ula =UARTLogicAnalyzer(uart, sim = True, log = logging.getLogger("cocotb"), debug = True)

    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    nysa.pretty_print_sdb()
    driver = yield cocotb.external(LogicAnalyzer)(nysa, nysa.find_device(LogicAnalyzer)[0])
    yield cocotb.external(driver.enable_uart_control)(False)
    yield (nysa.wait_clocks)(100)
    yield ula.ping()
    yield (nysa.wait_clocks)(100)
    yield ula.enable(True)
    yield (nysa.wait_clocks)(100)
    yield ula.is_enabled()
    yield (nysa.wait_clocks)(100)
    yield ula.enable(False)
    yield (nysa.wait_clocks)(100)
    yield ula.is_enabled()
    yield (nysa.wait_clocks)(100)
    yield ula.reset()
    yield (nysa.wait_clocks)(100)
    yield ula.force_trigger()
    yield (nysa.wait_clocks)(100)
    value = yield ula.get_start_pos()
    yield (nysa.wait_clocks)(100)
    value = yield ula.get_data_count()
    yield (nysa.wait_clocks)(100)
    yield ula.set_trigger(0x01234567)
    yield (nysa.wait_clocks)(100)
    yield ula.set_trigger_mask(0x01234567)
    yield (nysa.wait_clocks)(100)
    yield ula.set_trigger_after(0x01234567)
    yield (nysa.wait_clocks)(100)
    yield ula.set_trigger_edge(0x01234567)
    yield (nysa.wait_clocks)(100)
    yield ula.set_both_edge(0x01234567)
    yield (nysa.wait_clocks)(100)
    yield ula.set_repeat_count(0x01234567)
    yield (nysa.wait_clocks)(100)



@cocotb.test(skip = False)
def test_uart_simple(dut):
    """
    Description:
        Very Basic Functionality
            Startup Nysa

    Test ID: 3

    Expected Results:
        Write to all registers
    """
    dut.test_id = 3
    print "module path: %s" % MODULE_PATH
    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    #uw = UARTCommWriter(dut, "uart", dut.clk)
    #ur = UARTCommReader(dut, "uart", dut.clk)
    uart = UART(dut, "uart", dut.clk)
    ula =UARTLogicAnalyzer(uart, sim = True, log = logging.getLogger("cocotb"), debug = True)

    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    nysa.pretty_print_sdb()
    driver = yield cocotb.external(LogicAnalyzer)(nysa, nysa.find_device(LogicAnalyzer)[0])
    yield cocotb.external(driver.enable_uart_control)(True)
    yield (nysa.wait_clocks)(100)
    yield ula.set_trigger(0x00000001)
    yield (nysa.wait_clocks)(100)
    yield ula.set_trigger_mask(0x00000001)
    yield (nysa.wait_clocks)(100)
    yield ula.set_trigger_after(0x00000000)
    yield (nysa.wait_clocks)(100)
    yield ula.set_trigger_edge(0x00000001)
    yield (nysa.wait_clocks)(100)
    yield ula.set_both_edge(0x00000000)
    yield (nysa.wait_clocks)(100)
    yield ula.set_repeat_count(0x00000000)
    yield (nysa.wait_clocks)(100)
    yield ula.enable(True)
    data = yield ula.read_data()
    dut.log.info("Data: %s" % str(data))








