
import time

import cocotb
from cocotb.result import ReturnValue
from cocotb.drivers.amba import AXI4LiteMaster
from cocotb.triggers import Timer
from array import array as Array

#SIM = True
SIM = False

#Registers
REG_CONTROL                   =  0
REG_STATUS                    =  1
REG_USER_INPUT                =  2
REG_HCI_OPCODE_COUNT          =  3
REG_HCI_OPCODE_ADDR           =  4
REG_HCI_OPCODE                =  5
REG_HCI_OPCODE_DATA           =  6
REG_HCI_READ_STB              =  7
REG_IMAGE_WIDTH               =  8
REG_IMAGE_HEIGHT              =  9
REG_IMAGE_SIZE                = 10
REG_VERSION                   = 11

#Control
CONTROL_HCI_RESET             = 0
CONTROL_CONSOLE_RESET         = 1

#Status
STATUS_CLOCK_LOCKED           = 0
STATUS_HCI_READY              = 1
STATUS_HCI_NEW_STATUS         = 2
STATUS_HCI_S_BOT              = 16
STATUS_HCI_S_TOP              = STATUS_HCI_S_BOT + 15

# HCI Interface

# Debug packet opcodes.
OP_NOP                  = 0x00
OP_DBG_BRK              = 0x01
OP_DBG_RUN              = 0x02
OP_QUERY_DBG_BRK        = 0x03
OP_CPU_MEM_RD           = 0x04
OP_CPU_MEM_WR           = 0x05
OP_CPU_REG_RD           = 0x06
OP_CPU_REG_WR           = 0x07
OP_PPU_MEM_RD           = 0x08
OP_PPU_MEM_WR           = 0x09
OP_PPU_DISABLE          = 0x0A
OP_CART_SET_CFG         = 0x0B

# Opcode Status
OS_OK                   = 1
OS_ERROR                = 2
OS_UNKNOWN_OPCODE       = 4
OS_COUNT_IS_ZERO        = 8

# CPU Registers
CPU_REG_PCL             = 0x00  # PCL:  Program Counter Low
CPU_REG_PCH             = 0x01  # PCH:  Program Counter High
CPU_REG_AC              = 0x02  # AC:   Accumulator
CPU_REG_X               = 0x03  # X:    X index reg
CPU_REG_Y               = 0x04  # Y:    Y index reg
CPU_REG_P               = 0x05  # P:    Processor Status Reg
CPU_REG_S               = 0x06  # S:    Stack Pointer Reg

class NESError(Exception):
    pass

