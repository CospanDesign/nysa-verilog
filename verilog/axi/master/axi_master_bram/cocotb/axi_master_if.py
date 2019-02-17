
import cocotb
from cocotb.triggers import RisingEdge, ReadOnly, Lock
from cocotb.drivers import BusDriver
from cocotb.result import ReturnValue
from cocotb.binary import BinaryValue
from cocotb.clock import Clock

import binascii
import array

from bram_controller import BRAMWriteController
from bram_controller import BRAMReadController

MEM_SIZE = 1024

class CommandMaster (BusDriver):
    _signals = ["EN", "ERROR", "ACK", "STATUS", "INTERRUPTS",
                "ADR", "ADR_FIXED", "ADR_WRAP",
                "WR_RD", "COUNT"]

    def __init__(self, entity, name, clock):
        BusDriver.__init__(self, entity, name, clock)

        self.bus.EN.setimmediatevalue(0)
        self.bus.ADR.setimmediatevalue(0)
        self.bus.ADR_FIXED.setimmediatevalue(0)
        self.bus.ADR_WRAP.setimmediatevalue(0)
        self.bus.WR_RD.setimmediatevalue(0)
        self.bus.COUNT.setimmediatevalue(0)

        self.command_busy = Lock("%s_wabusy" % name)
        self.write_mem = BRAMWriteController(entity, "BRAM_INGRESS", entity.BRAM_INGRESS_CLK, MEM_SIZE, clock_period = 10)
        self.read_mem =  BRAMReadController( entity, "BRAM_EGRESS",  entity.BRAM_EGRESS_CLK,  MEM_SIZE, clock_period = 10)

    @cocotb.coroutine
    def write(self, address, data):
        count = 0
        yield self.command_busy.acquire()
        yield RisingEdge(self.clock)
        self.bus.ADR    <= address
        self.bus.COUNT  <=  len(data)
        self.bus.WR_RD  <=  1
        self.bus.EN     <=  1
        yield RisingEdge(self.clock)
        print "Length of data: %d" % len(data)

        #yield self.write_fifo.write(data)

        yield RisingEdge(self.clock)
        self.bus.EN     <=  0
        self.command_busy.release()

    @cocotb.coroutine
    def read(self, address, size, sync=True):
        count = 0
        data = []
        yield self.command_busy.acquire()
        self.bus.ADR <= address
        self.bus.COUNT  <=  size
        self.bus.EN <= 1
        yield RisingEdge(self.clock)

        yield RisingEdge(self.clock)
        self.bus.EN <=  0

        yield ReadOnly()
        self.command_busy.release()



