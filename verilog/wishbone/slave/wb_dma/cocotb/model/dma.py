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


from nysa.host.driver import driver


COSPAN_DESIGN_DMA_MODULE        = 0x01


#Register Constants
CONTROL                         = 0

BIT_CONTROL_ENABLE              = 0
BIT_CONTROL_INTERRUPT_CMD_FIN   = 1

STATUS                          = 1

CHANNEL_COUNT                   = 2
SINK_COUNT                      = 3

CHANNEL_ADDR_CONTROL_BASE       = 0x04

BIT_CFG_DMA_ENABLE              = 0
BIT_CFG_SRC_ADDR_DEC            = 1
BIT_CFG_SRC_ADDR_INC            = 2

CHANNEL_ADDR_STATUS_BASE        = 0x08

SINK_ADDR_CONTROL_BASE          = 0x0C

BIT_CFG_DEST_ADDR_DEC           = 1
BIT_CFG_DEST_ADDR_INC           = 2
BIT_CFG_DEST_DATA_QUANTUM       = 3

SINK_ADDR_STATUS_BASE           = 0x10

BIT_CHAN_CNTRL_EN               = 0

BIT_SINK_ADDR_BOT               = 8
BIT_SINK_ADDR_TOP               = 10

BIT_INST_PTR_BOT                = 16
BIT_INST_PTR_TOP                = 19

#Instructions
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

BIT_INST_CMD_CONTINUE           = 11
BIT_INST_CMD_NEXT_TOP           = 19
BIT_INST_CMD_NEXT_BOT           = 16

BIT_INST_CMD_BOND_ADDR_IN_TOP   = 27
BIT_INST_CMD_BOND_ADDR_IN_BOT   = 24

BIT_INST_CMD_BOND_ADDR_OUT_TOP  = 31
BIT_INST_CMD_BOND_ADDR_OUT_BOT  = 28

#Instruction Count
INSTRUCTION_COUNT               = 8