class NESHCI (object):

    def __init__(self, dut, BUS_NAME, clock_period = 10):
        self.dut = dut
        self.axim = AXI4LiteMaster(dut, BUS_NAME, dut.clk)
        self.clk_period = clock_period

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
    def enable_console_reset(self, enable):
        data = yield self._read_data(REG_CONTROL)
        data = int(data)
        yield Timer(self.clk_period * 1)
        if enable:
            data |= 1 << CONTROL_CONSOLE_RESET
        else:
            data &= ~(1 << CONTROL_CONSOLE_RESET)
        self._write_data(REG_CONTROL, data)

    @cocotb.coroutine
    def enable_hci_reset(self, enable):
        data = yield self._read_data(REG_CONTROL)
        data = int(data)
        yield Timer(self.clk_period * 1)
        if enable:
            data |= 1 << CONTROL_HCI_RESET
        else:
            data &= ~(1 << CONTROL_HCI_RESET)
        yield self._write_data(REG_CONTROL, data)

    @cocotb.coroutine
    def reset_hci(self):
        yield self.enable_hci_reset(True)
        yield Timer(self.clk_period * 10)
        yield self.enable_hci_reset(False)

    @cocotb.coroutine
    def reset_console(self):
        yield self.enable_console_reset(True)
        yield Timer(self.clk_period * 10)
        yield self.enable_console_reset(False)


    @cocotb.coroutine
    def enter_debug(self):
        '''
        put the device into debug mode
        '''
        yield self._write_data(REG_HCI_OPCODE, OP_DBG_BRK)

    @cocotb.coroutine
    def exit_debug(self):
        '''
        take the device out of debug mode
        '''
        yield self._write_data(REG_HCI_OPCODE, OP_DBG_RUN)

    @cocotb.coroutine
    def is_debug_enabled(self):
        yield self._write_data(REG_HCI_OPCODE, OP_QUERY_DBG_BRK)
        data = yield self._read_data(REG_STATUS)
        data = int(data)
        status = data >> 16
        dbg_en = (status == OS_OK)
        raise ReturnValue(dbg_en)

    @cocotb.coroutine
    def nop(self):
        yield self._write_data(REG_HCI_OPCODE, OP_NOP)

    @cocotb.coroutine
    def write_cpu_register(self, reg_addr, value):
        yield self.enter_debug()
        yield self._write_data(REG_HCI_OPCODE_COUNT, 1)
        yield self._write_data(REG_HCI_OPCODE_ADDR, reg_addr)
        yield self._write_data(REG_HCI_OPCODE, OP_CPU_REG_WR)
        yield self._write_data(REG_HCI_OPCODE_DATA, value)
        yield self._write_data(REG_HCI_READ_STB, 0x01)

    @cocotb.coroutine
    def read_cpu_register(self, reg_addr):
        yield self.enter_debug()
        yield self._write_data(REG_HCI_OPCODE_COUNT, 1)
        yield self._write_data(REG_HCI_OPCODE_ADDR, reg_addr)
        yield self._write_data(REG_HCI_OPCODE, OP_CPU_REG_RD)
        yield self._write_data(REG_HCI_READ_STB, 0x01)
        data = yield self._read_data(REG_HCI_OPCODE_DATA)
        raise ReturnValue(int(data))


    @cocotb.coroutine
    def write_cpu_mem(self, addr, data):
        if data is int:
            data = [data]

        yield self.enter_debug()
        yield self._write_data(REG_HCI_OPCODE_COUNT, len(data))
        yield self._write_data(REG_HCI_OPCODE_ADDR, addr)
        yield self._write_data(REG_HCI_OPCODE, OP_CPU_MEM_WR)
        for d in data:
            yield self._write_data(REG_HCI_OPCODE_DATA, d)

    @cocotb.coroutine
    def read_cpu_mem(self, addr, length = 1):
        data = [0] * length
        yield self.enter_debug()
        yield self._write_data(REG_HCI_OPCODE_COUNT, length)
        yield self._write_data(REG_HCI_OPCODE_ADDR, addr)
        yield self._write_data(REG_HCI_OPCODE, OP_CPU_MEM_RD)
        for i in range(length):
            yield self._write_data(REG_HCI_READ_STB, 0x01)
            value = yield self._read_data(REG_HCI_OPCODE_DATA)
            data[i] = int(value)
            #print "%d" % int(value)
        raise ReturnValue(data)

    @cocotb.coroutine
    def write_ppu_mem(self, addr, data):
        if data is int:
            data = [data]

        yield self.enter_debug()
        yield self._write_data(REG_HCI_OPCODE_COUNT, len(data))
        yield self._write_data(REG_HCI_OPCODE_ADDR, addr)
        yield self._write_data(REG_HCI_OPCODE, OP_PPU_MEM_WR)
        for d in data:
            yield self._write_data(REG_HCI_OPCODE_DATA, d)

    @cocotb.coroutine
    def read_ppu_mem(self, addr, length = 1):
        data = [0] * length
        yield self.enter_debug()
        yield self._write_data(REG_HCI_OPCODE_COUNT, length)
        yield self._write_data(REG_HCI_OPCODE_ADDR, addr)
        yield self._write_data(REG_HCI_OPCODE, OP_PPU_MEM_RD)
        for i in range(length):
            yield self._write_data(REG_HCI_READ_STB, 0x01)
            value = yield self._read_data(REG_HCI_OPCODE_DATA)
            data[i] = int(value)
            #print "%d" % int(value)
        raise ReturnValue(data)

    @cocotb.coroutine
    def set_cart_config(self, data):
        """
        32-bit Cartridge Value
        """
        yield self.enter_debug()
        yield self._write_data(REG_HCI_OPCODE_COUNT, len(data))
        yield self._write_data(REG_HCI_OPCODE, OP_CART_SET_CFG)
        for d in data:
            yield self._write_data(REG_HCI_OPCODE_DATA, d)

    @cocotb.coroutine
    def disable_ppu(self):
        yield self.enter_debug()
        yield self._write_data(REG_HCI_OPCODE, OP_PPU_DISABLE)

    @cocotb.coroutine
    def load_rom(self, filename):
        f = open(filename, 'r')
        #data = f.read()
        data = Array('B')
        data.fromstring(f.read())
        print "Length of data: %d" % len(data)
        print "Type: %s" % str(type(data))
        f.close()
        #if ((data[0] != 'N') or (data[1] != 'E') or (data[2] != 'S') or (data[3] != 0x1A)):
        if ((data[0] != 0x4E) or (data[1] != 0x45) or (data[2] != 0x53) or (data[3] != 0x1A)):
            raise NESError("Invalid ROM header")


        prg_rom_banks = data[4]
        chr_rom_banks = data[5]
        if (prg_rom_banks > 2) or (chr_rom_banks > 1):
            raise NESError("Too many ROM banks: PRG_ROM: %d CHR ROM: %d" % (prg_rom_banks, chr_rom_banks))

        mapper = (((data[6] & 0xF0) >> 4) | ((data[7] & 0xF0)) != 0)
        if mapper != 0:
            raise NESError("Only mapper 0 is supported")

        # Issue a debug break
        yield self.enter_debug()

        #Disable PPU
        yield self.disable_ppu()

        #Set header info to config mapper
        config = [0] * 5
        config[0] = data[4]
        config[1] = data[5]
        config[2] = data[6]
        config[3] = data[7]
        config[4] = data[8]
        yield self.set_cart_config(config)

        #Calculate all the sizes
        prg_rom_size = prg_rom_banks * 0x4000
        chr_rom_size = chr_rom_banks * 0x2000
        total_size = prg_rom_size + chr_rom_size
        transfer_block_size = 0x400

        prg_rom = data[16:16 + prg_rom_size]
        chr_rom = data[16 + prg_rom_size: 16 + prg_rom_size + chr_rom_size]
        
        #XXX: SIMULATION Don't write too much data
        if SIM:
            load_prg_rom = prg_rom[0:256]
            load_chr_rom = prg_rom[0:256]

        prg_offset = 0x8000
        #Copy PRG ROM data
        if SIM:
            yield self.write_cpu_mem(prg_offset, load_prg_rom)
        else:
            yield self.write_cpu_mem(prg_offset, prg_rom)

        #Copy CHR ROM data
        #chr_offset = prg_offset + len(prg_rom)
        chr_offset = 0x00
        #yield self.write_cpu_mem(chr_offset, chr_rom)
        if SIM:
            yield self.write_ppu_mem(chr_offset, load_chr_rom)
        else:
            yield self.write_ppu_mem(chr_offset, chr_rom)

        #Update PC to point to the reset interrupt vector location
        pcl_val = data[16 + prg_rom_size - 4]
        pch_val = data[16 + prg_rom_size - 3]
        print "PCH:PCL: %02X:%02X" % (pch_val, pcl_val)

        yield self.write_cpu_register(CPU_REG_PCL, pcl_val) 
        yield self.write_cpu_register(CPU_REG_PCH, pch_val)

        #Issue a debug run command
        yield self.exit_debug()

