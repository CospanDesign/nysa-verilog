# Simple tests for an adder module
import cocotb
from cocotb.result import TestFailure
from model.dma import DMA
from model.sim_host import NysaSim
import time

CLK_PERIOD = 4

@cocotb.test(skip = False)
def first_test(dut):
    """
    Description:
        Initial Test

    Test ID: 0

    Expected Results:
        Write to all registers
    """

    dut.test_id = 0
    nysa = NysaSim(dut)
    yield(nysa.reset())
    nysa.read_sdb()

    #nysa.pretty_print_sdb()
    #dma = DMA(nysa, nysa.find_device(DMA)[0])
    dma = DMA(nysa, nysa.find_device(DMA)[0])
    yield cocotb.external(dma.setup)()
    print "Try a read"
    yield cocotb.external(dma.get_channel_count)()

    dut.log.info("DMA Opened!")
    dut.log.info("Ready")


def test_func(f, args, response):
    if f(args) != response:
        print "FAIL!"
        return False
    return True

@cocotb.test(skip = False)
def test_setup_dma(dut):
    """
    Description:
        Setup a channel

    Test ID: 1

    Expected Results:
        Write to all registers
    """

    dut.test_id = 1
    nysa = NysaSim(dut)
    yield(nysa.reset())
    nysa.read_sdb()

    dma = DMA(nysa, nysa.find_device(DMA)[0])
    yield cocotb.external(dma.setup)()
    yield cocotb.external(dma.enable_dma)(True)
    #yield nysa.wait_clocks(10)

    SINK_ADDR = 2
    INST_ADDR = 7
    for i in range (0, dma.channel_count):
        #print "w"
        yield cocotb.external(dma.set_channel_sink_addr)(i, SINK_ADDR)
        r = yield cocotb.external(dma.get_channel_sink_addr)(i)
        if SINK_ADDR != r:
            raise cocotb.result.TestFailure("Channel [%d] Sink Addr should be [%d] but is [%d]" % (i, SINK_ADDR, r))

        yield cocotb.external(dma.set_channel_instruction_pointer)(i, INST_ADDR)
        r = yield cocotb.external(dma.get_channel_instruction_pointer)(i)
        if INST_ADDR != r:
            raise cocotb.result.TestFailure("Channel [%d] Insruction Addr should be [%d] but is [%d]" % (i, INST_ADDR, r))

        print "hi"

        yield cocotb.external(dma.enable_source_address_increment)(i, True)
        r = yield cocotb.external(dma.is_source_address_increment)(i)
        if r != True:
            raise cocotb.result.TestFailure("Channel [%d] source Addr should be [%d] but is [%d]" % (i, INST_ADDR, r))

        yield cocotb.external(dma.enable_source_address_increment)(i, False)
        r = yield cocotb.external(dma.is_source_address_increment)(i)
        if r != False:
            raise cocotb.result.TestFailure("Channel [%d] source Addr should be [%d] but is [%d]" % (i, INST_ADDR, r))



        yield cocotb.external(dma.enable_channel)(i, True)
        yield cocotb.external(test_func)(dma.is_channel_enable, i, True)

        yield cocotb.external(dma.enable_channel)(i, False)
        yield cocotb.external(test_func)(dma.is_channel_enable, i, False)



    r = nysa.response
    #print "response: %s" % str(r)


    yield nysa.wait_clocks(10)

