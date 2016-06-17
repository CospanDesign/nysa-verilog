import sys
import os
import time
import logging
from array import array as Array
from collections import OrderedDict
from cocotb.triggers import ReadOnly
import cocotb
from cocotb.result import ReturnValue
from nysa.host.driver.utils import *


DEVICE_TYPE                     = "Logic Analyzer"


#Addresses
CONTROL         = 0x00
STATUS          = 0x01
TRIGGER         = 0x02
TRIGGER_MASK    = 0x03
TRIGGER_AFTER   = 0x04
TRIGGER_EDGE    = 0x05
BOTH_EDGES      = 0x06
REPEAT_COUNT    = 0x07
DATA_COUNT      = 0x08
START_POS       = 0x09
CLOCK_RATE      = 0x0A
READ_DATA       = 0x0B

class UARTLogicAnalyzer(object):
    """ wb_logic_analyser

        Communication with a logic analyzer
    """

    def __init__(self, uart_path, baudrate = 115200, sim = False, log = None, debug = False):
        object.__init__(self)
        if log is None:
            self.log = logging.getLogger("Logic Analyzer")
        else:
            self.log = log
        self.log.info("Started")
        self.uart = None
        self.path = uart_path
        self.path = "sim"
        self.start_pos = 0
        if sim:
            self.uart = uart_path
            
    @cocotb.coroutine
    def ping(self):
        yield self.uart.write(Array('B', "W0\n"))
        self.log.info("Finished Write!")
        yield self.uart.read(4)
        yield ReadOnly()
        self.data = self.uart.get_data()
        self.log.info("Data: %s" % str(self.data))
        if self.data.tostring()[1] == "S":
            self.log.info("Success")
        else:
            self.log.info("Fail")

    @cocotb.coroutine
    def reset(self):
        wr_data = "W;\n"
        print "Write data: %s" % wr_data
        yield self.uart.write(Array('B', wr_data))
        self.log.info("Finished Write!")
        yield self.uart.read(4)
        yield ReadOnly()
        self.data = self.uart.get_data()
        self.log.info("Data: %s" % str(self.data))
        if self.data.tostring()[1] == "S":
            self.log.info("Success")
        else:
            self.log.info("Fail")

    @cocotb.coroutine
    def enable(self, enable):
        wr_data = "W1%d\n" % enable
        print "Write data: %s" % wr_data
        yield self.uart.write(Array('B', wr_data))
        self.log.info("Finished Write!")
        yield self.uart.read(4)
        yield ReadOnly()
        self.data = self.uart.get_data()
        self.log.info("Data: %s" % str(self.data))
        if self.data.tostring()[1] == "S":
            self.log.info("Success")
        else:
            self.log.info("Fail")

    @cocotb.coroutine
    def is_enabled(self):
        wr_data = "W2\n"
        print "Write data: %s" % wr_data
        yield self.uart.write(Array('B', wr_data))
        yield self.uart.read(5)
        yield ReadOnly()
        self.data = self.uart.get_data()
        self.log.info("Data: %s" % str(self.data))
        if self.data.tostring()[2] == "1":
            self.log.info("Enabled")
        else:
            self.log.info("Disabled")

    @cocotb.coroutine
    def is_finished(self):
        pass

    @cocotb.coroutine
    def force_trigger(self):
        wr_data = "W<\n"
        print "Write data: %s" % wr_data
        yield self.uart.write(Array('B', wr_data))
        self.log.info("Finished Write!")
        yield self.uart.read(4)
        yield ReadOnly()
        self.data = self.uart.get_data()
        self.log.info("Data: %s" % str(self.data))
        if self.data.tostring()[1] == "S":
            self.log.info("Success")
        else:
            self.log.info("Fail")

    @cocotb.coroutine
    def set_trigger(self, trigger):
        wr_data = "W4%08X\n" % trigger
        print "Write data: %s" % wr_data
        yield self.uart.write(Array('B', wr_data))
        self.log.info("Finished Write!")
        yield self.uart.read(4)
        yield ReadOnly()
        self.data = self.uart.get_data()
        self.log.info("Data: %s" % str(self.data))
        if self.data.tostring()[1] == "S":
            self.log.info("Success")
        else:
            self.log.info("Fail")

    @cocotb.coroutine
    def set_trigger_mask(self, trigger_mask):
        wr_data = "W5%08X\n" % trigger_mask
        print "Write data: %s" % wr_data
        yield self.uart.write(Array('B', wr_data))
        self.log.info("Finished Write!")
        yield self.uart.read(4)
        yield ReadOnly()
        self.data = self.uart.get_data()
        self.log.info("Data: %s" % str(self.data))
        if self.data.tostring()[1] == "S":
            self.log.info("Success")
        else:
            self.log.info("Fail")

    @cocotb.coroutine
    def set_trigger_after(self, trigger_after):
        wr_data = "W6%08X\n" % trigger_after
        print "Write data: %s" % wr_data
        yield self.uart.write(Array('B', wr_data))
        self.log.info("Finished Write!")
        yield self.uart.read(4)
        yield ReadOnly()
        self.data = self.uart.get_data()
        self.log.info("Data: %s" % str(self.data))
        if self.data.tostring()[1] == "S":
            self.log.info("Success")
        else:
            self.log.info("Fail")

    @cocotb.coroutine
    def set_trigger_edge(self, trigger_edge):
        wr_data = "W7%08X\n" % trigger_edge
        print "Write data: %s" % wr_data
        yield self.uart.write(Array('B', wr_data))
        self.log.info("Finished Write!")
        yield self.uart.read(4)
        yield ReadOnly()
        self.data = self.uart.get_data()
        self.log.info("Data: %s" % str(self.data))
        if self.data.tostring()[1] == "S":
            self.log.info("Success")
        else:
            self.log.info("Fail")

    @cocotb.coroutine
    def set_both_edge(self, both_edges):
        wr_data = "W8%08X\n" % both_edges
        print "Write data: %s" % wr_data
        yield self.uart.write(Array('B', wr_data))
        self.log.info("Finished Write!")
        yield self.uart.read(4)
        yield ReadOnly()
        self.data = self.uart.get_data()
        self.log.info("Data: %s" % str(self.data))
        if self.data.tostring()[1] == "S":
            self.log.info("Success")
        else:
            self.log.info("Fail")

    @cocotb.coroutine
    def set_repeat_count(self, repeat_count):
        wr_data = "W9%08X\n" % repeat_count
        print "Write data: %s" % wr_data
        yield self.uart.write(Array('B', wr_data))
        self.log.info("Finished Write!")
        yield self.uart.read(4)
        yield ReadOnly()
        self.data = self.uart.get_data()
        self.log.info("Data: %s" % str(self.data))
        if self.data.tostring()[1] == "S":
            self.log.info("Success")
        else:
            self.log.info("Fail")

    @cocotb.coroutine
    def get_data_count(self):
        wr_data = "W3\n"
        print "Write data: %s" % wr_data
        yield self.uart.write(Array('B', wr_data))
        yield self.uart.read(12)
        yield ReadOnly()
        self.data = self.uart.get_data()
        self.log.info("Data: %s" % str(self.data))

        d = self.data[2:10].tostring()

        data = Array('B')
        for i in range(0, len(d), 2):
            v = (int(d[i], 0) << 4) | int(d[i + 1], 0)
            data.append(v)

        value = array_to_dword(data)
        self.log.info("Value: 0x%08X" % value)
        raise ReturnValue(value)

    @cocotb.coroutine
    def get_start_pos(self):
        wr_data = "W:\n"
        print "Write data: %s" % wr_data
        yield self.uart.write(Array('B', wr_data))
        yield self.uart.read(12)
        yield ReadOnly()
        self.data = self.uart.get_data()
        self.log.info("Data: %s" % str(self.data))

        d = self.data[2:10].tostring()

        data = Array('B')
        for i in range(0, len(d), 2):
            v = (int(d[i], 0) << 4) | int(d[i + 1], 0)
            data.append(v)

        value = array_to_dword(data)
        self.log.info("Value: 0x%08X" % value)
        raise ReturnValue(value)


    @cocotb.coroutine
    def read_raw_data(self):
        return self.read(READ_DATA, self.data_count, disable_auto_inc = True)

    @cocotb.coroutine
    def read_data(self):
        #start_pos = self.read_register(START_POS)
        #raw_data = self.read(READ_DATA, self.data_count, disable_auto_inc = True)
        yield self.uart.read(8 + 8 * 8)
        data = Array('B', self.uart.get_data().tostring().decode("hex"))
        #data = Array('B')
        #print "Data: %s" % str(data)
        '''
        for i in range(0, len(d), 2):
            v = (int(d[i], 0) << 4) | int(d[i + 1], 0)
            data.append(v)

        #Need to reorder the data so it makes sense for the user
        temp = Array('L')
        for i in range (0, len(raw_data), 4):
            temp.append(array_to_dword(data[i: i + 4]))

        #for i in range (0, len(temp), 1):
        #    print "\t[%04X] 0x%08X" % (i, temp[i])

        print "Start Pos: 0x%04X" % start_pos

        #Change data to 32-bit array
        data = Array('L')
        if start_pos  == 0:
            data = temp

        data.extend(temp[start_pos:])
        data.extend(temp[0:start_pos])
        '''
        raise ReturnValue(data)

    def get_clock_rate(self):
        return self.read_register(CLOCK_RATE)

