import os
import sys
import time
import cocotb
from cocotb.result import ReturnValue
from cocotb.clock import Clock
from cocotb.triggers import Timer
from cocotb.drivers.amba import AXI4LiteMaster

CLK_PERIOD = 10

class Driver(object):

    def __init__(self, dut, clock, MASTER_NAME="AXIML", debug=False):
        
        self.debug = debug
        self.dut = dut
        self.clock = clock
        self.dut.rst <= 1
        self.dut.test_id = 0
        self.axim = AXI4LiteMaster(dut, MASTER_NAME, self.clock)
        cocotb.fork(Clock(self.clock, CLK_PERIOD).start())
        dut.log.debug ("Started")

    @cocotb.coroutine
    def read(self, address, length = 1):
        """read

        Generic read command used to read data from a Nysa image, this will be
        overriden based on the communication method with the FPGA board

        standard methods include

        UART, FTDI Synchronous FIFO, Cypress USB 3.0 Interface,

        Args:
          length (int): Number of 32 bit words to read from the FPGA
          address (int):  Address of the register/memory to read
          disable_auto_inc (bool): if true, auto increment feature will be disabled

        Returns:
          (Array of unsigned bytes): A byte array containtin the raw data
                                     returned from Nysa

        Raises:
          AssertionError: This function must be overriden by a board specific
          implementation
        """
        data = []
        for i in range(length):
            d = yield self.axim.read((address + (i << 2)))
            data.append(int(d))
            yield Timer(CLK_PERIOD * 10)
        raise ReturnValue(data)

    @cocotb.coroutine
    def write(self, address, data):
        """write

        Generic write command usd to write data to a Nysa image, this will be
        overriden based on the communication method with the specific FPGA board

        Args:
            address (int): Address of the register/memory to read
            data (array of unsigned bytes): Array of raw bytes to send to the
                                           device
            disable_auto_inc (bool): if true, auto increment feature will be disabled
        Returns:
            Nothing

        Raises:
            AssertionError: This function must be overriden by a board specific
                implementation
        """
        if type(data) is not list:
            data = [data]

        for i in range(len(data)):
            yield self.axim.write(address + (i << 2), data[i])
            yield Timer(CLK_PERIOD * 10)

    @cocotb.coroutine
    def read_register(self, address):
        """read_register

        Reads a single register from the read command and then converts it to an
        integer

        Args:
          address (int):  Address of the register/memory to read

        Returns:
          (int): 32-bit unsigned register value

        Raises:
          NysaCommError: Error in communication
        """
        data = yield self.read(address, 1)
        raise ReturnValue(data[0])

    @cocotb.coroutine
    def write_register(self, address, value):
        """write_register

        Writes a single register from a 32-bit unsingned integer

        Args:
          address (int):  Address of the register/memory to read
          value (int)  32-bit unsigned integer to be written into the register

        Returns:
          Nothing

        Raises:
          NysaCommError: Error in communication
        """
        yield self.write(address, value)

    @cocotb.coroutine
    def enable_register_bit(self, address, bit, enable):
        """enable_register_bit

        Pass a bool value to set/clear a bit

        Args:
          address (int): Address of the register/memory to modify
          bit (int): Address of bit to set (31 - 0)
          enable (bool): set or clear a bit

        Returns:
          Nothing

        Raises:
          NysaCommError: Error in communication
        """
        if enable:
            yield self.set_register_bit(address, bit)
        else:
            yield self.clear_register_bit(address, bit)

    @cocotb.coroutine
    def set_register_bit(self, address, bit):
        """set_register_bit

        Sets an individual bit in a register

        Args:
          address (int): Address of the register/memory to modify
          bit (int): Address of bit to set (31 - 0)

        Returns:
          Nothing

        Raises:
          NysaCommError: Error in communication
        """
        register = yield self.read_register(address)
        bit_mask =  1 << bit
        register |= bit_mask
        yield self.write_register(address, register)

    @cocotb.coroutine
    def clear_register_bit(self, address, bit):
        """clear_register_bit

        Clear an individual bit in a register

        Args:
          address (int): Address of the register/memory to modify
          bit (int): Address of bit to set (31 - 0)

        Returns:
          Nothing

        Raises:
          NysaCommError: Error in communication
        """
        register = yield self.read_register(address)
        bit_mask =  1 << bit
        register &= ~bit_mask
        yield self.write_register(address, register)

    @cocotb.coroutine
    def is_register_bit_set(self, address, bit):
        """is_register_bit_set

        raise ReturnValues true if an individual bit is set, false if clear

        Args:
          address (int): Address of the register/memory to read
          bit (int): Address of bit to check (31 - 0)

        Returns:
          (boolean):
            True: bit is set
            False: bit is not set

        Raises:
          NysaCommError
        """
        register = yield self.read_register(address)
        bit_mask =  1 << bit
        raise ReturnValue ((register & bit_mask) > 0)


    @cocotb.coroutine
    def read_register_bit_range(self, address, high_bit, low_bit):
        """
        Read a range of bits within a register at address 'address'

        Register = [XXXXXXXXXXXXXXXXXXXXXXXH---LXXXX]

        Read the value within a register, the top bit is H and bottom is L

        Args:
            address (unsigned long): Address or the register/memory to read
            high_bit (int): the high bit of the bit range to read
            low_bit (int): the low bit of the bit range to read

        Returns (unsigned integer):
            Value within the bitfield

        Raises:
            NysaCommError
            
        """

        value = yield self.read_register(address)
        bitmask = (((1 << (high_bit + 1))) - (1 << low_bit))
        value = value & bitmask
        value = value >> low_bit
        raise ReturnValue(value)


    @cocotb.coroutine
    def sleep(self, clock_count):
        yield Timer(clock_count * CLK_PERIOD)

