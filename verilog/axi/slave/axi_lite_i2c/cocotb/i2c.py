#Distributed under the MIT licesnse.
#Copyright (c) 2011 Dave McCoy (dave.mccoy@cospandesign.com)

#Permission is hereby granted, free of charge, to any person obtaining a copy of
#this software and associated documentation files (the "Software"), to deal in
#the Software without restriction, including without limitation the rights to
#use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
#of the Software, and to permit persons to whom the Software is furnished to do
#so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

""" I2C

Facilitates communication with the I2C core independent of communication
medium

For more details see:

http://wiki.cospandesign.com/index.php?title=Wb_i2c

"""

__author__ = 'dave.mccoy@cospandesign.com (Dave McCoy)'

import sys
import os
import time

from array import array as Array

import cocotb
from cocotb.result import ReturnValue
from cocotb.drivers.amba import AXI4LiteMaster
from cocotb.triggers import Timer



COSPAN_DESIGN_I2C_MODULE = 0x01

#Register Constants
CONTROL               = 0
STATUS                = 1
INTERRUPT             = 2
INTERRUPT_EN          = 3
CLOCK_RATE            = 4
CLOCK_DIVISOR         = 5
COMMAND               = 6
TRANSMIT              = 7
RECEIVE               = 8
VERSION               = 9

#Control bit values
CONTROL_EN            = 0
CONTROL_INTERRUPT_EN  = 1
CONTROL_SET_100KHZ    = 2
CONTROL_SET_400KHZ    = 3
CONTROL_RESET         = 7

#Status
STATUS_TIP            = 1 << 1
STATUS_ARB_LOST       = 1 << 5
STATUS_BUSY           = 1 << 6
STATUS_READ_ACK_N     = 1 << 7

#Command
COMMAND_START         = 1 << 0
COMMAND_STOP          = 1 << 1
COMMAND_READ          = 1 << 2
COMMAND_WRITE         = 1 << 3
COMMAND_NACK          = 1 << 4

class I2CError (Exception):
    """I2C Error:

    Errors associated with I2C
        I2C Bus Busy
        Incorrect Settings
    """
    pass


