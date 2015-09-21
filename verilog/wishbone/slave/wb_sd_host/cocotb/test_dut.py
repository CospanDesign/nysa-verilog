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
import json
from nysa.tools.nysa_paths import get_verilog_path

SDIO_PATH = "path to sdio-device interface"

SIM_CONFIG = "sim_config.json"


CLK_PERIOD = 10

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "rtl")
MODULE_PATH = os.path.abspath(MODULE_PATH)


def setup_dut(dut):
    cocotb.fork(Clock(dut.in_clk, CLK_PERIOD).start())
    dut.request_interrupt =   0

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
    #driver = wb_sd_hostDriver(nysa, nysa.find_device(wb_sd_hostDriver)[0])
    driver = yield cocotb.external(wb_sd_hostDriver)(nysa, nysa.find_device(wb_sd_hostDriver)[0])
    #yield cocotb.external(driver.set_control)(0x01)
    yield (nysa.wait_clocks(200))
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


@cocotb.test(skip = True)
def send_simple_command(dut):
    """
    Description:
        Initiate an SD transaction

    Test ID: 1

    Expected Results:
        Enable an SD Transaction
    """
    dut.test_id = 1
    SDIO_PATH = get_verilog_path("sdio-device")
    sdio_config = os.path.join(SDIO_PATH, "sdio_configuration.json")
    config = None
    with open (sdio_config, "r") as f:
        dut.log.warning("Run %s before running this function" % os.path.join(SDIO_PATH, "tools", "generate_config.py"))
        config = json.load(f)

    #print "SDIO PATH: %s" % SDIO_PATH
    #print "module path: %s" % MODULE_PATH
    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    nysa.pretty_print_sdb()
    #driver = wb_sd_hostDriver(nysa, nysa.find_device(wb_sd_hostDriver)[0])
    driver = yield cocotb.external(wb_sd_hostDriver)(nysa, nysa.find_device(wb_sd_hostDriver)[0])
    driver.set_voltage_range(2.0, 3.6)

    yield cocotb.external(driver.enable_sd_host)(True)
    yield (nysa.wait_clocks(100))
    #yield cocotb.external(driver.send_command)(0x05, 0x01234)
    #yield cocotb.external(driver.send_command)(0x05, 0x00000)
    yield cocotb.external(driver.cmd_phy_sel)()
    yield cocotb.external(driver.cmd_io_send_op_cond)(enable_1p8v = True)
    yield cocotb.external(driver.cmd_get_relative_card_address)()
    yield cocotb.external(driver.cmd_enable_card)(True)
    yield cocotb.external(driver.cmd_enable_card)(False)
    yield cocotb.external(driver.cmd_enable_card)(False)
    yield cocotb.external(driver.cmd_go_inactive_state)()

    yield (nysa.wait_clocks(20))

@cocotb.test(skip = True)
def send_byte_test(dut):
    """
    Description:
        Initiate an SD transaction

    Test ID: 2

    Expected Results:
        Single Data Write
    """
    dut.test_id = 2
    SDIO_PATH = get_verilog_path("sdio-device")
    sdio_config = os.path.join(SDIO_PATH, "sdio_configuration.json")
    config = None
    with open (sdio_config, "r") as f:
        dut.log.warning("Run %s before running this function" % os.path.join(SDIO_PATH, "tools", "generate_config.py"))
        config = json.load(f)

    #print "SDIO PATH: %s" % SDIO_PATH
    #print "module path: %s" % MODULE_PATH
    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    #nysa.pretty_print_sdb()
    #driver = wb_sd_hostDriver(nysa, nysa.find_device(wb_sd_hostDriver)[0])
    driver = yield cocotb.external(wb_sd_hostDriver)(nysa, nysa.find_device(wb_sd_hostDriver)[0])
    #Enable SDIO
    yield cocotb.external(driver.enable_sd_host)(True)
    yield cocotb.external(driver.cmd_io_send_op_cond)(enable_1p8v = True)
    yield cocotb.external(driver.cmd_get_relative_card_address)()
    yield cocotb.external(driver.cmd_enable_card)(True)

    yield cocotb.external(driver.write_config_byte)(0x02, 0x01)
    yield (nysa.wait_clocks(1000))



