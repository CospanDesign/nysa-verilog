# Simple tests for an adder module
import os
import sys
import cocotb
import logging
from cocotb.result import TestFailure
#from nysa.host.sim.sim_host import NysaSim
from sim_host import NysaSim
from cocotb.clock import Clock
import time
from array import array as Array
from dut_driver import ft_fifo_testerDriver
from nysa.host.driver.utils import list_to_hex_string
from cocotb.triggers import RisingEdge
from cocotb.triggers import ReadOnly
from cocotb.triggers import ClockCycles


SIM_CONFIG = "sim_config.json"


CLK_PERIOD = 10

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "rtl")
MODULE_PATH = os.path.abspath(MODULE_PATH)


def setup_dut(dut):
    dut.back_preassure  <=  0

@cocotb.test(skip = True)
def small_write_read(dut):
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
    driver = ft_fifo_testerDriver(nysa, nysa.find_device(ft_fifo_testerDriver)[0])
    dut.log.info("Ready")

    #For a demo write a value to the control register (See the ${SDB_NAME}Driver for addresses)
    WRITE_VALUE = 0x01
    dut.log.info("Writing value: 0x%08X" % WRITE_VALUE)
    yield cocotb.external(driver.set_control)(WRITE_VALUE)
    yield (nysa.wait_clocks(100))
    read_value = yield cocotb.external(driver.get_control)()
    yield (nysa.wait_clocks(100))
    dut.log.info("Control Register: 0x%08X" % read_value)




@cocotb.test(skip = True)
def long_write_read(dut):
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
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    nysa.pretty_print_sdb()
    driver = ft_fifo_testerDriver(nysa, nysa.find_device(ft_fifo_testerDriver)[0])
    dut.log.info("Ready")
    memory_urns = nysa.get_memory_devices_as_urns()
    mem_addrs = []
    for m in memory_urns:
        mem_addrs.append(nysa.get_device_address(m))
    dut.log.info("Memory Size: 0x%08X" % nysa.get_total_memory_size())

    #DWORD_SIZE = nysa.get_total_memory_size()
    DWORD_SIZE = 4
    write_data = Array('B')
    for i in range (0, DWORD_SIZE * 4, 4):

        write_data.append((i + 0) % 256)
        write_data.append((i + 1) % 256)
        write_data.append((i + 2) % 256)
        write_data.append((i + 3) % 256)


    #For a demo write a value to the control register (See the ${SDB_NAME}Driver for addresses)
    yield cocotb.external(nysa.write_memory)(0x00, write_data)
    yield (nysa.wait_clocks(100))
    read_data = yield cocotb.external(nysa.read_memory)(0x00, DWORD_SIZE)
    yield (nysa.wait_clocks(100))
    #dut.log.info("Read Data: %s" % list_to_hex_string(read_data))
    fail_count = 0

    if len(write_data) != len(read_data):
        print "Length of read data is not equal to the length of write data: 0x%04X != 0x!04X" % (len(write_data), len(read_data))

    else:
        for i in range(len(write_data)):
            if write_data[i] != read_data[i]:
                if fail_count < 16:
                    print "[0x%04X] %02X != %02X" % (i, write_data[i], read_data[i])
                fail_count += 1


@cocotb.test(skip = True)
def long_write_and_read_with_no_back_preassure(dut):
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
    driver = ft_fifo_testerDriver(nysa, nysa.find_device(ft_fifo_testerDriver)[0])
    dut.log.info("Ready")
    memory_urns = nysa.get_memory_devices_as_urns()
    mem_addrs = []
    for m in memory_urns:
        mem_addrs.append(nysa.get_device_address(m))
    dut.log.info("Memory Size: 0x%08X" % nysa.get_total_memory_size())

    #DWORD_SIZE = nysa.get_total_memory_size()
    DWORD_SIZE = 0x100
    write_data = Array('B')
    for i in range (0, DWORD_SIZE * 4, 4):
        write_data.append((i + 0) % 256)
        write_data.append((i + 1) % 256)
        write_data.append((i + 2) % 256)
        write_data.append((i + 3) % 256)

    #For a demo write a value to the control register (See the ${SDB_NAME}Driver for addresses)
    yield cocotb.external(nysa.write_memory)(0x00, write_data)
    yield (nysa.wait_clocks(100))
    read_data = yield cocotb.external(nysa.read_memory)(0x00, DWORD_SIZE) 
    yield (nysa.wait_clocks(100))
    #dut.log.info("Read Data: %s" % list_to_hex_string(read_data))
    fail_count = 0

    if len(write_data) != len(read_data):
        print "Length of read data is not equal to the length of write data: 0x%04X != 0x!04X" % (len(write_data), len(read_data))

    else:
        for i in range(len(write_data)):
            if write_data[i] != read_data[i]:
                if fail_count < 16:
                    print "[0x%04X] %02X != %02X" % (i, write_data[i], read_data[i])
                fail_count += 1


