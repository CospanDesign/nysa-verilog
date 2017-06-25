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
    _signals = ["HSYNC", "SOF_STB", "RED", "GREEN", "BLUE"]

    def __init__(self, entity, name, clock, width = 100, height = 100, y_fp = 10, y_bp = 10, x_fp = 10, x_bp = 10):
        BusDriver.__init__(self, entity, name, clock)
        self.width = width
        self.height = height
        self.y_fp = y_fp
        self.y_bp = y_bp
        self.x_fp = x_fp
        self.x_bp = x_bp
        self.bus.SOF_STB.setimmediatevalue(0)
        self.bus.HSYNC.setimmediatevalue(0)
        self.bus.RED.setimmediatevalue(0)
        self.bus.BLUE.setimmediatevalue(0)
        self.bus.GREEN.setimmediatevalue(0)
        self.busy = Lock("%s_busy" % name)

    @cocotb.coroutine
    def write(self, data = None):

        if data is None:
            #Generate a test image
            data = [[0] * width] * height
            for y in range(height):
                for x in range(width):
                    data[y][x] = i % 256

        yield self.busy.acquire()

        yield RisingEdge(self.clock)
        '''
        self.bus.SOF_STB <= 1
        yield RisingEdge(self.clock)
        self.bus.SOF_STB <= 0
        '''

        #Perform Y Front Porch Delay
        for i in range (self.y_fp):
           yield RisingEdge(self.clock)
           yield ReadOnly()

        for y in range(self.height):
            #Perform X Front Porch Delay
            for i in range (self.x_fp):
                yield RisingEdge(self.clock)
                yield ReadOnly()

            yield RisingEdge(self.clock)
            self.bus.SOF_STB    <=  1
            yield RisingEdge(self.clock)
            self.bus.SOF_STB    <=  0

            for x in range(self.width):
                yield RisingEdge()
                self.busy.HSYNC <=  1
                self.bus.RED    <=  (data[y][x] >> 5) & 0x5
                self.bus.GREEN  <=  (data[y][x] >> 2) & 0x5
                self.bus.BLUE   <=  (data[y][x] >> 0) & 0x3

            yield RisingEdge()
            self.busy.HSYNC <=  0


            #Perform X Back Porch Delay
            for i in range (self.x_bp):
                yield RisingEdge(self.clock)
                yield ReadOnly()

        #Perform Y Back Porch Delay
        for i in range (self.y_bp):
           yield RisingEdge(self.clock)
           yield ReadOnly()

