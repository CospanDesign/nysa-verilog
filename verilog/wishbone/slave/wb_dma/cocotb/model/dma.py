#Distributed under the MIT licesnse.
#Copyright (c) 2015 Dave McCoy (dave.mccoy@cospandesign.com)

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

""" DMA

Facilitates communication with the DMA controller

"""

__author__ = 'dave.mccoy@cospandesign.com (Dave McCoy)'

import sys
import os
import time

from array import array as Array


import driver


COSPAN_DESIGN_DMA_MODULE        = 0x01


#Register Constants
CONTROL                         = 0

BIT_CONTROL_ENABLE              = 0
BIT_CONTROL_INTERRUPT_CMD_FIN   = 1

STATUS                          = 1

CHANNEL_COUNT                   = 2
SINK_COUNT                      = 3

CHANNEL_ADDR_CONTROL_BASE       = 4
CHANNEL_ADDR_STATUS_BASE        = 8

SINK_ADDR_CONTROL_BASE          = 12
SINK_ADDR_STATUS_BASE           = 16

BIT_CHAN_CNTRL_EN               = 0
BIT_SINK_ADDR_TOP               = 5
BIT_SINK_ADDR_BOT               = 6
BIT_INST_PTR_TOP                = 10
BIT_INST_PTR_BOT                = 8

INST_BASE                       = 0x20
INST_OFFSET                     = 0x10

INST_SRC_ADDR_LOW               = 0x00
INST_SRC_ADDR_HIGH              = 0x01
INST_DEST_ADDR_LOW              = 0x02
INST_DEST_ADDR_HIGH             = 0x03
INST_COUNT                      = 0x04
INST_CNTRL                      = 0x05

#Move to Sink/Source Control
BIT_INST_SRC_ADDR_DEC           = 0
BIT_INST_SRC_ADDR_INC           = 1
BIT_INST_SRC_RST_ON_INST        = 2

BIT_INST_DEST_ADDR_DEC          = 4
BIT_INST_DEST_ADDR_INC          = 5
BIT_INST_DEST_QNTM              = 6
BIT_INST_DEST_RST_ON_INST       = 7

#End
BIT_INST_CMD_BOND_INGRESS       = 8
BIT_INST_CMD_BOND_EGRESS        = 9

BIT_INST_CMD_CONTINUE           = 10
BIT_INST_CMD_NEXT_TOP           = 19
BIT_INST_CMD_NEXT_BOT           = 16

BIT_INST_CMD_BOND_ADDR_IN_TOP   = 27
BIT_INST_CMD_BOND_ADDR_IN_BOT   = 24

BIT_INST_CMD_BOND_ADDR_OUT_TOP  = 31
BIT_INST_CMD_BOND_ADDR_OUT_BOT  = 28

#Instruction Count
INST_COUNT                      = 8


class DMAError(Exception):
    """
    Errors associated with DMA Transactions
        SNK Bound Twice
        DMA Not responding
        User requesting a channel count out of range
        User requesting an instruction out of range
    """