@cocotb.coroutine
def back_preassure_manager(dut, timeout):
    count = 0
    print "In back preassure manager"
    yield ClockCycles(dut.clk, timeout)
    print "Go High!"
    dut.back_preassure <=  1
    yield ClockCycles(dut.clk, 10)
    print "Go Low"
    dut.back_preassure <=  0
    #while True:
    #    count = count + 1
    #    if count >= timeout:
    #        if bp.value == 0: 
    #            bp  <=  1
    #            #print "BP 1"
    #        else:
    #            bp  <=  0
    #            count   <= 0
    #            #print "BP 0"
    #    #yield ro
    #    yield clk_edge

@cocotb.test(skip = True)
def long_write_read_with_back_preassure(dut):
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
    yield(nysa.reset())
    #cocotb.fork(back_preassure_manager(dut, 10))
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    nysa.pretty_print_sdb()
    driver = ft_fifo_testerDriver(nysa, nysa.find_device(ft_fifo_testerDriver)[0])
    dut.log.info("Ready")
    memory_urns = nysa.get_memory_devices_as_urns()
    mem_addrs = []
    for m in memory_urns:
        mem_addrs.append(nysa.get_device_address(m))
    dut.log.info("Memory Size: 0x%08X" % nysa.get_total_memory_size())

    #DWORD_SIZE = nysa.get_total_memory_size()
    DWORD_SIZE = 0x100
    write_data = Array('B')
    for i in range (0, DWORD_SIZE * 4, 4):
        write_data.append((i + 0) % 256)
        write_data.append((i + 1) % 256)
        write_data.append((i + 2) % 256)
        write_data.append((i + 3) % 256)

    #For a demo write a value to the control register (See the ${SDB_NAME}Driver for addresses)
    yield cocotb.external(nysa.write_memory)(0x00, write_data)
    yield (nysa.wait_clocks(100))
    read_data = yield cocotb.external(nysa.read_memory)(0x00, DWORD_SIZE) 
    yield (nysa.wait_clocks(100))
    #dut.log.info("Read Data: %s" % list_to_hex_string(read_data))
    fail_count = 0

    if len(write_data) != len(read_data):
        print "Length of read data is not equal to the length of write data: 0x%04X != 0x!04X" % (len(write_data), len(read_data))

    else:
        for i in range(len(write_data)):
            if write_data[i] != read_data[i]:
                if fail_count < 16:
                    print "[0x%04X] %02X != %02X" % (i, write_data[i], read_data[i])
                fail_count += 1

@cocotb.test(skip = False)
def master_write_read(dut):
    """
    Description:
        Very Basic Functionality
            Startup Nysa

    Test ID: 4

    Expected Results:
        Write to all registers
    """

    dut.test_id = 4
    print "module path: %s" % MODULE_PATH
    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield (nysa.wait_clocks(10))
    nysa.pretty_print_sdb()

    dut.log.info("Read Master Flags")
    write_flags = yield cocotb.external(nysa.read_master_register)(0x00)
    yield (nysa.wait_clocks(100))
    dut.log.info("Writing flags: 0x%08X" % write_flags)
    write_flags = 0x001
    yield cocotb.external(nysa.write_master_register)(0x00, write_flags)
    yield (nysa.wait_clocks(100))

    write_flags = yield cocotb.external(nysa.read_master_register)(0x00)
    yield (nysa.wait_clocks(100))
    dut.log.info("Writing flags: 0x%08X" % write_flags)
    yield cocotb.external(nysa.write_master_register)(0x00, 0x00)