@cocotb.test(skip = True)
def receive_byte_test(dut):
    """
    Description:
        Initiate an SD transaction

    Test ID: 3

    Expected Results:
        Single Data Read
    """
    dut.test_id = 3
    SDIO_PATH = get_verilog_path("sdio-device")
    sdio_config = os.path.join(SDIO_PATH, "sdio_configuration.json")
    config = None
    with open (sdio_config, "r") as f:
        dut.log.warning("Run %s before running this function" % os.path.join(SDIO_PATH, "tools", "generate_config.py"))
        config = json.load(f)

    #print "SDIO PATH: %s" % SDIO_PATH
    #print "module path: %s" % MODULE_PATH
    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    #nysa.pretty_print_sdb()
    #driver = wb_sd_hostDriver(nysa, nysa.find_device(wb_sd_hostDriver)[0])
    driver = yield cocotb.external(wb_sd_hostDriver)(nysa, nysa.find_device(wb_sd_hostDriver)[0])
    #Enable SDIO
    yield cocotb.external(driver.enable_sd_host)(True)
    yield cocotb.external(driver.cmd_io_send_op_cond)(enable_1p8v = True)
    yield cocotb.external(driver.cmd_get_relative_card_address)()
    yield cocotb.external(driver.cmd_enable_card)(True)

    value = yield cocotb.external(driver.read_config_byte)(0x00)
    dut.log.info("Read value: 0x%02X" % value)
    value = yield cocotb.external(driver.read_config_byte)(0x01)
    dut.log.info("Read value: 0x%02X" % value)
    value = yield cocotb.external(driver.read_config_byte)(0x02)
    dut.log.info("Read value: 0x%02X" % value)


    yield (nysa.wait_clocks(1000))


@cocotb.test(skip = True)
def small_multi_byte_data_write(dut):
    """
    Description:
        Perform a small write on the data bus

    Test ID: 4

    Expected Results:
        Multi byte data transfer, this will use the data bus, not FIFO mode
    """
    dut.test_id = 4
    SDIO_PATH = get_verilog_path("sdio-device")
    sdio_config = os.path.join(SDIO_PATH, "sdio_configuration.json")
    config = None
    with open (sdio_config, "r") as f:
        dut.log.warning("Run %s before running this function" % os.path.join(SDIO_PATH, "tools", "generate_config.py"))
        config = json.load(f)

    #print "SDIO PATH: %s" % SDIO_PATH
    #print "module path: %s" % MODULE_PATH
    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    #nysa.pretty_print_sdb()
    #driver = wb_sd_hostDriver(nysa, nysa.find_device(wb_sd_hostDriver)[0])
    driver = yield cocotb.external(wb_sd_hostDriver)(nysa, nysa.find_device(wb_sd_hostDriver)[0])
    #Enable SDIO
    yield cocotb.external(driver.enable_sd_host)(True)
    yield cocotb.external(driver.cmd_io_send_op_cond)(enable_1p8v = True)
    yield cocotb.external(driver.cmd_get_relative_card_address)()
    yield cocotb.external(driver.cmd_enable_card)(True)

    #data = Array('B')
    #for i in range (2):
    #    data.append(0xFF)
    #yield cocotb.external(driver.write_sd_data)(0, 0x00, [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07], fifo_mode = False, read_after_write = False)
    #yield cocotb.external(driver.write_sd_data)(0, 0x00, [0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF], fifo_mode = False, read_after_write = False)
    #yield cocotb.external(driver.write_sd_data)(0, 0x00, [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF], fifo_mode = False, read_after_write = False)
    #yield cocotb.external(driver.write_sd_data)(0, 0x00, [0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF], fifo_mode = False, read_after_write = False)

    data = Array ('B')
    for i in range (128):
        value = i % 256
        data.append(value)
    yield cocotb.external(driver.write_sd_data)(0, 0x00, data, fifo_mode = False, read_after_write = False)
    yield (nysa.wait_clocks(1000))


