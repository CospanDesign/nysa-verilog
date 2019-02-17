
import cocotb
from cocotb.triggers import RisingEdge, ReadOnly, Lock
from cocotb.drivers import BusDriver
from cocotb.result import ReturnValue
from cocotb.binary import BinaryValue
from cocotb.clock import Clock

import binascii
import array

class BRAMWriteController (BusDriver):
    _signals = ["DATA", "ADDR", "WEA"]

    def __init__(self, entity, name, clock, mem_size, clock_period = 10):
        BusDriver.__init__(self, entity, name, clock)
        self.mem_size = mem_size
        self.bus.DATA.setimmediatevalue(0)
        self.bus.ADDR.setimmediatevalue(0)
        self.bus.WEA.setimmediatevalue(0)
        self.busy_lock = Lock("%s_wabusy" % name)
        cocotb.fork(Clock(self.clock, clock_period).start())

    def write(self, data):
        yield self.busy_lock.acquire()
        yield RisingEdge(self.clock)
        self.busy_lock.release()


class BRAMReadController (BusDriver):
    _signals = ["DATA", "ADDR"]

    def __init__(self, entity, name, clock, mem_size, clock_period = 10):
        BusDriver.__init__(self, entity, name, clock)
        self.mem_size = mem_size
        self.bus.DATA.setimmediatevalue(0)
        self.bus.ADDR.setimmediatevalue(0)
        self.busy_lock = Lock("%s_wabusy" % name)
        cocotb.fork(Clock(self.clock, clock_period).start())

    @cocotb.coroutine
    def read(self, size=None):
        yield self.busy_lock.acquire()
        yield RisingEdge(self.clock)
        self.busy_lock.release()


