
import cocotb
from cocotb.triggers import RisingEdge, ReadOnly, Lock, NextTimeStep
from cocotb.drivers import BusDriver
from cocotb.result import ReturnValue
from cocotb.binary import BinaryValue
from cocotb.clock import Clock

import binascii
import array

class CommandMaster (BusDriver):
    _signals = ["EN", "ERROR", "ACK", "STATUS", "INTERRUPT",
                "ADR", "WR_RD", "BYTE_EN",
                "DATA_COUNT", "WR_DATA", "RD_DATA"]

    def __init__(self,
                 entity,
                 name,
                 clock):
        BusDriver.__init__(self, entity, name, clock)
        self.bus.EN.setimmediatevalue(0)
        self.bus.ADR.setimmediatevalue(0)
        self.bus.WR_RD.setimmediatevalue(0)
        self.bus.BYTE_EN.setimmediatevalue(0)
        self.bus.DATA_COUNT.setimmediatevalue(0)
        self.bus.WR_DATA.setimmediatevalue(0)

        # Mutex for each channel that we master to prevent contention
        self.rd_busy = Lock("%s_wbusy" % name)
        self.wr_busy = Lock("%s_rbusy" % name)

    @cocotb.coroutine
    def write(self, address, data, byte_en = 0xF):
        assert not isinstance(data, int), "Data should be a list"
        yield self.wr_busy.acquire()
        yield RisingEdge(self.clock)
        self.bus.WR_RD      <=  1
        self.bus.EN         <=  1
        self.bus.ADR        <=  address
        self.bus.DATA_COUNT <=  1
        if (data is int):
            self.bus.WR_DATA    <=  data
        else:
            self.bus.WR_DATA    <=  data[0]
        self.bus.BYTE_EN    <=  byte_en

        yield RisingEdge(self.clock)

#        yield ReadOnly()
#        rdy = int(self.bus.ACK)
#
#        while (rdy == 0):
#            yield RisingEdge(self.clock)
#            yield ReadOnly()
#            rdy = int(self.bus.ACK)
#
#        yield RisingEdge(self.clock)
#        self.bus.EN         <=  0
        self.wr_busy.release()

    @cocotb.coroutine
    def read(self, address, count = 1):
        data = []
        yield self.rd_busy.acquire()
        self.bus.ADR        <= address
        self.bus.EN         <= 1
        self.bus.DATA_COUNT <= 1
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

        data.append(self.bus.RD_DATA)
        raise ReturnValue(data)

    @cocotb.coroutine
    def get_read_status(self):
        #print ("Status: %s" % str(self.bus.STATUS))
        yield RisingEdge(self.clock)
        command_status = (int(self.bus.STATUS) >> 8) & 0x03
        raise ReturnValue(command_status)