@cocotb.test(skip = True)
def small_multi_byte_data_read(dut):
    """
    Description:
        Perform a small read on the data bus

    Test ID: 5

    Expected Results:
        Multi byte data transfer, this will use the data bus, not CMC mode
    """
    dut.test_id = 5
    SDIO_PATH = get_verilog_path("sdio-device")
    sdio_config = os.path.join(SDIO_PATH, "sdio_configuration.json")
    config = None
    with open (sdio_config, "r") as f:
        dut.log.warning("Run %s before running this function" % os.path.join(SDIO_PATH, "tools", "generate_config.py"))
        config = json.load(f)

    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    driver = yield cocotb.external(wb_sd_hostDriver)(nysa, nysa.find_device(wb_sd_hostDriver)[0])

    #Enable SDIO
    yield cocotb.external(driver.enable_sd_host)(True)
    yield cocotb.external(driver.cmd_io_send_op_cond)(enable_1p8v = True)
    yield cocotb.external(driver.cmd_get_relative_card_address)()
    yield cocotb.external(driver.cmd_enable_card)(True)

    data = yield cocotb.external(driver.read_sd_data)(  function_id = 0,
                                                        address     = 0x00,
                                                        byte_count  = 8,
                                                        fifo_mode   = False)

    yield (nysa.wait_clocks(1000))


@cocotb.test(skip = True)
def data_block_write(dut):
    """
    Description:
        Perform a block write

    Test ID: 6

    Expected Results:
        Block Transfer (Write)
    """
    dut.test_id = 6
    SDIO_PATH = get_verilog_path("sdio-device")
    sdio_config = os.path.join(SDIO_PATH, "sdio_configuration.json")
    config = None
    with open (sdio_config, "r") as f:
        dut.log.warning("Run %s before running this function" % os.path.join(SDIO_PATH, "tools", "generate_config.py"))
        config = json.load(f)

    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    driver = yield cocotb.external(wb_sd_hostDriver)(nysa, nysa.find_device(wb_sd_hostDriver)[0])
    #Enable SDIO
    FUNCTION = 0
    yield cocotb.external(driver.enable_sd_host)(True)
    yield cocotb.external(driver.cmd_io_send_op_cond)(enable_1p8v = True)
    yield cocotb.external(driver.cmd_get_relative_card_address)()
    yield cocotb.external(driver.cmd_enable_card)(True)
    yield cocotb.external(driver.set_function_block_size)(FUNCTION, 0x08)

    #data = [0x01, 0x02, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
    #data = [0x01, 0x02, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
    data = Array ('B')
    for i in range (16):
        value = i % 256
        data.append(value)
    yield cocotb.external(driver.write_sd_data)(FUNCTION, 0x00, data, fifo_mode = False, read_after_write = False)
    yield (nysa.wait_clocks(1000))


@cocotb.test(skip = False)
def data_block_read(dut):
    """
    Description:
        Perform a block read

    Test ID: 7

    Expected Results:
        Block Transfer (Read)
    """
    dut.test_id = 7
    BLOCK_SIZE = 0x08
    READ_SIZE = 0x10

    SDIO_PATH = get_verilog_path("sdio-device")
    sdio_config = os.path.join(SDIO_PATH, "sdio_configuration.json")
    config = None
    with open (sdio_config, "r") as f:
        dut.log.warning("Run %s before running this function" % os.path.join(SDIO_PATH, "tools", "generate_config.py"))
        config = json.load(f)

    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    driver = yield cocotb.external(wb_sd_hostDriver)(nysa, nysa.find_device(wb_sd_hostDriver)[0])
    #Enable SDIO
    FUNCTION = 0
    yield cocotb.external(driver.enable_sd_host)(True)
    yield cocotb.external(driver.cmd_io_send_op_cond)(enable_1p8v = True)
    yield cocotb.external(driver.cmd_get_relative_card_address)()
    yield cocotb.external(driver.cmd_enable_card)(True)
    yield cocotb.external(driver.set_function_block_size)(FUNCTION, BLOCK_SIZE)

    #data = [0x01, 0x02, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
    #data = [0x01, 0x02, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
    data = yield cocotb.external(driver.read_sd_data)(FUNCTION, 0x00, READ_SIZE, fifo_mode = False)
    yield (nysa.wait_clocks(1000))



