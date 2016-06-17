import cocotb
from cocotb.triggers import RisingEdge, ReadOnly, Lock
from cocotb.drivers import BusDriver
from cocotb.result import ReturnValue
from cocotb.binary import BinaryValue

import binascii
from array import array as Array

def create_32bit_word(data_array, index):
    return (data_array[index] << 24) | (data_array[index + 1] << 16) | (data_array[index + 2] << 8) | (data_array[index + 3])

class UART(object):

    def __init__(self, entry, name, clock):
        self.uw = UARTCommWriter(entry, name, clock)
        self.ur = UARTCommReader(entry, name, clock)
        self.data = Array('B')

    @cocotb.coroutine
    def write(self, data):
        yield self.uw.write(data)

    @cocotb.coroutine
    def read(self, size):
        self.data = Array('B')
        yield self.ur.read(size)
        self.data = self.ur.get_data()

    def get_data(self):
        return self.data

    def set_baudrate(self):
        pass
    

class UARTCommWriter(BusDriver):

    _signals = ["wr_stb", "wr_data", "wr_busy"]

    def __init__(self, entity, name, clock):
        BusDriver.__init__(self, entity, name, clock)
        self.bus.wr_stb     <=  0
        self.bus.wr_data    <=  0
        self.write_data_busy = Lock("%s_wbusy" % name)


    @cocotb.coroutine
    def write(self, data):
        yield self.write_data_busy.acquire()
        i = 0
        while i < len(data):
            yield ReadOnly()
            yield RisingEdge(self.clock)
            if not (self.bus.wr_busy.value):
                if i == len(data):
                    break
                self.bus.wr_data    <=  data[i]
                self.bus.wr_stb     <=  1
                i = i + 1

            yield RisingEdge(self.clock)
            self.bus.wr_stb     <=  0

        self.write_data_busy.release()
        

class UARTCommReader(BusDriver):

    _signals = ["rd_data", "rd_stb"]

    def __init__(self, entity, name, clock):
        BusDriver.__init__(self, entity, name, clock)
        self.read_data_busy = Lock("%s_wbusy" % name)
        self.data = Array('B')

    @cocotb.coroutine
    def read(self, size):
        yield self.read_data_busy.acquire()
        self.data = Array('B')
        count = 0
        while count < size:
            yield ReadOnly()
            yield RisingEdge(self.clock)
            if self.bus.rd_stb.value == 1:
                self.data.append(self.bus.rd_data.value)
                count += 1

        yield RisingEdge(self.clock)
        self.read_data_busy.release()

    def get_data(self):
        return self.data
