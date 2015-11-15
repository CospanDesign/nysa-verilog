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
from dut_driver import wb_hs_demoDriver
import nysa.host.driver.dma as dmam
from nysa.host.driver.dma import DMA

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
    driver = wb_hs_demoDriver(nysa, nysa.find_device(wb_hs_demoDriver)[0])
    dut.log.info("Ready")

@cocotb.test(skip = True)
def simple_read_write_bram(dut):
    """
    Description:
        Read and write data to the block ram

    Test ID: 1

    Expected Results:
        Write Data the Block RAM through Wishbone interface
        Read Same data from the block RAM through wishbone interface
    """
    dut.test_id = 1
    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield(nysa.wait_clocks(10))
    driver = wb_hs_demoDriver(nysa, nysa.find_device(wb_hs_demoDriver)[0])
    yield cocotb.external(driver.write_data)(0x00, [0x00, 0x01, 0x02, 0x03])
    yield (nysa.wait_clocks(100))
    v = yield cocotb.external(driver.read_data)(0x00, 1)
    dut.log.info("V: %s" % v)
    dut.log.info("Ready")

@cocotb.test(skip = True)
def stream_read_write_bram(dut):
    """
    Description:
        Read and write data to the block ram

    Test ID: 2

    Expected Results:
        Write Data the Block RAM through Wishbone interface
        Read Same data from the block RAM through wishbone interface
    """
    dut.test_id = 2
    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield(nysa.wait_clocks(10))
    driver = wb_hs_demoDriver(nysa, nysa.find_device(wb_hs_demoDriver)[0])
    data = Array('B')
    SIZE =1024
    for i in range(SIZE):
        data.append(i % 256)

    yield cocotb.external(driver.write_data)(0x00, data)
    yield (nysa.wait_clocks(100))
    v = yield cocotb.external(driver.read_data)(0x00, (SIZE / 4))

    if len(v) != len(data):
        raise cocotb.result.TestFailure("Test %d: Length of incomming data and outgoing data is equal %d = %d" % (dut.test_id, len(v), len(data)))

    for i in range(len(data)):
        if v[i] != data[i]:
            raise cocotb.result.TestFailure("Test %d: Address 0x%02X 0x%02X != 0x%02X" % (dut.test_id, i, v[i], data[i]))

    dut.log.info("Success")



@cocotb.test(skip = False)
def test_dma_simple_transfer(dut):
    """
    Description:
        Simple DMA Transfer

    Test ID: 3

    Expected Results:
    """
    dut.test_id = 3
    nysa = NysaSim(dut, SIM_CONFIG, CLK_PERIOD, user_paths = [MODULE_PATH])
    setup_dut(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield(nysa.wait_clocks(10))
    driver = wb_hs_demoDriver(nysa, nysa.find_device(wb_hs_demoDriver)[0])
    dma = DMA(nysa, nysa.find_device(DMA)[0])
    yield cocotb.external(dma.setup)()
    yield cocotb.external(dma.enable_dma)(True)
    yield(nysa.wait_clocks(10))

    count = yield cocotb.external(dma.get_channel_count)()
    dut.log.info("DMA Channel Count: %d" % count)

    #WORD_COUNT = 0x880
    #WORD_COUNT = 0x1000
    #WORD_COUNT = 0x0800
    #WORD_COUNT = 0x400
    WORD_COUNT = 0x400
    #WORD_COUNT = 0x800000
    CHANNEL_ADDR = 1
    SINK_ADDR = 3
    INST_ADDR = 7

    SOURCE_ADDRESS  = 0x0000000000000000
    DEST_ADDRESS    = 0x0000000000000000


    yield cocotb.external(dma.set_channel_sink_addr)            (CHANNEL_ADDR,  SINK_ADDR           )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.set_channel_instruction_pointer)  (CHANNEL_ADDR,  INST_ADDR           )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.enable_source_address_increment)  (CHANNEL_ADDR,  True                )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.enable_dest_address_increment)    (SINK_ADDR,     True                )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.enable_dest_respect_quantum)      (SINK_ADDR,     False              )
    #yield cocotb.external(dma.enable_dest_respect_quantum)      (SINK_ADDR,     True                )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.set_instruction_source_address)   (INST_ADDR,     SOURCE_ADDRESS      )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.set_instruction_dest_address)     (INST_ADDR,     DEST_ADDRESS        )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.set_instruction_data_count)       (INST_ADDR,     WORD_COUNT          )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.set_channel_instruction_pointer)  (CHANNEL_ADDR,  INST_ADDR           )
    yield nysa.wait_clocks(10)
    #Start
    yield cocotb.external(dma.enable_channel)                   (CHANNEL_ADDR,  True                )

    yield nysa.wait_clocks(10000)
    yield cocotb.external(dma.enable_channel)                   (CHANNEL_ADDR,  False               )
    yield cocotb.external(dma.enable_dma)(False)
    yield nysa.wait_clocks(10)



    WORD_COUNT = 0x400
    CHANNEL_ADDR = 3
    SINK_ADDR = 0
    INST_ADDR = 0

    SOURCE_ADDRESS  = 0x0000000000000000
    DEST_ADDRESS    = 0x0000000000000000

    yield cocotb.external(dma.set_channel_sink_addr)            (CHANNEL_ADDR,  SINK_ADDR           )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.set_channel_instruction_pointer)  (CHANNEL_ADDR,  INST_ADDR           )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.enable_source_address_increment)  (CHANNEL_ADDR,  True                )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.enable_dest_address_increment)    (SINK_ADDR,     True                )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.enable_dest_respect_quantum)      (SINK_ADDR,     False              )
    #yield cocotb.external(dma.enable_dest_respect_quantum)      (SINK_ADDR,     True                )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.set_instruction_source_address)   (INST_ADDR,     SOURCE_ADDRESS      )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.set_instruction_dest_address)     (INST_ADDR,     DEST_ADDRESS        )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.set_instruction_data_count)       (INST_ADDR,     WORD_COUNT          )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.set_channel_instruction_pointer)  (CHANNEL_ADDR,  INST_ADDR           )
    yield nysa.wait_clocks(10)
    #Start
    yield cocotb.external(dma.enable_channel)                   (CHANNEL_ADDR,  True                )

    yield nysa.wait_clocks(10000)
    yield cocotb.external(dma.enable_channel)                   (CHANNEL_ADDR,  False               )
    yield cocotb.external(dma.enable_dma)(False)
    yield nysa.wait_clocks(10)


    '''
    data = Array('B')
    SIZE =1024
    for i in range(SIZE):
        data.append(i % 256)

    yield cocotb.external(driver.write_data)(0x00, data)
    yield (nysa.wait_clocks(100))
    v = yield cocotb.external(driver.read_data)(0x00, (SIZE / 4))

    if len(v) != len(data):
        raise cocotb.result.TestFailure("Test %d: Length of incomming data and outgoing data is equal %d = %d" % (dut.test_id, len(v), len(data)))

    for i in range(len(data)):
        if v[i] != data[i]:
            raise cocotb.result.TestFailure("Test %d: Address 0x%02X 0x%02X != 0x%02X" % (dut.test_id, i, v[i], data[i]))

    '''
    dut.log.info("Success")

