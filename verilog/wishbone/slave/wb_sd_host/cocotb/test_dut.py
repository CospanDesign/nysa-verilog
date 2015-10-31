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
from nysa.host.driver.sd_host_driver import SDHostException
from nysa.host.driver.sd_host_driver import SDHostDriver

import json
from nysa.tools.nysa_paths import get_verilog_path

SDIO_PATH = "path to sdio-device interface"
SIM_CONFIG = "sim_config.json"

CLK_PERIOD = 10

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "rtl")
MODULE_PATH = os.path.abspath(MODULE_PATH)

interrupt_called = False
data_is_ready = False

def setup_dut(dut):
    cocotb.fork(Clock(dut.in_clk, CLK_PERIOD).start())
    dut.request_interrupt =   0
    global interrupt_called
    interrupt_called = False
    global data_is_ready
    data_is_ready = False

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
    #print "module path: %s" % MODULE_PATH
    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    nysa.pretty_print_sdb()
    #driver = SDHostDriver(nysa, nysa.find_device(SDHostDriver)[0])
    driver = yield cocotb.external(SDHostDriver)(nysa, nysa.find_device(SDHostDriver)[0])
    #yield cocotb.external(driver.set_control)(0x01)
    yield (nysa.wait_clocks(200))
    v = yield cocotb.external(driver.get_control)()
    dut.log.debug("V: %d" % v)
    dut.log.debug("DUT Opened!")
    dut.log.debug("Ready")
    test_data = [0x00, 0x01, 0x02, 0x03]
    yield cocotb.external(nysa.write_memory)(0x00, test_data)
    yield (nysa.wait_clocks(10))
    dut.log.debug("Wrote %s to memory" % (test_data))
    data = yield cocotb.external(nysa.read_memory)(0x00, 1)
    dut.log.debug("Read back %s from memory" % test_data)
    fail = False
    for i in range(len(data)):
        if data[i] != test_data[i]:
            raise TestFailure("Data into memory != Data out of memory: %s != %s" %
                                (print_hex_array(test_data), print_hex_array(data)))

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
    #driver = SDHostDriver(nysa, nysa.find_device(SDHostDriver)[0])
    driver = yield cocotb.external(SDHostDriver)(nysa, nysa.find_device(SDHostDriver)[0])
    driver.set_voltage_range(2.0, 3.6)

    yield cocotb.external(driver.enable_sd_host)(True)
    yield (nysa.wait_clocks(100))

    yield cocotb.external(driver.cmd_phy_sel)()

    yield cocotb.external(driver.cmd_io_send_op_cond)(enable_1p8v = False)
    if dut.sdio_device.card_controller.v1p8_sel.value.get_value() == True:
        raise TestFailure ("1.8V Switch Voltage Before Request")

    yield cocotb.external(driver.cmd_io_send_op_cond)(enable_1p8v = True)
    if dut.sdio_device.card_controller.v1p8_sel.value.get_value() == False:
        raise TestFailure ("Failed to set 1.8V Switch Voltage Request")

    yield cocotb.external(driver.cmd_get_relative_card_address)()
    if dut.sdio_device.card_controller.state.value.get_value() != 2:
        raise TestFailure ("Card Should Be In Standby State Right Now")

    yield cocotb.external(driver.cmd_enable_card)(True)
    if dut.sdio_device.card_controller.state.value.get_value() != 3:
        raise TestFailure ("Card Should Be In Command State Right Now")

    yield cocotb.external(driver.cmd_enable_card)(False)
    if dut.sdio_device.card_controller.state.value.get_value() != 2:
        raise TestFailure ("Card Should Be In Standby State Right Now")

    yield cocotb.external(driver.cmd_go_inactive_state)()
    if dut.sdio_device.card_controller.state.value.get_value() != 5:
        raise TestFailure ("Card Should Be In Standby State Right Now")

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
    #driver = SDHostDriver(nysa, nysa.find_device(SDHostDriver)[0])
    driver = yield cocotb.external(SDHostDriver)(nysa, nysa.find_device(SDHostDriver)[0])
    #Enable SDIO
    yield cocotb.external(driver.enable_sd_host)(True)
    yield cocotb.external(driver.cmd_io_send_op_cond)(enable_1p8v = True)
    if dut.sdio_device.card_controller.v1p8_sel.value.get_value() == False:
        raise TestFailure ("Failed to set 1.8V Switch Voltage Request")

    yield cocotb.external(driver.cmd_get_relative_card_address)()
    if dut.sdio_device.card_controller.state.value.get_value() != 2:
        raise TestFailure ("Card Should Be In Standby State Right Now")

    yield cocotb.external(driver.cmd_enable_card)(True)
    if dut.sdio_device.card_controller.state.value.get_value() != 3:
        raise TestFailure ("Card Should Be In Command State Right Now")

    yield cocotb.external(driver.write_config_byte)(0x02, 0x01)
    if dut.sdio_device.cia.cccr.o_func_enable.value.get_value() != 1:
        raise TestFailure ("Failed to write configuration byte to CCCR Memory Space")

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
    #driver = SDHostDriver(nysa, nysa.find_device(SDHostDriver)[0])
    driver = yield cocotb.external(SDHostDriver)(nysa, nysa.find_device(SDHostDriver)[0])
    #Enable SDIO
    yield cocotb.external(driver.enable_sd_host)(True)
    yield cocotb.external(driver.cmd_io_send_op_cond)(enable_1p8v = True)
    yield cocotb.external(driver.cmd_get_relative_card_address)()
    yield cocotb.external(driver.cmd_enable_card)(True)

    value = yield cocotb.external(driver.read_config_byte)(0x00)
    if value != 0x43:
        raise TestFailure("Failed to Read Configuration Byte at Address 0: bad value: 0x%02X" % value)
    dut.log.debug("Read value: 0x%02X" % value)
    value = yield cocotb.external(driver.read_config_byte)(0x01)
    if value != 0x03:
        raise TestFailure("Failed to Read Configuration Byte at Address 1: bad value: 0x%02X" % value)
    dut.log.debug("Read value: 0x%02X" % value)
    value = yield cocotb.external(driver.read_config_byte)(0x02)
    if value != 0x00:
        raise TestFailure("Failed to Read Configuration Byte at Address 2: bad value: 0x%02X" % value)
    dut.log.debug("Read value: 0x%02X" % value)

    yield (nysa.wait_clocks(1000))


