# Simple tests for an adder module
import cocotb
import logging
from cocotb.result import TestFailure
from nysa.host.driver.sata_driver import SATADriver
from model.sim_host import NysaSim
from cocotb.clock import Clock
import time
from array import array as Array

SATA_CLK_PERIOD = 16
CLK_PERIOD = 10


def setup_sata(dut):
    cocotb.fork(Clock(dut.sata_clk, SATA_CLK_PERIOD).start())
    dut.u2h_write_enable = 0
    dut.u2h_write_count = 2048
    dut.h2u_read_enable = 0

@cocotb.coroutine
def wait_for_sata_ready(nysa, dut):

    while not dut.hd_ready.value.get_value():
        yield(nysa.wait_clocks(1))

    dut.log.info("SATA Stack Ready")
    yield(nysa.wait_clocks(100))

def enable_hd_read(nysa, dut):
    dut.u2h_read_enable = 1

@cocotb.coroutine
def enable_hd_write(nysa, dut, count):
    dut.d2h_write_count = count
    dut.u2h_write_enable = True

@cocotb.coroutine
def enable_sata_hold(nysa, dut, enable):
    dut.hold = enable

@cocotb.test(skip = True)
def first_test(dut):
    """
    Description:
        Very Basic Functionality
            Startup Nysa
            Startup Sata Stack

    Test ID: 0

    Expected Results:
        Write to all registers
    """

    dut.test_id = 0
    nysa = NysaSim(dut, CLK_PERIOD)
    setup_sata(dut)

    yield(nysa.reset())
    nysa.read_sdb()
    nysa.pretty_print_sdb()

    #Get the driver
    sata = SATADriver(nysa, nysa.find_device(SATADriver)[0])

    #Reset the hard drive
    yield cocotb.external(sata.enable_sata_reset)(False)
    #Wait for SATA to Startup
    yield(wait_for_sata_ready)(nysa, dut)

    dut.log.info("SATA Opened!")
    dut.log.info("Ready")


@cocotb.test(skip = False)
def write_test(dut):
    """
    Description:
        Very Basic Functionality
            Startup Nysa
            Startup Sata Stack

    Test ID: 1

    Expected Results:
        Write to all registers
    """

    dut.test_id = 1
    nysa = NysaSim(dut, CLK_PERIOD)
    setup_sata(dut)

    yield(nysa.reset())
    nysa.read_sdb()
    nysa.pretty_print_sdb()
    enable_hd_read(nysa, dut)

    #Get the driver
    sata = SATADriver(nysa, nysa.find_device(SATADriver)[0])

    #Reset the hard drive
    yield cocotb.external(sata.enable_sata_reset)(False)
    #Wait for SATA to Startup
    yield(wait_for_sata_ready)(nysa, dut)
    values = Array('B')
    clear_values = Array('B')
    #for i in range (0, 2048 * 4):
    for i in range (0, 2048):
        v = Array('B', [(i >> 24) & 0xFF, (i >> 16) & 0xFF, (i >> 8) & 0xFF, i & 0xFF])
        #values.append(i % 256)
        values.extend(v)
        clear_values.append(0)
        clear_values.extend(Array('B', [0, 0, 0, 0]))

    #yield cocotb.external(sata.set_local_buffer_write_size)(100)
    yield cocotb.external(sata.write_local_buffer)(values)
    yield cocotb.external(sata.load_local_buffer)()


    dut.log.info("SATA Opened!")
    dut.log.info("Ready")
    dut.u2h_write_enable = 1
    dut.u2h_write_count = 2048
    yield cocotb.external(sata.hard_drive_write)(0x01000, 1)
    yield(nysa.wait_clocks(10000))
    dut.u2h_write_enable = 0


@cocotb.test(skip = True)
def read_test(dut):
    """
    Description:
        Very Basic Functionality
            Startup Nysa
            Startup Sata Stack

    Test ID: 1

    Expected Results:
        Write to all registers
    """

    dut.test_id = 2
    nysa = NysaSim(dut, CLK_PERIOD)
    setup_sata(dut)

    yield(nysa.reset())
    nysa.read_sdb()
    nysa.pretty_print_sdb()
    enable_hd_read(nysa, dut)

    #Get the driver
    sata = SATADriver(nysa, nysa.find_device(SATADriver)[0])

    #Reset the hard drive
    yield cocotb.external(sata.enable_sata_reset)(False)
    #Wait for SATA to Startup
    yield(wait_for_sata_ready)(nysa, dut)
    values = Array('B')
    clear_values = Array('B')

    dut.h2u_read_enable = 1
    yield(nysa.wait_clocks(3000))
    yield cocotb.external(sata.hard_drive_read)(0x01000, 1)
    yield(nysa.wait_clocks(7000))
    data = yield(cocotb.external(sata.read_local_buffer))()
    dut.h2u_read_enable = 0