def set_vcd_header():
    #set date
    buf = ""
    buf += "$date\n"
    buf += time.strftime("%b %d, %Y %H:%M:%S") + "\n"
    buf += "$end\n"
    buf += "\n"

    #set version
    buf += "$version\n"
    buf += "\tNysa Logic Analyzer V0.1\n"
    buf += "$end\n"
    buf += "\n"

    #set the timescale
    buf += "$timescale\n"
    buf += "\t1 ns\n"
    buf += "$end\n"
    buf += "\n"

    return buf

def set_signal_names(signal_dict, add_clock):
    buf = ""

    #set the scope
    buf += "$scope\n"
    buf += "$module logic_analyzer\n"
    buf += "$end\n"
    buf += "\n"

    offset = 0
    char_offset = 33
    if add_clock:
        character_alias = char_offset
        buf += "$var wire 1 %c clk $end\n" % (character_alias)
        char_offset = 34

    offset = 0
    for name in signal_dict:
        character_alias = char_offset + offset
        buf += "$var wire %d %c %s $end\n" % (signal_dict[name], character_alias, name)
        offset += 1

    #Pop of the scope stack
    buf += "\n"
    buf += "$upscope\n"
    buf += "$end\n"
    buf += "\n"

    #End the signal name defnitions
    buf += "$enddefinitions\n"
    buf += "$end\n"
    return buf

