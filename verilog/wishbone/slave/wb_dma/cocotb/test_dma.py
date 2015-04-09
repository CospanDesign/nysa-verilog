# Simple tests for an adder module
import cocotb
from cocotb.result import TestFailure
from model.dma import DMA

CLK_PERIOD = 4

@cocotb.test(skip = False)
def first_test(dut):
    """
    Description:
        Initial Test

    Test ID: 0

    Expected Results:
        The SATA stack should be ready and in the IDLE state
    """
    dut.test_id = 0
    sata = SataController(dut, CLK_PERIOD)
    yield(sata.reset())

    #yield(sata.wait_for_idle()0))
    yield(sata.wait_for_idle())
    if not sata.ready():
        dut.log.error("Sata Is not ready")
        TestFailure()
    else:
        dut.log.info("Sata is Ready")


