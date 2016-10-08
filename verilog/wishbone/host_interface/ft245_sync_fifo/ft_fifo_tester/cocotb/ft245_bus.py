import logging
import cocotb
from cocotb.triggers import FallingEdge
from cocotb.triggers import ClockCycles
from cocotb.triggers import RisingEdge
from cocotb.triggers import ReadOnly
from cocotb.triggers import Lock
from cocotb.drivers import BusDriver
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb import log
from nysa.host.driver.utils import list_to_hex_string

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

#Default buffer size
BUFFER_SIZE = 512

CLK_PERIOD = 12

def setup_ft245_clk(dut):
    cocotb.fork(Clock(dut.ft245_clk, CLK_PERIOD).start())

class FT245(BusDriver):

    _signals = ["data", "txe_n", "wr_n", "rd_n", "rde_n", "oe_n", "siwu"]

    def __init__(self, entity, name, clock, buffer_size = BUFFER_SIZE, debug = False):
        BusDriver.__init__(self, entity, name, clock)
        if debug:
            self.log.setLevel(logging.DEBUG)
        self.buffer_size = buffer_size
        self.bus.data.binstr = 'ZZZZZZZZ'
        self.bus.txe_n  <=  1
        self.bus.rde_n  <=  1
        self.data = Array('B')

    @cocotb.coroutine
    def write(self, data):
        length = len(data)
        data_pos = 0
        #XXX: Need to simulate the buffer size behavior to exercise the delay behavior
        buffer_pos = 0
        #print "Sending: %s" % list_to_hex_string(data)

        self.bus.data   <= data[data_pos]
        while data_pos < length:
            if not self.bus.oe_n.value:
                self.bus.data   <= data[data_pos]
            else:
                #self.log.error("User requested data when OE is not low!!")
                self.bus.data.binstr = 'ZZZZZZZZ'

            if not self.bus.rde_n.value and not self.bus.rd_n.value:
                data_pos        += 1
                buffer_pos      += 1
                if self.bus.oe_n.value:
                    self.log.error("User requested data when OE is not low!!")
                if data_pos < length:
                    self.bus.data   <= data[data_pos]
                else:
                    break

            if buffer_pos < self.buffer_size:
                #Notify the FPGA that we have data available
                self.bus.rde_n  <=  0
            else:
                #print "Buffer pos is too large..."
                buffer_pos      =  0
                self.bus.rde_n  <=  1

            yield RisingEdge(self.clock)


        self.bus.data.binstr = 'ZZZZZZZZ'
        self.bus.rde_n  <=  1
        yield RisingEdge(self.clock)

    @cocotb.coroutine
    def read(self, byte_length):
        data_pos = 0
        self.data = Array('B')
        buffer_pos = 0
        self.bus.data.binstr = 'ZZZZZZZZ'
        self.bus.txe_n  <= 1

        while data_pos < byte_length:

            if buffer_pos < self.buffer_size:
                self.bus.txe_n  <= 0
            else:
                self.bus.txe_n  <= 1
                buffer_pos      = 0

            yield ReadOnly()

            if not self.bus.wr_n.value:
                self.data.append(self.bus.data.value)
                data_pos        += 1
                buffer_pos      += 1

            yield FallingEdge(self.clock)

        self.bus.txe_n  <=  1
        yield RisingEdge(self.clock)

    def get_data(self):
        return self.data

