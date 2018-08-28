
import cocotb
from cocotb.triggers import RisingEdge, ReadOnly, Lock
from cocotb.drivers import BusDriver
from cocotb.result import ReturnValue
from cocotb.binary import BinaryValue
from cocotb.clock import Clock

import binascii
import array

from ppfifo_driver import PPFIFOWritePath
from ppfifo_driver import PPFIFOReadPath

class CommandMaster (BusDriver):
    _signals = ["EN", "ERROR", "ACK", "STATUS", "INTERRUPT",
                "ADR", "ADR_FIXED", "ADR_WRAP",
                "WR_RD", "COUNT"]

    def __init__(self,
                 entity,
                 name,
                 clock,
                 wr_fifo_name = "WR",
                 wr_fifo_clk = None,
                 wr_fifo_clk_period = 10,
                 rd_fifo_name = "RD",
                 rd_fifo_clk = None,
                 rd_fifo_clk_period = 10):
        BusDriver.__init__(self, entity, name, clock)
        if wr_fifo_clk is None:
            wr_fifo_clk = entity.WR_CLK
        if rd_fifo_clk is None:
            rd_fifo_clk = entity.RD_CLK

        self.bus.EN.setimmediatevalue(0)
        self.bus.ADR.setimmediatevalue(0)
        self.bus.ADR_FIXED.setimmediatevalue(0)
        self.bus.ADR_WRAP.setimmediatevalue(0)
        self.bus.WR_RD.setimmediatevalue(0)
        self.bus.COUNT.setimmediatevalue(0)

        # Mutex for each channel that we master to prevent contention
        self.command_busy = Lock("%s_wabusy" % name)
        cocotb.fork(Clock(wr_fifo_clk, wr_fifo_clk_period).start())
        cocotb.fork(Clock(rd_fifo_clk, rd_fifo_clk_period).start())

        self.write_fifo = PPFIFOWritePath(entity, wr_fifo_name, wr_fifo_clk)
        self.read_fifo = PPFIFOReadPath(entity, rd_fifo_name, rd_fifo_clk)

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

        yield self.write_fifo.write(data)

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