@cocotb.test(skip = False)
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
    #driver = SDHostDriver(nysa, nysa.find_device(SDHostDriver)[0])
    driver = yield cocotb.external(SDHostDriver)(nysa, nysa.find_device(SDHostDriver)[0])
    #Enable SDIO
    yield cocotb.external(driver.enable_sd_host)(True)
    yield cocotb.external(driver.cmd_io_send_op_cond)(enable_1p8v = True)
    yield cocotb.external(driver.cmd_get_relative_card_address)()
    yield cocotb.external(driver.cmd_enable_card)(True)

    #data = Array ('B', [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07])
    data = Array ('B')
    for i in range (8):
        value = i % 256
        data.append(value)
    yield cocotb.external(driver.write_sd_data)(0, 0x00, data, fifo_mode = False, read_after_write = False)
    value = dut.sdio_device.cia.cccr.o_func_enable.value.get_value()
    if value != 0x02:
        raise TestFailure ("Failed to write configuration byte to CCCR Memory Space: Should be 0x02 is: 0x%02X" % value)
    value = dut.sdio_device.cia.cccr.o_func_int_enable.value.get_value()
    if value != 0x04:
        raise TestFailure ("Failed to write configuration byte to CCCR Memory Space: Should be 0x04 is: 0x%02X" % value)
    yield (nysa.wait_clocks(1000))