def set_waveforms(data, signal_dict, add_clock, cycles_per_clock, debug = False):
    buf = ""
    buf += "#0\n"
    buf += "$dumpvars\n"
    timeval = 0

    if debug: print "Cycles per clock: %d" % cycles_per_clock

    index_offset = 33
    clock_character = 33
    if add_clock:
        index_offset = 34

    #Time 0
    #Add in the initial Clock Edge
    if add_clock:
        buf += "%d%c\n" % (0, clock_character)

    for i in range(len(signal_dict)):
        buf += "x%c\n" % (index_offset + i)

    #Time 1/2 clock cycle
    if add_clock:
        buf += "#%d\n" % (cycles_per_clock / 2)
        buf += "%d%c\n" % (0, clock_character)

    if add_clock:
        buf += "#%d\n" % ((i + 1) * cycles_per_clock)
        buf += "%d%c\n" % (1, clock_character)


    for j in range (len(signal_dict)):
        buf += "%d%c\n" % (((data[0] >> j) & 0x01), (index_offset + j))

    #Time 1/2 clock cycle
    if add_clock:
        buf += "#%d\n" % (cycles_per_clock / 2)
        buf += "%d%c\n" % (0, clock_character)



    #Go through all the values for every time instance and look for changes
    if debug: print "Data Length: %d" % len(data)
    for i in range(1, len(data)):

        if add_clock:
            buf += "#%d\n" % ((i + 1) * cycles_per_clock)
            buf += "%d%c\n" % (1, clock_character)

        #Read up to the second to the last peice of data
        if data[i - 1] != data[i]:
            if not add_clock:
                buf += "#%d\n" % ((i + 1) * cycles_per_clock)
            for j in range (len(signal_dict)):
                if ((data[i - 1] >> j) & 0x01) != ((data[i] >> j) & 0x01):
                    buf += "%d%c\n" % (((data[i] >> j) & 0x01), (index_offset + j))

        if add_clock:
            buf += "#%d\n" % (((i + 1) * cycles_per_clock) + (cycles_per_clock / 2))
            buf += "%d%c\n" % (0, clock_character)


    buf += "#%d\n" % (len(data) * cycles_per_clock)
    for i in range(len(signal_dict)):
        buf += "%d%c\n" % (((data[-1] >> i) & 0x01), (33 + i))
    return buf

def create_vcd_buffer(data, signal_dict = OrderedDict(), count = 32, clock_count = 100, add_clock = True, debug = False):
    if debug: print "Create a VCD file"
    print "clock count: %d" % clock_count
    ghertz_freq = 1000000000
    if clock_count == 0:
        clock_count = 100000000
    cycles_per_clock = int(ghertz_freq / clock_count)
    if debug: print "Clocks per cycle: %d" % cycles_per_clock

    if len(signal_dict) < count:
        for i in range(count):
            signal_dict["signal%d" % i] = 1

    buf = ""
    buf += set_vcd_header()
    buf += set_signal_names(signal_dict, add_clock)
    buf += set_waveforms(data, signal_dict, add_clock, cycles_per_clock, debug)
    return buf