class DMA(driver.Driver):
    """
    DMA Controller
    """

    @staticmethod
    def get_abi_class():
        return 0

    @staticmethod
    def get_abi_major():
        return driver.get_device_id_from_name("dma")

    @staticmethod
    def get_abi_minor():
        return COSPAN_DESIGN_DMA_MODULE


    def __init__(self, nysa, urn, debug = False):
        super (DMA, self).__init__(nysa, urn, debug)
        self.instructions_available = [for i in range(0, INST_COUNT)]
        self.instruction_used = []
        self.channel_count = None
        self.sink_count = None

    def __del__(self):
        pass

    def setup(self):
        """
        sets up the core
        """
        self.channel_count = self.read_register(CHANNEL_COUNT)
        self.sink_count = self.read_register(SINK_COUNT)


    def enable_dma(self, enable):
        """
        Enable or disable the entire DMA Controller

        Args:
            enable (bool)
                True: Enables the DMA Controller
                False: Disables the DMA Controller

        Return:
            Nothing

        Raises:
            Nothing
        """
        self.set_register_bit(BIT_CONTROL_ENABLE, enable)

    def enable_interrupt_when_command_fin(self, enable):
        """
        When the command is finished fire off an interrupt to the host

        Args:
            enable (bool)
                True: Enables interrupt when the instructions are finished
                False: Disable interrupts when the instructions are finished

        Returns:
            Nothing

        Raises:
            NysaCommError
        """
        pass

    def set_channel_sink_addr(self, channel, addr):
        """
        Setup the addr where this channel will write to

        Args:
            channel (unsigned char): channel to talk configure
            addr (unsigned char): The 2 bit addr of the destination
                channel
        Returns:
            Nothing

        Raises:
            NysaCommError
        """
        if channel > self.channel_count - 1:
            raise DMAError("Illegal channel count: %d > %d" % (channel, self.channel_count - 1))

        if addr > self.sink_cont - 1:
            raise DMAError("Illegal sink count: %d > %d" % (addr, self.sink_count - 1)

        r = self.read_register(CHANNEL_ADDR_CONTROL_BASE + channel)
        mask = BIT_SINK_ADDR_TOP - BIT_SINK_ADDR_BOT
        r &= ~mask
        addr &= mask >> BIT_SINK_ADDR_BOT
        r |= addres << BIT_SINK_ADDR_BOT
        self.write_register(CHANNEL_ADDR_CONTROL_BASE + channel)

    def get_channel_sink_addr(self, channel):
        """
        Get the data sink port for the specified channel

        Args:
            channel (unsigned char): channel to talk configure

        Returns (unsigned integer):
            Destination port of a DMA transfer

        Raises:
            NysaCommError
        """
        pass

    def set_channel_instruction_pointer(self, channel, ip_addr):
        """
        Set the channel instruction pointer

        Args:
            channel (unsigned char): channel to configure

        Returns:
            Nothing

        Raises:
            NysaCommError
        """
        pass

    def get_channel_instruction_pointer(self, channel)
        """
        Gets the instruction pointer for a channel

        Args:
            channel (unsigned char): channel to talk configure

        Returns (unsigned integer):
            Address of the instruction

        Raises:
            NysaCommError
        """

        pass

    def enable_channel(self, channel):
        """
        Start executing insturctions for a channel pointed to by the instruction
        pointer

        Args:
            channel (unsigned char): channel to talk configure

        Returns:
            Nothing

        Raises:
            NysaCommError

        """
        pass

    def set_instruction(self,   inst_addr,
                                source_addr
                                dest_addr,
                                count,
                                ingress_enable,
                                egress_enable,
                                cmd_continue,
                                next_instruction,
                                ingress_bond_addr,
                                egress_bond_addr):
        """
        Setup individual instruction

        Args:
            inst_addr (unsigned integer): Address of instruction
            source_addr (unsigned long): Address within source device
            sink_addr (unsigned long): Address within destination device
            count (unsigned integer): number of 32-bit data to read/write
            ingress_enable (bool): Enable ingress channel bond
            egress_enable (bool): Enable egress channel bond
            cmd_continue (bool): When finished executing the instruction
                continue to execute the next instruction specified by
                next instruction
            next_instruction(unsigned integer): address of the next instruction
                to execute
            ingress_bond_addr (unsigned integer): channel address of the
                bonded channel (to wait for finished writing data)
            egress_bond_addr (unsigned integer): chanenl address of the
                bonded channel (to wait for finished reading data)

        Return:
            Nothing

        Raises:
            NysaCommError
        """
        if inst_addr > INST_COUNT - 1:
            raise DMAError("Specified instruction address out of range (%d > %d)" % (inst_addr, INST_COUNT))

    def set_instruction_source_address(self, inst_addr, source_addr):
        """
        Sets the source address for the instruction transaction

        Args:
            instr_addr (unsigned int): Address of instruction
            source_addr (64-bit unsigned): source address of where to get data
        Returns:
            Nothing
        Raises:
            NysaCommError
            DMAError
        """
        if inst_addr > INST_COUNT - 1:
            raise DMAError("Specified instruction address out of range (%d > %d)" % (inst_addr, INST_COUNT))
        self.write_register(INST_BASE + inst_addr + INST_SRC_ADDR_LOW,  ((source_addr >> 32) &  0xFFFFFFFF))
        self.write_register(INST_BASE + inst_addr + INST_SRC_ADDR_HIGH, ((source_addr) &        0xFFFFFFFF))

    def set_instruction_dest_address(self, inst_addr, dest_addr):
        """

        Args:
            instr_addr (unsigned int): Address of instruction
            sink_addr (64-bit unsigned): Address of where to put data
        Returns:
            Nothing
        Raises:
            NysaCommError
            DMAError
        """
        if inst_addr > INST_COUNT - 1:
            raise DMAError("Specified instruction address out of range (%d > %d)" % (inst_addr, INST_COUNT))
        self.write_register(INST_BASE + inst_addr + INST_DEST_ADDR_LOW,  ((dest_addr >> 32) &  0xFFFFFFFF))
        self.write_register(INST_BASE + inst_addr + INST_DEST_ADDR_HIGH, ((dest_addr) &        0xFFFFFFFF))

    def set_instruction_count(self, inst_addr, count):
        """

        Args:
            instr_addr (unsigned int): Address of instruction
        Returns:
            Nothing
        Raises:
            NysaCommError
            DMAError
        """
        if inst_addr > INST_COUNT - 1:
            raise DMAError("Specified instruction address out of range (%d > %d)" % (inst_addr, INST_COUNT))
        self.write_register(INST_BASE + inst_addr + INST_COUNT, count)

    def set_instruction_ingress(self, enable, ingress_inst_addr):
        """

        Args:
            instr_addr (unsigned int): Address of instruction
        Returns:
            Nothing
        Raises:
            NysaCommError
            DMAError
        """
        if inst_addr > INST_COUNT - 1:
            raise DMAError("Specified instruction address out of range (%d > %d)" % (inst_addr, INST_COUNT))
        if ingress_inst_addr > INST_COUNT - 1:
            raise DMAError("Specified ingress address is out of range (%d > %d)" % (ingress_inst_addr, INST_COUNT))
        r = self.read_register(INST_BASE + inst_addr + INST_CNTRL)
        mask = BIT_INST_CMD_BOND_ADDR_IN_TOP - BIT_INST_CMD_BOND_ADDR_IN_BOT
        r &= ~mask
        r |= ingress_inst_addr << BIT_INST_CMD_BOND_ADDR_IN_BOT
        self.write_register(INST_BASE + inst_addr + INST_CNTRL, r)

    def set_insturction_egress(self, enable, egress_inst_addr):
        """

        Args:
            instr_addr (unsigned int): Address of instruction
        Returns:
            Nothing
        Raises:
            NysaCommError
            DMAError
        """
        if inst_addr > INST_COUNT - 1:
            raise DMAError("Specified instruction address out of range (%d > %d)" % (inst_addr, INST_COUNT))
        if egress_inst_addr > INST_COUNT - 1:
            raise DMAError("Specified egress address is out of range (%d > %d)" % (egress_inst_addr, INST_COUNT))
        r = self.read_register(INST_BASE + inst_addr + INST_CNTRL)
        mask = BIT_INST_CMD_BOND_ADDR_OUT_TOP - BIT_INST_CMD_BOND_ADDR_OUT_BOT
        r &= ~mask
        r |= egress_inst_addr << BIT_INST_CMD_BOND_ADDR_OUT_BOT
        self.write_register(INST_BASE + inst_addr + INST_CNTRL, r)

    def set_instruction_next_instruction(self, next_instruction):
        """

        Args:
            instr_addr (unsigned int): Address of instruction
        Returns:
            Nothing
        Raises:
            NysaCommError
            DMAError
        """
        if inst_addr > INST_COUNT - 1:
            raise DMAError("Specified instruction address out of range (%d > %d)" % (inst_addr, INST_COUNT))
        if next_instruction > INST_COUNT - 1:
            raise DMAError("Specified next address is out of range (%d > %d)" % (next_instruction, INST_COUNT))
        r = self.read_register(INST_BASE + inst_addr + INST_CNTRL)
        mask = BIT_INST_CMD_NEXT_TOP - BIT_INST_CMD_NEXT_BOT
        r &= ~mask
        r |= next_instruction << BIT_INST_CMD_NEXT_BOT
        self.write_register(INST_BASE + inst_addr + INST_CNTRL, r)

    def enable_instruction_continue(self, inst_addr, enable):
        """

        Args:
            instr_addr (unsigned int): Address of instruction
        Returns:
            Nothing
        Raises:
            NysaCommError
            DMAError
        """
        if inst_addr > INST_COUNT - 1:
            raise DMAError("Specified instruction address out of range (%d > %d)" % (inst_addr, INST_COUNT))
        self.set_register_bit(INST_BASE + inst_addr, BIT_INST_CMD_CONTINUE, enable)

    def setup_double_buffer(self, source, sink, mem, source_addr, sink_addr, count):
        """

        Args:
            instr_addr (unsigned int): Address of instruction
        Returns:
            Nothing
        Raises:
            NysaCommError
            DMAError
        """
        if inst_addr > INST_COUNT - 1:
            raise DMAError("Specified instruction address out of range (%d > %d)" % (inst_addr, INST_COUNT))