@cocotb.test(skip = False)
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
    driver = yield cocotb.external(SDHostDriver)(nysa, nysa.find_device(SDHostDriver)[0])

    #Enable SDIO
    yield cocotb.external(driver.enable_sd_host)(True)
    yield cocotb.external(driver.cmd_io_send_op_cond)(enable_1p8v = True)
    yield cocotb.external(driver.cmd_get_relative_card_address)()
    yield cocotb.external(driver.cmd_enable_card)(True)

    data = yield cocotb.external(driver.read_sd_data)(  function_id = 0,
                                                        address     = 0x00,
                                                        byte_count  = 8,
                                                        fifo_mode   = False)

    #print "data: %s" % print_hex_array(data)
    fail = False
    test_data = Array('B', [0x43, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
    for i in range (len(data)):
        if data[i] != test_data[i]:
            fail = True
            break

    if fail:
        raise TestFailure("Multi-Byte Read incorrect: %s != %s" % (print_hex_array(test_data), print_hex_array(data)))

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
    FUNCTION = 1
    ADDRESS = 0x00
    BLOCK_SIZE = 0x08
    SIZE = 0x10

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
    driver = yield cocotb.external(SDHostDriver)(nysa, nysa.find_device(SDHostDriver)[0])
    #Enable SDIO

    yield cocotb.external(driver.enable_sd_host)(True)
    yield cocotb.external(driver.cmd_io_send_op_cond)(enable_1p8v = True)
    yield cocotb.external(driver.cmd_get_relative_card_address)()
    yield cocotb.external(driver.cmd_enable_card)(True)

    #Enable Function
    yield cocotb.external(driver.enable_function)(FUNCTION)
    yield cocotb.external(driver.set_function_block_size)(FUNCTION, BLOCK_SIZE)

    write_data = Array ('B')
    for i in range (SIZE):
        value = i % 256
        write_data.append(value)
    yield cocotb.external(driver.write_sd_data)(FUNCTION, ADDRESS, write_data, fifo_mode = False, read_after_write = False)
    yield (nysa.wait_clocks(2000))
    read_data = yield cocotb.external(driver.read_sd_data)( function_id = FUNCTION,
                                                            address     = ADDRESS,
                                                            byte_count  = len(write_data),
                                                            fifo_mode   = False)
    yield (nysa.wait_clocks(2000))
    fail = False
    for i in range(len(write_data)):
        if write_data[i] != read_data[i]:
            fail = True

    if fail:
        raise TestFailure("Block Write Transfer Failed, %s != %s" % (print_hex_array(write_data), print_hex_array(read_data)))


@cocotb.test(skip = True)
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
    SIZE = 0x10
    FUNCTION = 0
    ADDRESS = 0x00

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
    driver = yield cocotb.external(SDHostDriver)(nysa, nysa.find_device(SDHostDriver)[0])
    #Enable SDIO
    yield cocotb.external(driver.enable_sd_host)(True)
    yield cocotb.external(driver.cmd_io_send_op_cond)(enable_1p8v = True)
    yield cocotb.external(driver.cmd_get_relative_card_address)()
    yield cocotb.external(driver.cmd_enable_card)(True)
    yield cocotb.external(driver.set_function_block_size)(FUNCTION, BLOCK_SIZE)

    data = yield cocotb.external(driver.read_sd_data)(FUNCTION, ADDRESS, SIZE, fifo_mode = False)
    print "Data: %s" % print_hex_array(data)
    yield (nysa.wait_clocks(2000))

@cocotb.test(skip = True)
def data_async_block_read(dut):
    """
    Description:
        Perform a block read using asynchronous transfer

    Test ID: 8

    Expected Results:
        Block Transfer (Read)
    """
    dut.test_id = 8
    ADDRESS = 0x00
    FUNCTION = 1
    BLOCK_SIZE = 0x08
    SIZE = 0x10

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
    driver = yield cocotb.external(SDHostDriver)(nysa, nysa.find_device(SDHostDriver)[0])
    #Enable SDIO
    yield cocotb.external(driver.enable_sd_host)(True)
    yield cocotb.external(driver.cmd_io_send_op_cond)(enable_1p8v = True)
    yield cocotb.external(driver.cmd_get_relative_card_address)()
    yield cocotb.external(driver.cmd_enable_card)(True)

    #Enable Function
    yield cocotb.external(driver.set_function_block_size)(FUNCTION, BLOCK_SIZE)
    yield cocotb.external(driver.enable_function)(FUNCTION)

    write_data = Array ('B')
    for i in range (SIZE):
        value = i % 256
        write_data.append(value)
    yield cocotb.external(driver.write_sd_data)(FUNCTION, ADDRESS, write_data, fifo_mode = False, read_after_write = False)
    yield cocotb.external(driver.set_async_dma_reader_callback)(dma_read_callback)
    yield cocotb.external(driver.enable_async_dma_reader)(True)
    yield cocotb.external(driver.read_sd_data)(FUNCTION, ADDRESS, SIZE, fifo_mode = False)
    dut.log.debug("Waiting for function to finish...")
    yield (nysa.wait_clocks(4000))
    if not data_is_ready:
        raise TestFailure("Async Read Never Finished!")

    read_data = driver.read_async_data()
    dut.log.debug("Async Data: %s" % print_hex_array(read_data))
    fail = False
    for i in range(len(write_data)):
        if write_data[i] != read_data[i]:
            fail = True
    if fail:
        raise TestFailure("Async Block Read Transfer Failed, %s != %s" % (print_hex_array(write_data), print_hex_array(read_data)))

@cocotb.test(skip = True)
def data_async_block_read_with_read_wait(dut):
    """
    Description:
        Perform a block read using asynchronous transfer with read wait

    Test ID: 9

    Expected Results:
        Block Transfer (Read)
    """
    dut.test_id = 9
    ADDRESS = 0x00
    FUNCTION = 1
    BLOCK_SIZE = 0x08
    SIZE = 0x10

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
    driver = yield cocotb.external(SDHostDriver)(nysa, nysa.find_device(SDHostDriver)[0])
    #Enable SDIO
    yield cocotb.external(driver.enable_sd_host)(True)
    yield cocotb.external(driver.cmd_io_send_op_cond)(enable_1p8v = True)
    yield cocotb.external(driver.cmd_get_relative_card_address)()
    yield cocotb.external(driver.cmd_enable_card)(True)

    rw_support = yield cocotb.external(driver.is_read_wait_supported)()

    #Enable Function
    yield cocotb.external(driver.set_function_block_size)(FUNCTION, BLOCK_SIZE)
    yield cocotb.external(driver.enable_function)(FUNCTION)

    write_data = Array ('B')
    for i in range (SIZE):
        value = i % 256
        write_data.append(value)
    yield cocotb.external(driver.write_sd_data)(FUNCTION, ADDRESS, write_data, fifo_mode = False, read_after_write = False)

    #XXX: Debug why this doesn't work sometimes!
    #rw_support = yield cocotb.external(driver.is_read_wait_supported)()

    yield cocotb.external(driver.set_async_dma_reader_callback)(dma_read_callback)
    yield cocotb.external(driver.enable_async_dma_reader)(True)

    dut.log.debug("Read Wait Supported: %s" % str(rw_support))

    data = yield cocotb.external(driver.read_sd_data)(FUNCTION, ADDRESS, SIZE, fifo_mode = False)

    dut.log.debug("Waiting for function to finish...")

    dut.request_read_wait   = 1;
    yield (nysa.wait_clocks(2000))
    dut.request_read_wait   = 0;

    yield (nysa.wait_clocks(3000))
    if not data_is_ready:
        raise TestFailure("Async Read Never Finished!")
    read_data = driver.read_async_data()
    dut.log.debug("Async Data: %s" % print_hex_array(read_data))
    fail = False
    for i in range(len(write_data)):
        if write_data[i] != read_data[i]:
            fail = True
    if fail:
        raise TestFailure("Async Block Read Transfer Failed, %s != %s" % (print_hex_array(write_data), print_hex_array(read_data)))

@cocotb.test(skip = True)
def detect_interrupt(dut):
    """
    Description:
        Detect an interrupt

    Test ID: 10

    Expected Results:
        Block Transfer (Read)
    """
    dut.test_id = 10

    FUNCTION = 1
    BLOCK_SIZE = 0x08
    READ_SIZE = 0x18

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
    driver = yield cocotb.external(SDHostDriver)(nysa, nysa.find_device(SDHostDriver)[0])
    #Enable SDIO
    yield cocotb.external(driver.enable_sd_host)(True)
    yield cocotb.external(driver.cmd_io_send_op_cond)(enable_1p8v = True)
    yield cocotb.external(driver.cmd_get_relative_card_address)()
    yield cocotb.external(driver.cmd_enable_card)(True)

    #Configure an interrupt callback
    driver.set_interrupt_callback(interrupt_callback)

    #Enable Function
    yield cocotb.external(driver.enable_function)(FUNCTION)
    #Enable Interrupts on Device
    yield cocotb.external(driver.enable_function_interrupt)(FUNCTION)
    pending = yield cocotb.external(driver.is_interrupt_pending)(FUNCTION)
    dut.log.debug("Is Interrupt Pending? %s" % pending)

    #Enable Interrupt on controller
    yield cocotb.external(driver.enable_interrupt)(True)
    yield (nysa.wait_clocks(100))
    #Generate an interrupt
    dut.request_interrupt = 1
    #Detect an interrupt from the device
    pending = yield cocotb.external(driver.is_interrupt_pending)(FUNCTION)
    dut.log.debug("Is Interrupt Pending? %s" % pending)

    yield (nysa.wait_clocks(3000))
    if not interrupt_called:
        raise TestFailure("Interrupt was not detected")

@cocotb.test(skip = True)
def data_async_block_read_write_long_transfer(dut):
    """
    Description:
        Perform a block read using asynchronous transfer

    Test ID: 11

    Expected Results:
        Block Transfer (Read)
    """
    dut.test_id = 11
    ADDRESS = 0x00
    FUNCTION = 1
    BLOCK_SIZE = 0x08
    SIZE = 0x18

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
    driver = yield cocotb.external(SDHostDriver)(nysa, nysa.find_device(SDHostDriver)[0])
    #Enable SDIO
    yield cocotb.external(driver.enable_sd_host)(True)
    yield cocotb.external(driver.cmd_io_send_op_cond)(enable_1p8v = True)
    yield cocotb.external(driver.cmd_get_relative_card_address)()
    yield cocotb.external(driver.cmd_enable_card)(True)

    #Enable Function
    yield cocotb.external(driver.enable_function)(FUNCTION)
    yield cocotb.external(driver.set_function_block_size)(FUNCTION, BLOCK_SIZE)

    write_data = Array ('B')
    for i in range (SIZE):
        value = i % 256
        write_data.append(value)
    yield cocotb.external(driver.write_sd_data)(FUNCTION, ADDRESS, write_data, fifo_mode = False, read_after_write = False)
    yield cocotb.external(driver.set_async_dma_reader_callback)(dma_read_callback)
    yield cocotb.external(driver.enable_async_dma_reader)(True)
    yield cocotb.external(driver.read_sd_data)(FUNCTION, ADDRESS, SIZE, fifo_mode = False)
    dut.log.debug("Waiting for function to finish...")
    yield (nysa.wait_clocks(4000))
    if not data_is_ready:
        raise TestFailure("Async Read Never Finished!")

    read_data = driver.read_async_data()
    dut.log.debug("Async Data: %s" % print_hex_array(read_data))
    fail = False
    for i in range(len(write_data)):
        if write_data[i] != read_data[i]:
            fail = True
    if fail:
        raise TestFailure("Async Block Read Transfer Failed, %s != %s" % (print_hex_array(write_data), print_hex_array(read_data)))



def interrupt_callback():
    global interrupt_called
    interrupt_called = True
    #print "INTERRRRUUUUPPPPTTTT CALLLLLLBACKKKKK!!!!"

def dma_read_callback(data):
    global data_is_ready
    data_is_ready = True
    #print "Data is ready!: %s" % print_hex_array(data)

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
