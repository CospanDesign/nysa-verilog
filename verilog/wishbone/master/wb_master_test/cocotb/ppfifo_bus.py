import logging
import cocotb
from cocotb.triggers import RisingEdge
from cocotb.triggers import ReadOnly
from cocotb.triggers import Lock
from cocotb.drivers import BusDriver
from cocotb.binary import BinaryValue
from cocotb import log

from array import array as Array

def create_32bit_word(data_array, index):
    return (data_array[index] << 24) | (data_array[index + 1] << 16) | (data_array[index + 2] << 8) | (data_array[index + 3])

def create_byte_array_from_dword(dword):
    d = Array('B')
    d.append((dword >> 24) & 0xFF)
    d.append((dword >> 16) & 0xFF)
    d.append((dword >>  8) & 0xFF)
    d.append((dword >>  0) & 0xFF)
    return d

class PPFIFOIngress(BusDriver):

    _signals = ["rdy", "act", "stb", "data", "size"]

    def __init__(self, entity, name, clock, debug = False):
        BusDriver.__init__(self, entity, name, clock)
        if debug:
            self.log.setLevel(logging.DEBUG)
        self.bus.act    <=  0
        self.bus.stb    <=  0
        self.bus.data   <=  0

    @cocotb.coroutine
    def write(self, data):
        fifo_pos = 0
        length = len(data) / 4
        data_pos = 0

        while data_pos < length:
            if (self.bus.rdy.value > 0) and (self.bus.act.value == 0):
                fifo_pos            =   0
                v = int(self.bus.rdy.value)
                #log.info("Ready Value: 0x%02X" % v)
                if (v & 0x01) > 0:
                    self.bus.act    <=  0x01
                else:
                    self.bus.act    <=  0x02

            elif self.bus.act.value:
                #log.info("Bus Pos: %d, data pos %d, Length: %d" % (fifo_pos, data_pos, length))
                if fifo_pos   < self.bus.size.value:
                    self.bus.data   <=  create_32bit_word(data, data_pos * 4)
                    self.bus.stb    <=  1
                    fifo_pos        +=  1
                    data_pos        +=  1
                else:
                    self.bus.act    <=  0

            yield RisingEdge(self.clock)
            self.bus.stb            <=  0

        yield RisingEdge(self.clock)
        self.bus.act                <=  0

class PPFIFOEgress(BusDriver):
    _signals = ["rdy", "act", "stb", "data", "size"]

    def __init__(self, entity, name, clock, debug = False):
        BusDriver.__init__(self, entity, name, clock)
        if debug:
            self.log.setLevel(logging.DEBUG)
        self.bus.act    <=  0
        self.bus.stb    <=  0
        self.data       =  Array('B')

    def get_data(self):
        return self.data

    @cocotb.coroutine
    def read(self, byte_length):
        fifo_pos = 0
        data_pos = 0
        length = byte_length / 4
        self.data = Array('B')

        while data_pos < length:
            self.bus.stb            <=  0
            if self.bus.stb.value:
                self.data.extend(create_byte_array_from_dword(self.bus.data.value))
                fifo_pos        +=  1
                data_pos        +=  1

            if self.bus.rdy.value and not self.bus.act.value:
                fifo_pos            =  0
                self.bus.act        <=  1

            elif self.bus.act.value:
                if fifo_pos < self.bus.size.value:
                    self.bus.stb    <=  1
                else:
                    self.bus.act    <=  0

            yield RisingEdge(self.clock)

        yield RisingEdge(self.clock)