class DMAError(Exception):
    """
    Errors associated with DMA Transactions
        SNK Bound Twice
        DMA Not responding
        User requesting a channel count out of range
        User requesting an instruction out of range
    """
    pass


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
        #return COSPAN_DESIGN_DMA_MODULE
        return COSPAN_DESIGN_DMA_MODULE

    def __init__(self, nysa, urn, debug = False):
        super (DMA, self).__init__(nysa, urn, debug)
        self.instructions_available = [i for i in range(0, INSTRUCTION_COUNT)]
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
        self.enable_dma(False)
        for i in range(self.channel_count):
            self.enable_channel(i, False)

    def get_channel_count(self):
        return self.read_register(CHANNEL_COUNT)

    def get_sink_count(self):
        return self.read_register(SINK_COUNT)

    def get_instruction_count(self):
        return INSTRUCTION_COUNT

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

    def enable_interrupt_when_command_finish(self, enable):
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
        raise AssertionError("Not implemented yet!")
        pass

    def set_channel_sink_addr(self, channel, address):
        """
        Setup the addr where this channel will write to

        Args:
            channel (unsigned char): channel to configure
            addr (unsigned char): The 2 bit addr of the destination
                channel
        Returns:
            Nothing

        Raises:
            NysaCommError
        """
        if channel > self.channel_count - 1:
            raise DMAError("Illegal channel count: %d > %d" % (channel, self.channel_count - 1))

        if address > self.sink_count - 1:
            raise DMAError("Illegal sink count: %d > %d" % (address, self.sink_count - 1))

        r = self.read_register(CHANNEL_ADDR_CONTROL_BASE + channel)
        mask = ((1 << BIT_SINK_ADDR_TOP) - (1 << BIT_SINK_ADDR_BOT))
        r &= ~mask
        r |= address << BIT_SINK_ADDR_BOT
        self.write_register(CHANNEL_ADDR_CONTROL_BASE + channel, r)

    def get_channel_sink_addr(self, channel):
        """
        Get the data sink port for the specified channel

        Args:
            channel (unsigned char): channel to configure

        Returns (unsigned integer):
            Destination port of a DMA transfer

        Raises:
            NysaCommError
        """
        if channel > self.channel_count - 1:
            raise DMAError("Illegal channel count: %d > %d" % (channel, self.channel_count - 1))

        r = self.read_register(CHANNEL_ADDR_CONTROL_BASE + channel)
        mask = ((1 << BIT_SINK_ADDR_TOP) - (1 << BIT_SINK_ADDR_BOT))
        r &= mask
        address = (r >> BIT_SINK_ADDR_BOT & 0x03)
        self.n.s.Verbose("Channel: %d Sink Address: 0x%02X" % (channel, address))
        return address

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
        if channel > self.channel_count - 1:
            raise DMAError("Illegal channel count: %d > %d" % (channel, self.channel_count - 1))

        if ip_addr > INSTRUCTION_COUNT - 1:
            raise DMAError("Illegal sink count: %d > %d" % (ip_addr, INSTRUCTION_COUNT - 1))

        r = self.read_register(CHANNEL_ADDR_CONTROL_BASE + channel)
        mask = ((1 << BIT_INST_PTR_TOP) - (1 << BIT_INST_PTR_BOT))
        r &= ~mask
        r |= ip_addr << BIT_INST_PTR_BOT
        self.write_register(CHANNEL_ADDR_CONTROL_BASE + channel, r)

    def get_channel_instruction_pointer(self, channel):
        """
        Gets the instruction pointer for a channel

        Args:
            channel (unsigned char): channel to configure

        Returns (unsigned integer):
            Address of the instruction

        Raises:
            NysaCommError
            DMAError:
                User requested an address out of range
        """
        if channel > self.channel_count - 1:
            raise DMAError("Illegal channel count: %d > %d" % (channel, self.channel_count - 1))

        r = self.read_register(CHANNEL_ADDR_CONTROL_BASE + channel)
        mask = ((1 << BIT_INST_PTR_TOP) - (1 << BIT_INST_PTR_BOT))
        r &= mask
        address = (r >> BIT_INST_PTR_BOT & 0x07)
        self.n.s.Verbose("Channel %d Sink Address: 0x%02X" % (channel, address))
        return address

    def enable_source_address_increment(self, source, enable):
        """
        Enable incrementing the address on 32-bit value read from the source

        Args:
            channel (unsigned char): channel to configure
            enable (bool):
                True: Enable incrementing the address
                False: Disable incrementing the address

                NOTE: Do not set both increment and decrement, unknown
                    behavior

        Returns:
            Nothing

        Raises:
            NysaCommError
            DMAError:
                User requested an address out of range
        """
        if source > self.channel_count - 1:
            raise DMAError("Illegal source count: %d > %d" % (source, self.channel_count - 1))
        self.enable_register_bit(CHANNEL_ADDR_CONTROL_BASE + source, BIT_CFG_SRC_ADDR_INC, enable)

    def is_source_address_increment(self, source):
        """
        Return True if the source address will increment on every read

        Args:
            channel (unsigned char): channel to configure
        Returns:
            Nothing

        Raises:
            NysaCommError
            DMAError:
                User requested an address out of range
        """
        if source > self.channel_count - 1:
            raise DMAError("Illegal source count: %d > %d" % (source, self.channel_count - 1))
        return self.is_register_bit_set(CHANNEL_ADDR_CONTROL_BASE + source, BIT_CFG_SRC_ADDR_INC)

    def enable_source_address_decrement(self, source, enable):
        """
        Enable decrementing the address on 32-bit value read from the source

        Args:
            channel (unsigned char): channel to configure
            enable (bool):
                True: Enable decrementing the address
                False: Disable decrementing the address

                NOTE: Do not set both increment and decrement, unknown
                    behavior

        Returns:
            Nothing

        Raises:
            NysaCommError
            DMAError:
                User requested an address out of range
        """
        if source > self.channel_count - 1:
            raise DMAError("Illegal source count: %d > %d" % (source, self.channel_count - 1))
        self.enable_register_bit(CHANNEL_ADDR_CONTROL_BASE + source, BIT_CFG_SRC_ADDR_DEC, enable)

    def is_source_address_decrement(self, source):
        """
        Return True if the source address will decrement on every read

        Args:
            channel (unsigned char): channel to configure
        Returns:
            Nothing

        Raises:
            NysaCommError
            DMAError:
                User requested an address out of range
        """
        if source > self.channel_count - 1:
            raise DMAError("Illegal source count: %d > %d" % (source, self.channel_count - 1))
        return self.is_register_bit_set(CHANNEL_ADDR_CONTROL_BASE + source, BIT_CFG_SRC_ADDR_DEC)

    def enable_dest_address_increment(self, sink, enable):
        """
        Enable incrementing the address on 32-bit value read from the dest

        Args:
            sink (unsigned char): sink to configure
            enable (bool):
                True: Enable incrementing the address
                False: Disable incrementing the address

                NOTE: Do not set both increment and decrement, unknown
                    behavior

        Returns:
            Nothing

        Raises:
            NysaCommError
            DMAError:
                User requested an address out of range
        """
        if sink > self.sink_count - 1:
            raise DMAError("Illegal sink count: %d > %d" % (sink, self.sink_count - 1))
        self.enable_register_bit(SINK_ADDR_CONTROL_BASE + sink, BIT_CFG_DEST_ADDR_INC, enable)
        if enable:
            self.enable_register_bit(SINK_ADDR_CONTROL_BASE + sink, BIT_CFG_DEST_ADDR_DEC, False)

    def is_dest_address_increment(self, sink):
        """
        Return True if the sink address will increment on every read

        Args:
            sink (unsigned char): sink to configure
        Returns:
            Nothing

        Raises:
            NysaCommError
            DMAError:
                User requested an address out of range
        """
        if sink > self.sink_count - 1:
            raise DMAError("Illegal sink count: %d > %d" % (sink, self.sink_count - 1))
        return self.is_register_bit_set(SINK_ADDR_CONTROL_BASE + sink, BIT_CFG_DEST_ADDR_INC)

    def enable_dest_address_decrement(self, sink, enable):
        """
        Enable decrementing the address on 32-bit value read from the dest

        Args:
            sink (unsigned char): sink to configure
            enable (bool):
                True: Enable decrementing the address
                False: Disable decrementing the address

                NOTE: Do not set both increment and decrement, unknown
                    behavior

        Returns:
            Nothing

        Raises:
            NysaCommError
            DMAError:
                User requested an address out of range
        """

        if sink > self.sink_count - 1:
            raise DMAError("Illegal sink count: %d > %d" % (sink, self.sink_count - 1))
        self.enable_register_bit(SINK_ADDR_CONTROL_BASE + sink, BIT_CFG_DEST_ADDR_DEC, enable)
        if enable:
            self.enable_register_bit(SINK_ADDR_CONTROL_BASE + sink, BIT_CFG_DEST_ADDR_INC, False)

    def is_dest_address_decrement(self, sink):
        """
        Return True if the sink address will decrement on every read

        Args:
            sink (unsigned char): sink to configure
        Returns:
            Nothing

        Raises:
            NysaCommError
            DMAError:
                User requested an address out of range
        """

        if sink > self.sink_count - 1:
            raise DMAError("Illegal sink count: %d > %d" % (sink, self.sink_count - 1))
        return self.is_register_bit_set(SINK_ADDR_CONTROL_BASE + sink, BIT_CFG_DEST_ADDR_DEC)

    def enable_dest_respect_quantum(self, sink, enable):
        """
        Enable respect data quantum:
        Some devices require data to arrive in a quantum of data

        i.e. SATA requires data to arrive in chunks of 8K bytes. the buffers
        that are setup to write to SATA are 8K so the DMA controller should
        fill up the entire buffer before releasing the buffer. Otherwise unknown
        behavior could be observed on SATA

        Args:
            sink (unsigned char): sink to configure
            enable (bool):
                True: Enable respect data quantum
                False: Disable respect data quantum

        Returns:
            Nothing

        Raises:
            NysaCommError
            DMAError:
                User requested an address out of range
        """
        if sink > self.sink_count - 1:
            raise DMAError("Illegal sink count: %d > %d" % (sink, self.sink_count - 1))
        self.enable_register_bit(SINK_ADDR_CONTROL_BASE + sink, BIT_CFG_DEST_DATA_QUANTUM, enable)

    def is_dest_respect_quantum(self, sink):
        """
        Return True if the source address will respect data quantum on every read

        Args:
            sink (unsigned char): sink to configure
        Returns:
            Nothing

        Raises:
            NysaCommError
            DMAError:
                User requested an address out of range
        """
        if sink > self.sink_count - 1:
            raise DMAError("Illegal sink count: %d > %d" % (sink, self.sink_count - 1))
        return self.is_register_bit_set(SINK_ADDR_CONTROL_BASE + sink, BIT_CFG_DEST_DATA_QUANTUM)

    def enable_channel(self, channel, enable):
        """
        Start executing instructions for a channel pointed to by the instruction
        pointer

        Args:
            channel (unsigned char): channel to configure

        Returns:
            Nothing

        Raises:
            NysaCommError
            DMAError:
                User requested an address out of range

        """
        if channel > self.channel_count - 1:
            raise DMAError("Illegal channel count: %d > %d" % (channel, self.channel_count - 1))

        self.enable_register_bit(CHANNEL_ADDR_CONTROL_BASE + channel, BIT_CFG_DMA_ENABLE, enable)

    def is_channel_enable(self, channel):
        """
        Returns true if channel is enable

        Args:
            channel (unsigned char): channel to configure

        Returns (bool):
            is channel enable

        Raises:
            NysaCommError
            DMAError:
                User requested an address out of range
        """
        if channel > self.channel_count - 1:
            raise DMAError("Illegal channel count: %d > %d" % (channel, self.channel_count - 1))
        value = self.is_register_bit_set(CHANNEL_ADDR_CONTROL_BASE + channel, BIT_CFG_DMA_ENABLE)
        self.n.s.Verbose("Channel %d Enable: %s" % (channel, str(value)))
        return value

    def set_instruction(self,   inst_addr,          \
                                source_addr,        \
                                dest_addr,          \
                                count,              \
                                ingress_enable,     \
                                egress_enable,      \
                                cmd_continue,       \
                                next_instruction,   \
                                ingress_bond_addr,  \
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
        if inst_addr > INSTRUCTION_COUNT - 1:
            raise DMAError("Specified instruction address out of range (%d > %d)" % (inst_addr, INSTRUCTION_COUNT))

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
        if inst_addr > INSTRUCTION_COUNT - 1:
            raise DMAError("Specified instruction address out of range (%d > %d)" % (inst_addr, INSTRUCTION_COUNT))
        self.write_register(INST_BASE + (INST_OFFSET * inst_addr) + INST_SRC_ADDR_LOW,  ((source_addr) &        0xFFFFFFFF))
        self.write_register(INST_BASE + (INST_OFFSET * inst_addr) + INST_SRC_ADDR_HIGH, ((source_addr >> 32) &  0xFFFFFFFF))

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
        if inst_addr > INSTRUCTION_COUNT - 1:
            raise DMAError("Specified instruction address out of range (%d > %d)" % (inst_addr, INSTRUCTION_COUNT))
        self.write_register(INST_BASE + (INST_OFFSET * inst_addr) + INST_DEST_ADDR_LOW,  ((dest_addr) &         0xFFFFFFFF))
        self.write_register(INST_BASE + (INST_OFFSET * inst_addr) + INST_DEST_ADDR_HIGH, ((dest_addr >> 32) &   0xFFFFFFFF))

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
        if inst_addr > INSTRUCTION_COUNT - 1:
            raise DMAError("Specified instruction address out of range (%d > %d)" % (inst_addr, INSTRUCTION_COUNT))
        self.write_register(INST_BASE + (INST_OFFSET * inst_addr) + INST_COUNT, count)

    def set_instruction_ingress(self, inst_addr, enable, ingress_inst_addr = None):
        """
        Sets both the ingress address as well as a flag to enable
        the ingress action

        Args:
            instr_addr (unsigned int): Address of instruction
        Returns:
            Nothing
        Raises:
            NysaCommError
            DMAError
        """
        if not enable:
            ingress_inst_addr = 0

        elif ingress_inst_addr is None:
            raise DMAError("Ingress Address cannot be left blank!")
        
        if inst_addr > INSTRUCTION_COUNT - 1:
            raise DMAError("Specified instruction address out of range (%d > %d)" % (inst_addr, INSTRUCTION_COUNT))

        if ingress_inst_addr > INSTRUCTION_COUNT - 1:
            raise DMAError("Specified ingress address is out of range (%d > %d)" % (ingress_inst_addr, INSTRUCTION_COUNT))

        r = self.read_register(INST_BASE + (INST_OFFSET * inst_addr) + INST_CNTRL)
        mask = BIT_INST_CMD_BOND_ADDR_IN_TOP - BIT_INST_CMD_BOND_ADDR_IN_BOT
        r &= ~mask
        r |= ingress_inst_addr << BIT_INST_CMD_BOND_ADDR_IN_BOT
        self.write_register(INST_BASE + (INST_OFFSET * inst_addr) + INST_CNTRL, r)
        self.enable_register_bit(INST_BASE + (INST_OFFSET * inst_addr) + INST_CNTRL, BIT_INST_CMD_BOND_INGRESS, enable)

    def set_instruction_egress(self, inst_addr, enable, egress_inst_addr = None):
        """

        Args:
            instr_addr (unsigned int): Address of instruction
        Returns:
            Nothing
        Raises:
            NysaCommError
            DMAError
        """
        if not enable:
            egress_inst_addr = 0

        elif egress_inst_addr is None:
            raise DMAError("Egress Address cannot be left blank!")

        if inst_addr > INSTRUCTION_COUNT - 1:
            raise DMAError("Specified instruction address out of range (%d > %d)" % (inst_addr, INSTRUCTION_COUNT))
        if egress_inst_addr > INSTRUCTION_COUNT - 1:
            raise DMAError("Specified egress address is out of range (%d > %d)" % (egress_inst_addr, INSTRUCTION_COUNT))
        r = self.read_register(INST_BASE + (INST_OFFSET * inst_addr) + INST_CNTRL)
        mask = BIT_INST_CMD_BOND_ADDR_OUT_TOP - BIT_INST_CMD_BOND_ADDR_OUT_BOT
        r &= ~mask
        r |= egress_inst_addr << BIT_INST_CMD_BOND_ADDR_OUT_BOT
        self.write_register(INST_BASE + (INST_OFFSET * inst_addr) + INST_CNTRL, r)

    def set_instruction_next_instruction(self, inst_addr, next_instruction):
        """
        Set Next Instruction

        Args:
            instr_addr (unsigned int): Address of instruction
        Returns:
            Nothing
        Raises:
            NysaCommError
            DMAError
        """
        if inst_addr > INSTRUCTION_COUNT - 1:
            raise DMAError("Specified instruction address out of range (%d > %d)" % (inst_addr, INSTRUCTION_COUNT))
        if next_instruction > INSTRUCTION_COUNT - 1:
            raise DMAError("Specified next address is out of range (%d > %d)" % (next_instruction, INSTRUCTION_COUNT))
        r = self.read_register(INST_BASE + (INST_OFFSET * inst_addr) + INST_CNTRL)
        mask = BIT_INST_CMD_NEXT_TOP - BIT_INST_CMD_NEXT_BOT
        r &= ~mask
        r |= next_instruction << BIT_INST_CMD_NEXT_BOT
        self.write_register(INST_BASE + (INST_OFFSET * inst_addr) + INST_CNTRL, r)

    def enable_instruction_continue(self, inst_addr, enable):
        """
        Enable Instruction Continue

        Args:
            instr_addr (unsigned int): Address of instruction
        Returns:
            Nothing
        Raises:
            NysaCommError
            DMAError
        """
        if inst_addr > INSTRUCTION_COUNT - 1:
            raise DMAError("Specified instruction address out of range (%d > %d)" % (inst_addr, INSTRUCTION_COUNT))
        self.enable_register_bit(INST_BASE + (INST_OFFSET * inst_addr) + INST_CNTRL, BIT_INST_CMD_CONTINUE, enable)

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
        if inst_addr > INSTRUCTION_COUNT - 1:
            raise DMAError("Specified instruction address out of range (%d > %d)" % (inst_addr, INSTRUCTION_COUNT))

