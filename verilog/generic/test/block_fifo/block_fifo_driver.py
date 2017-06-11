import cocotb
from cocotb.triggers import RisingEdge, ReadOnly, Lock
from cocotb.drivers import BusDriver
from cocotb.result import ReturnValue
from cocotb.binary import BinaryValue

import binascii
import array

class BlockError(Exception):
    pass

class BlockFIFOWritePath(BusDriver):
    _signals = ["RDY", "ACT", "STB", "SIZE", "DATA"]
    _optional_signals = ["STARVED"]

    def __init__(self, entity, name, clock):
        BusDriver.__init__(self, entity, name, clock)
        self.bus.ACT.setimmediatevalue(0)
        self.bus.DATA.setimmediatevalue(0)
        self.bus.STB.setimmediatevalue(0)
        self.busy = Lock("%s_busy" % name)

    @cocotb.coroutine
    def write(self, data):
        yield self.busy.acquire()
        pos = 0
        count = 0
        total_length = len(data)
        rdy = 0

        while pos < total_length:
            while True:
                yield ReadOnly()
                rdy = int(self.bus.RDY)
                if rdy != 0:
                    yield RisingEdge(self.clock)
                    self.bus.ACT    <=  1
                    break
                yield RisingEdge(self.clock)

            yield RisingEdge(self.clock)
            length  = total_length - pos
            if length > int(self.bus.SIZE):
                length = int(self.bus.SIZE)

            print "Length: %d" % length
            print "pos: %d" % pos

            for d in data[pos:(pos + length)]:
                self.bus.STB    <=  1
                self.bus.DATA   <=  d
                yield RisingEdge(self.clock)

            self.bus.STB        <=  0
            pos += length
            yield RisingEdge(self.clock)
            self.bus.ACT        <=  0
            yield RisingEdge(self.clock)

        self.busy.release()

class BlockFIFOReadPath(BusDriver):
    _signals = ["RDY", "ACT", "STB", "SIZE", "DATA"]
    _optional_signals = ["INACTIVE"]

    def __init__(self, entity, name, clock):
        BusDriver.__init__(self, entity, name, clock)
        self.bus.ACT.setimmediatevalue(0)
        self.bus.STB.setimmediatevalue(0)
        self.busy = Lock("%s_busy" % name)

    @cocotb.coroutine
    def read(self, size=None):
        """
        If set to None just keep reading
        """
        fifo_size = 0
        data = []
        yield self.busy.acquire()
        pos = 0
        while (size is None) or (pos < size):
            print "Within read loop: Pos: %d" % pos
            yield ReadOnly()
            #while True:
            while self.bus.ACT == 0:
                if self.bus.RDY == 1:
                    yield RisingEdge(self.clock)
                    self.bus.ACT    <=  1
                yield RisingEdge(self.clock)
                yield ReadOnly()

            print "Got act!"
            yield RisingEdge(self.clock)
            count = 0
            yield ReadOnly()
            fifo_size = int(self.bus.SIZE)
            #print "FIFO Size: %d" % fifo_size
            while count < fifo_size:
                #print "Count: %d" % count
                yield RisingEdge(self.clock)
                self.bus.STB    <=  1
                yield ReadOnly()
                if size is not None:
                    d = int(self.bus.DATA)
                    #print "Data: %08X" % d
                    data.append(d)
                count   += 1
                pos     += 1
            yield RisingEdge(self.clock)
            self.bus.STB    <=  0
            self.bus.ACT    <=  0
            yield RisingEdge(self.clock)

        self.busy.release()

        raise ReturnValue(data)
