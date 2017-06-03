
import cocotb
from cocotb.triggers import RisingEdge, ReadOnly, Lock
from cocotb.drivers import BusDriver
from cocotb.result import ReturnValue
from cocotb.binary import BinaryValue
from cocotb.clock import Clock

import binascii
import array

class CommandMaster (BusDriver):
    _signals = ["EN", "ERROR", "ACK", "STATUS", "INTERRUPT",
                "ADR", "WR_RD", "BYTE_EN",
                "WR_DATA", "RD_DATA"]

    def __init__(self,
                 entity,
                 name,
                 clock):
        BusDriver.__init__(self, entity, name, clock)
        self.bus.EN.setimmediatevalue(0)
        self.bus.ADR.setimmediatevalue(0)
        self.bus.WR_RD.setimmediatevalue(0)
        self.bus.BYTE_EN.setimmediatevalue(0)
        self.bus.WR_DATA.setimmediatevalue(0)

        # Mutex for each channel that we master to prevent contention
        self.rd_busy = Lock("%s_wbusy" % name)
        self.wr_busy = Lock("%s_rbusy" % name)

    @cocotb.coroutine
    def write(self, address, data, byte_en = 0xF):
        yield self.wr_busy.acquire()
        yield RisingEdge(self.clock)
        self.bus.ADR        <= address
        self.bus.WR_RD      <=  1
        self.bus.EN         <=  1
        self.bus.ADR        <=  address
        self.bus.WR_DATA    <=  data
        self.bus.BYTE_EN    <=  byte_en

        yield RisingEdge(self.clock)

        yield ReadOnly()
        rdy = int(self.bus.ACK)

        while (rdy == 0):
            yield RisingEdge(self.clock)
            yield ReadOnly()
            rdy = int(self.bus.ACK)

        yield RisingEdge(self.clock)
        self.bus.EN         <=  0
        self.wr_busy.release()

    @cocotb.coroutine
    def read(self, address):
        data = []
        yield self.rd_busy.acquire()
        self.bus.ADR        <= address
        self.bus.EN         <= 1
        self.bus.WR_RD      <= 0
        self.bus.BYTE_EN    <= 0
        yield RisingEdge(self.clock)

        yield ReadOnly()
        rdy = int(self.bus.ACK)

        while (rdy == 0):
            yield RisingEdge(self.clock)
            yield ReadOnly()
            rdy = int(self.bus.ACK)

        yield RisingEdge(self.clock)
        self.bus.EN         <=  0