class I2C(object):
    """I2C
    """

    @staticmethod
    def get_abi_class():
        return 0

    @staticmethod
    def get_abi_major():
        return driver.get_device_id_from_name("i2c")

    @staticmethod
    def get_abi_minor():
        return COSPAN_DESIGN_I2C_MODULE

    #def __init__(self, nysa, urn, debug = False):
    def __init__(self, dut, BUS_NAME, clock_period = 10, debug = False):
        #super(I2C, self).__init__(nysa, urn, debug)
        self.dut = dut
        self.axim = AXI4LiteMaster(dut, BUS_NAME, dut.clk)
        self.clk_period = clock_period
        self.reset_i2c_core()

    def __del__(self):
        self.enable_i2c(False)

    @cocotb.coroutine
    def _write_data(self, address, data):
        yield self.axim.write((address << 2), data)
        yield Timer(self.clk_period * 1)

    @cocotb.coroutine
    def _read_data(self, address, len = 1):
        data = yield self.axim.read(address << 2)
        yield Timer(self.clk_period * 1)
        raise ReturnValue(data)

    @cocotb.coroutine
    def get_control(self):
        """get_control

        Read the control register

        Args:
            Nothing

        Return:
            32-bit control register value

        Raises:
            NysaCommError: Error in communication
        """
        return self._read_data(CONTROL)

    @cocotb.coroutine
    def set_control(self, control):
        """set_control

        Write the control register

        Args:
            control: 32-bit control value

        Returns:
            Nothing

        Raises:
            NysaCommError: Error in communication
        """
        self._write_data(CONTROL, control)

    @cocotb.coroutine
    def get_status(self):
        """get_status

        read the status register

        Args:
            Nothing

        Return:
            32-bit status register value

        Raises:
            NysaCommError: Error in communication
        """
        return self._read_data(STATUS)

    @cocotb.coroutine
    def set_command(self, command):
        """set_command

        set the command register

        Args:
            command: 32-bit command value

        Return:
            Nothing

        Raises:
            NysaCommError: Error in communication
        """
        self._write_data(COMMAND, command)

    @cocotb.coroutine
    def reset_i2c_core(self):
        """reset_i2c_core

        reset the i2c core

        Args:
            Nothing

        Return:
            Nothing

        Raises:
            NysaCommError
        """
        #The core will clear disable the reset the control bit on it's own
        self.set_register_bit(CONTROL, CONTROL_RESET)

    @cocotb.coroutine
    def get_clock_rate(self):
        """get_clock_rate

        returns the clock rate from the module

        Args:
            Nothing

        Returns:
            32-bit representation of the clock

        Raises:
            NysaCommError: Error in communication
        """
        return self._read_data(CLOCK_RATE)

    @cocotb.coroutine
    def get_clock_divider(self):
        """get_clock_divider

        returns the clock divider from the module

        Args:
            Nothing

        Returns:
            32-bit representation of the clock divider

        Raises:
            NysaCommError: Error in communication
        """
        return self._read_data(CLOCK_DIVISOR)

    @cocotb.coroutine
    def set_speed_to_100khz(self):
        """set_speed_to_100khz

        sets the flag for 100khz mode

        Args:
            Nothing

        Return:
            Nothing

        Raises:
            NysaCommError: Error in communication
        """
        self.set_register_bit(CONTROL, CONTROL_SET_100KHZ)

    @cocotb.coroutine
    def set_speed_to_400khz(self):
        """set_speed_to_400khz

        sets the flag for 400khz mode

        Args:
            Nothing

        Return:
            Nothing

        Raises:
            NysaCommError: Error in communication
        """
        self.set_register_bit(CONTROL, CONTROL_SET_400KHZ)

    @cocotb.coroutine
    def set_custom_speed(self, rate):
        """set_custom_speed

        sets the clock divisor to generate the custom speed

        Args:
            rate: speed of I2C

        Return:
            Nothing

        Raises:
            NysaCommError: Error in communication
        """
        clock_rate = self.get_clock_rate()
        divisor = clock_rate / (5 * rate)
        self.set_clock_divider(divisor)

    @cocotb.coroutine
    def set_clock_divider(self, clock_divider):
        """set_clock_divider

        set the clock divider

        Args:
            clock_divider: 32-bit value to write into the register

        Returns:
            Nothing

        Raises:
            NysaCommError: Error in communication
        """
        self._write_data(CLOCK_DIVISOR, clock_divider)

    @cocotb.coroutine
    def enable_i2c(self, enable):
        """enable_i2c

        Enable the I2C core

        Args:
            enable:
                True
                False

        Returns:
            Nothing

        Raises:
            NysaCommError: Error in communication
        """
        self.enable_register_bit(CONTROL, CONTROL_EN, enable)

    @cocotb.coroutine
    def is_i2c_enabled(self):
        """is_i2c_enabled

        returns true if i2c is enabled

        Args:
            Nothing

        Returns:
            True: Enabled
            False: Not Enabled

        Raises:
            NysaCommError: Error in communication
        """
        return self.is_register_bit_set(CONTROL, CONTROL_EN)

    @cocotb.coroutine
    def enable_interrupt(self, enable):
        """enable_interrupts

        Enable interrupts upon completion of sending a byte and arbitrattion
        lost

        Args:
            enable:
                True
                False

        Returns:
            Nothing

        Raises:
            NysaCommError: Error in communication
        """
        self.enable_register_bit(CONTROL, CONTROL_INTERRUPT_EN, enable)

    @cocotb.coroutine
    def is_interrupt_enabled(self):
        """is_i2c_enabled

        returns true if i2c is enabled

        Args:
            Nothing

        Returns:
            True: Enabled
            False: Not Enabled

        Raises:
            NysaCommError: Error in communication
        """
        return self.is_register_bit_set(CONTROL, CONTROL_INTERRUPT_EN)

    @cocotb.coroutine
    def print_control(self, control):
        """print_control

        print out the control in an easily readible format

        Args:
            status: The control to print out

        Returns:
            Nothing

        Raises:
            NysaCommError: Error in communication
        """
        print "Control (0x%X): " % control
        if (control & (1 << CONTROL_EN)) > 0:
            print "\tI2C Core Enabled"
        if (control & (1 << CONTROL_INTERRUPT_EN)) > 0:
            print "\tI2C Interrupt Enabled"

    @cocotb.coroutine
    def print_command(self,command):
        """print_command

        print out the command in an easily readible format

        Args:
            status: The command to print out

        Returns:
            Nothing

        Raises:
            Nothing
        """
        print "Command (0x%X): " % command
        if (command & COMMAND_START) > 0:
            print "\tSTART"
        if (command & COMMAND_STOP) > 0:
            print "\tSTOP"
        if (command & COMMAND_READ) > 0:
            print "\tREAD"
        if (command & COMMAND_WRITE) > 0:
            print "\tWRITE"
        if (command & COMMAND_NACK) > 0:
            print "\tNACK"

    @cocotb.coroutine
    def print_status(self, status):
        """print_status

        print out the status in an easily readible format

        Args:
            status: The status to print out

        Returns:
            Nothing

        Raises:
            Nothing
        """

        print "Status (0x%X): " % status
        if (status & STATUS_IRQ_FLAG) > 0:
            print "\tInterrupt pending"
        if (status & STATUS_TIP) > 0:
            print "\tTransfer in progress"
        if (status & STATUS_ARB_LOST) > 0:
            print "\tArbitration lost"
        if (status & STATUS_BUSY) > 0:
            print "\tTransaction in progress"
        if (status & STATUS_READ_ACK_N) > 0:
            print "\tNo ack from slave"
        else:
            print "\tAck from slave"

    @cocotb.coroutine
    def reset_i2c_device(self):
        """reset_i2c_device

        resets the I2C devices

        Args:
            Nothing

        Return:
            Nothing

        Raises:
            NysaCommError: Error in communication
        """
        self.print_control(self.get_control())
        #send the write command / i2c identification
        self._write_data(TRANSMIT, 0xFF)
        self._write_data(COMMAND, COMMAND_WRITE | COMMAND_STOP)
        self._write_data(TRANSMIT, 0xFF)
        self._write_data(COMMAND, COMMAND_WRITE | COMMAND_STOP)

        time.sleep(.1)
        if self.debug:
            self.print_status(self.get_status())

    @cocotb.coroutine
    def write_to_i2c(self, i2c_id, i2c_data, repeat_start = False):
        """write_to_i2c_register

        write to a register in the I2C device

        Args:
            i2c_id: Identification byte of the I2C (7-bit)
                this value will be shifted left by 1
            i2c_data: data to write to that register Array of bytes
            repeat_start: do not explicitely end a transaction, this is used for
                a repeat start condition

        Returns:
            Nothing

        Raises:
            NysaCommError: Error in communication
            I2CError: Errors associated with the I2C protocol
        """
        #self.debug = True
        #set up a write command
        write_command = i2c_id << 1
        #set up interrupts
        self.enable_interrupt(True)

        #send the write command / i2c identification
        self._write_data(TRANSMIT, write_command)

        command = COMMAND_START | COMMAND_WRITE
        #if self.debug:
        #    self.print_control(self._read_data(CONTROL))
        #    self.print_command(command)

        #send the command to the I2C command register to initiate a transfer
        self._write_data(COMMAND, command)

        #wait 1 second for interrupt
        if self.debug: print "Wait for interrupts..."
        if self.wait_for_interrupts(wait_time = 1):
            if self.debug:
                print "got interrupt for start"
            #if self.is_interrupt_for_slave():
            status = self.get_status()
            if self.debug:
                self.print_status(status)
            if (status & STATUS_READ_ACK_N) > 0:
                self.register_dump()
                raise I2CError("Did not recieve an ACK while writing I2C ID: 0x%02X" % i2c_id)
        else:
            if self.debug:
                self.print_status(self.get_status())
                self.register_dump()
            raise I2CError("Timed out while waiting for interrupt during a start: 0x%02X" % i2c_id)

        #send the data
        count = 0
        if self.debug:
            print "total data to write: %d" % len(i2c_data)
        if len(i2c_data) > 1:
            while count < len(i2c_data) - 1:
                if self.debug:
                    print "Writing %d" % count
                data = i2c_data[count]
                self._write_data(TRANSMIT, data)
                self._write_data(COMMAND, COMMAND_WRITE)
                if self.wait_for_interrupts(wait_time = 1):
                    if self.debug:
                        print "got interrupt for data"
                #if self.is_interrupt_for_slave():
                    status = self.get_status()
                    #self.print_status(status)
                    if (status & STATUS_READ_ACK_N) > 0:
                        raise I2CError("Did not receive an ACK while writing data")
                else:
                    raise I2CError("Timed out while waiting for interrupt durring send data")

                count = count + 1

        #send the last peice of data
        data = None
        if count < len(i2c_data):
            data = i2c_data[count]
            self._write_data(TRANSMIT, data)
            count += 1

        if not repeat_start:
            if count >= len(i2c_data):
                #last peice of data to be written
                self._write_data(COMMAND, COMMAND_WRITE | COMMAND_STOP)
            else:
                #There is just a start then stop command
                self._write_data(COMMAND, COMMAND_STOP)

            if self.wait_for_interrupts(wait_time = 1):
                if self.debug:
                    print "got interrupt for the last byte"
                #if self.is_interrupt_for_slave():
                status = self.get_status()
                if (status & STATUS_READ_ACK_N) > 0:
                    raise I2CError("Did not receive an ACK while writing data")
            else:
                raise I2CError("Timed out while waiting for interrupt while sending the last byte")

        else:
            #XXX: This repeat start condition has not been tested out!
            self._write_data(COMMAND, COMMAND_WRITE)


        #self.debug = True

    @cocotb.coroutine
    def read_from_i2c(self, i2c_id, i2c_write_data, read_length):
        """read_from_i2c_register

        read from a register in the I2C device

        Args:
            i2c_id: Identification byte of the I2C (7-bit)
                this value will be shifted left by 1
            i2c_write_data: data to write to that register (Array of bytes)
                in order to read from an I2C device the user must write some
                data to set up the device to read
            read_length: Length of bytes to read from the device

        Returns:
            Array of bytes read from the I2C device

        Raises:
            NysaCommError: Error in communication
            I2CError: Errors associated with the I2C protocol
        """
        #self.debug = False
        if self.debug: print "read_from_i2c: ENTERED"
        #set up a write command
        read_command = (i2c_id << 1) | 0x01
        read_data = Array('B')
        self.reset_i2c_core()
        if self.debug:
            print "\t\tGetting status before a read"
            self.print_status(self._read_data(STATUS))
            print "\t\tGetting status before a read"
            self.print_status(self._read_data(STATUS))

        #setup the registers to read
        if i2c_write_data is not None:
            if self.debug: print "Writing to I2C"
            self.write_to_i2c(i2c_id, i2c_write_data)

        #set up interrupts
        self.enable_interrupt(True)

        #send the write command / i2c identification
        self._write_data(TRANSMIT, read_command)


        command = COMMAND_START | COMMAND_WRITE
        if self.debug:
            self.print_command(command)
        #send the command to the I2C command register to initiate a transfer
        self._write_data(COMMAND, command)

        #wait 1 second for interrupt
        if self.wait_for_interrupts(wait_time = 1):
            if self.debug:
                print "got interrupt for start"
            #if self.is_interrupt_for_slave():
            status = self.get_status()
            if self.debug:
                self.print_status(status)
            if (status & STATUS_READ_ACK_N) > 0:
                raise I2CError("Did not recieve an ACK while writing I2C ID")

        else:
            if self.debug:
                self.print_status(self.get_status())
            raise I2CError("Timed out while waiting for interrupt durring a start")

        #send the data
        count = 0
        if read_length > 1:
            while count < read_length - 1:
                self.get_status()
                if self.debug:
                    print "\tReading %d" % count
                self._write_data(COMMAND, COMMAND_READ)
                if self.wait_for_interrupts(wait_time = 1):
                    if self.get_status() & 0x01:
                        #print "Status: 0x%08X" % self.get_status()
                        if self.debug:
                            print "got interrupt for data"
                        #if self.is_interrupt_for_slave(self.dev_id):
                        status = self.get_status()
                        #if (status & STATUS_READ_ACK_N) > 0:
                        #  raise I2CError("Did not receive an ACK while reading data")
                        value = self._read_data(RECEIVE)
                        if self.debug:
                            print "value: %s" % str(value)
                        read_data.append((value & 0xFF))


                else:
                    raise I2CError("Timed out while waiting for interrupt during read data")

                count = count + 1

        #read the last peice of data
        self._write_data(COMMAND, COMMAND_READ | COMMAND_NACK | COMMAND_STOP)
        if self.wait_for_interrupts(wait_time = 1):
            if self.debug:
                print "got interrupt for the last byte"
            if self.get_status() & 0x01:
                #if self.is_interrupt_for_slave(self.dev_id):
                #status = self.get_status()
                #if (status & STATUS_READ_ACK_N) > 0:
                #  raise I2CError("Did not receive an ACK while writing data")

                value = self._read_data(RECEIVE)
                if self.debug:
                  print "value: %d" % value
                read_data.append(value & 0xFF)
        else:
            raise I2CError("Timed out while waiting for interrupt while reading the last byte")

        #self.debug = False
        return read_data

