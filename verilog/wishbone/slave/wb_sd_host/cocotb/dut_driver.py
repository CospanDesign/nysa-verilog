#PUT LICENCE HERE!

"""
wb_sd_host Driver

"""

import sys
import os
import time
from array import array as Array

sys.path.append(os.path.join(os.path.dirname(__file__),
                             os.pardir))

from nysa.host.driver import driver

#Sub Module ID
#Use 'nysa devices' to get a list of different available devices
DEVICE_TYPE                 = "SD Host"
SDB_ABI_VERSION_MINOR       = 1
SDB_VENDOR_ID               = 0x800000000000C594

#Register Constants
ZERO_BIT                    = 0



CONTROL                     = 0
STATUS                      = 1
REG_MEM_0_BASE              = 2
REG_MEM_0_SIZE              = 3
REG_MEM_1_BASE              = 4
REG_MEM_1_SIZE              = 5
SD_ARGUMENT                 = 6
SD_COMMAND                  = 7
SD_CONFIGURE                = 8
SD_RESPONSE0                = 9
SD_RESPONSE1                = 10
SD_RESPONSE2                = 11
SD_RESPONSE3                = 12
SD_DATA_BYTE_COUNT          = 13

CONTROL_ENABLE_SD           = 0
CONTROL_ENABLE_INTERRUPT    = 1
CONTROL_ENABLE_DMA_WR       = 2
CONTROL_ENABLE_DMA_RD       = 3
CONTROL_ENABLE_SD_FIN_INT   = 4
CONTROL_DATA_WRITE_FLAG     = 5
CONTROL_DATA_BIT_ACTIVATE   = 6

COMMAND_BIT_GO              = 16
COMMAND_BIT_RSP_LONG_FLG    = 17

CONFIGURE_EN_CRC            = 4

CMD_PHY_MODE                = 0
CMD_SEND_RELATIVE_ADDR      = 3
CMD_OP_COND                 = 5
CMD_SEL_DESEL_CARD          = 7
CMD_GO_INACTIVE             = 15
CMD_SINGLE_DATA_RW          = 52
CMD_DATA_RW                 = 53

DATA_RW_WRITE               = 1
DATA_RW_READ                = 0
DATA_RW_FLAG                = 31
DATA_FUNC_INDEX             = 28
DATA_FUNC_BITMASK           = 7
DATA_ADDR                   = 9
DATA_ADDR_BITMASK           = 0x1FFFF
DATA_MASK                   = 0xFF

DATA_RW_BLOCK_MODE          = 27
DATA_RW_OP_CODE             = 26
DATA_RW_COUNT_BITMODE       = 0x1FF


OP_COND_BIT_EN_1P8V         = 24
OP_COND_BIT_OCR_LOW         = 8

STATUS_MEMORY_0_FINISHED    = 0
STATUS_MEMORY_1_FINISHED    = 1
STATUS_MEMORY_0_EMPTY       = 2
STATUS_MEMORY_1_EMPTY       = 3
STATUS_ENABLE               = 4
STATUS_SD_BUSY              = 5
STATUS_ERROR_BIT_TOP        = 31
STATUS_ERROR_BIT_BOT        = 24


R1_OUT_OF_RANGE             = 39
R1_COM_CRC_ERROR            = 38
R1_ILLEGAL_COMMAND          = 37
R1_ERROR                    = 19
R1_CURRENT_STATE            = 9
R1_CURRENT_STATE_BITMASK    = 0xF

R4_READY                    = 31
R4_NUM_FUNCS                = 28
R4_NUM_FUNCS_BITMASK        = 0x7
R4_MEM_PRESENT              = 27
R4_UHSII_AVAILABLE          = 26
R4_S18A                     = 24
R4_IO_OCR                   = 0
R4_IO_OCR_BITMASK           = 0xFFF

R5_COM_CRC_ERROR            = 15
R5_ILLEGAL_COMMAND          = 14
R5_CURRENT_STATE            = 12
R5_CURRENT_STATE_BITMASK    = 3
R5_ERROR                    = 3
R5_ERROR_FUNC               = 1
R5_ERROR_OUT_OF_RANGE       = 0

R6_REL_ADDR_BITMASK         = 0xFF
R6_REL_ADDR                 = 16
R6_STS_CRC_COMM_ERR         = 15
R6_STS_ILLEGAL_CMD          = 13
R6_STS_ERROR                = 12

RESPONSE_DICT = {CMD_PHY_MODE           : 1,
                 CMD_SEND_RELATIVE_ADDR : 6,
                 CMD_OP_COND            : 4,
                 CMD_SEL_DESEL_CARD     : 1,
                 CMD_GO_INACTIVE        : None,
                 CMD_SINGLE_DATA_RW     : 5,
                 CMD_DATA_RW            : 5}
                



class SDHostException(Exception):
    pass


class wb_sd_hostDriver(driver.Driver):

    """ wb_sd_host

        Communication with a DutDriver wb_sd_host Core
    """


    @staticmethod
    def get_abi_class():
        return 0

    @staticmethod
    def get_abi_major():
        return driver.get_device_id_from_name(DEVICE_TYPE)

    @staticmethod
    def get_abi_minor():
        return SDB_ABI_VERSION_MINOR

    @staticmethod
    def get_vendor_id():
        return SDB_VENDOR_ID

    def __init__(self, nysa, urn, debug = False):
        super(wb_sd_hostDriver, self).__init__(nysa, urn, debug)
        size = 2048
        self.MEM_BASE_0 = 0x000
        self.MEM_BASE_1 = self.MEM_BASE_0 + size
        self.set_register_bit(CONTROL, CONTROL_DATA_WRITE_FLAG)
        self.dma_reader = driver.DMAReadController(device     = self,
                                            mem_base0  = self.MEM_BASE_0,
                                            mem_base1  = self.MEM_BASE_1,
                                            size       = self.MEM_BASE_1 - self.MEM_BASE_0,
                                            reg_status = STATUS,
                                            reg_base0  = REG_MEM_0_BASE,
                                            reg_size0  = REG_MEM_0_SIZE,
                                            reg_base1  = REG_MEM_1_BASE,
                                            reg_size1  = REG_MEM_1_SIZE,
                                            timeout    = 3,
                                            finished0  = STATUS_MEMORY_0_FINISHED,
                                            finished1  = STATUS_MEMORY_1_FINISHED,
                                            empty0     = STATUS_MEMORY_0_EMPTY,
                                            empty1     = STATUS_MEMORY_1_EMPTY)

        self.dma_writer = driver.DMAWriteController(device     = self,
                                            mem_base0  = self.MEM_BASE_0,
                                            #mem_base1  = 0x00100000,
                                            mem_base1  = self.MEM_BASE_1,
                                            size       = self.MEM_BASE_1 - self.MEM_BASE_0,
                                            reg_status = STATUS,
                                            reg_base0  = REG_MEM_0_BASE,
                                            reg_size0  = REG_MEM_0_SIZE,
                                            reg_base1  = REG_MEM_1_BASE,
                                            reg_size1  = REG_MEM_1_SIZE,
                                            timeout    = 3,
                                            empty0     = STATUS_MEMORY_0_EMPTY,
                                            empty1     = STATUS_MEMORY_1_EMPTY)

        self.func_block_size = {}
        self.func_block_size[0] = 0
        self.func_block_size[1] = 0
        self.func_block_size[2] = 0
        self.func_block_size[3] = 0
        self.func_block_size[4] = 0
        self.func_block_size[5] = 0
        self.func_block_size[6] = 0
        self.func_block_size[7] = 0

        #Error Conditions
        self.error_crc = False
        self.error_illegal_cmd = False
        self.error_unknown = False
        self.error_out_of_range = False
        self.current_state = 0
        self.error_func = 0

        self.relative_card_address = 0x00
        self.voltage_range = {}
        self.voltage_range[20] = False
        self.voltage_range[21] = False
        self.voltage_range[22] = False
        self.voltage_range[23] = False
        self.voltage_range[24] = False
        self.voltage_range[25] = False
        self.voltage_range[26] = False
        self.voltage_range[27] = False
        self.voltage_range[28] = False
        self.voltage_range[29] = False
        self.voltage_range[30] = False
        self.voltage_range[31] = False
        self.voltage_range[32] = False
        self.voltage_range[33] = False
        self.voltage_range[34] = False
        self.voltage_range[35] = False

        self.card_voltage_range = {}
        self.card_voltage_range[20] = False
        self.card_voltage_range[21] = False
        self.card_voltage_range[22] = False
        self.card_voltage_range[23] = False
        self.card_voltage_range[24] = False
        self.card_voltage_range[25] = False
        self.card_voltage_range[26] = False
        self.card_voltage_range[27] = False
        self.card_voltage_range[28] = False
        self.card_voltage_range[29] = False
        self.card_voltage_range[30] = False
        self.card_voltage_range[31] = False
        self.card_voltage_range[32] = False
        self.card_voltage_range[33] = False
        self.card_voltage_range[34] = False
        self.card_voltage_range[35] = False

        self.set_voltage_range(2.0, 3.6)
        self.relative_card_address = 0x00
        self.inactive = False

#Low Level Functions
    def set_control(self, control):
        self.write_register(CONTROL, control)

    def enable_sd_host(self, enable):
        self.enable_register_bit(CONTROL, CONTROL_ENABLE_SD, enable)

    def enable_crc(self, enable):
        self.write_register_bit(SD_CONFIGURE, CONFIGURE_EN_CRC, enable)

    def is_crc_enabled(self):
        return self.is_register_bit_set(SD_CONFIGURE, CONFIGURE_EN_CRC)

    def get_control(self):
        return self.read_register(CONTROL)

    def get_status(self):
        return self.read_register(STATUS)

    def enable_control_0_bit(self, enable):
        self.enable_register_bit(CONTROL, ZERO_BIT, enable)

    def is_control_0_bit_set(self):
        return self.is_register_bit_set(CONTROL, ZERO_BIT)

    def send_command(self, cmd, cmd_arg = 0x00, long_rsp = False, timeout = 0.2):
        #Generate a command bit command
        cmd_reg = 0

        if (long_rsp):
            cmd_reg |= (1 << COMMAND_BIT_RSP_LONG_FLG)

        cmd_reg |= (1 << COMMAND_BIT_GO)
        cmd_reg |= cmd
        #print "cmd reg: 0x%08X" % cmd_reg

        self.write_register(SD_ARGUMENT, cmd_arg)
        self.write_register(SD_COMMAND, cmd_reg)
        to = time.time() + timeout
        while (time.time() < to) and self.is_sd_busy():
            print ".",
        print ""
        if self.is_sd_busy():
            print "Cancel command"
            cmd_reg &= (1 << COMMAND_BIT_GO)
            self.write_register(SD_COMMAND, cmd_reg)
            raise SDHostException("Timeout when sending command: 0x%02X" % cmd)

        response_index = RESPONSE_DICT[cmd]
        if response_index is None:
            return
        resp = self.read_response()
        self.parse_response(response_index, resp)

    def get_status(self):
        return self.read_register(STATUS)

    def is_sd_busy(self):
        return self.is_register_bit_set(STATUS, STATUS_SD_BUSY)

#Responses
    def read_response(self):
        resp = [0, 0, 0, 0, 0]
        resp[0] = self.read_register(SD_RESPONSE0)
        resp[1] = self.read_register(SD_RESPONSE1)
        resp[2] = self.read_register(SD_RESPONSE2)
        resp[3] = self.read_register(SD_RESPONSE3)
        return resp

    def parse_response(self, response_index, response):
        self.error_crc = 0
        self.error_out_of_range = 0
        if response_index == 1:
            self.parse_r1_resp(response)
        elif response_index == 2:
            raise SDHostException("R2 Response is not finished")
        elif response_index == 3:
            raise SDHostException("R3 Response is not finished")
        elif response_index == 4:
            self.parse_r4_resp(response)
        elif response_index == 5:
            self.parse_r5_resp(response)
        elif response_index == 6:
            self.parse_r6_resp(response)
        elif response_index == 7:
            self.parse_r7_resp(response)

    def parse_r1_resp(self, response):
        self.error_crc          =   ((response[3] & 1 << R1_COM_CRC_ERROR) > 0     )
        self.error_out_of_range =   ((response[3] & 1 << R1_OUT_OF_RANGE) > 0      )
        self.error_illegal_cmd  =   ((response[3] & 1 << R1_ILLEGAL_COMMAND) > 0   )
        self.error_unknown      =   ((response[3] & 1 << R1_ERROR) > 0             )
        self.current_state      =   ((response[3] >> R1_CURRENT_STATE) & R1_CURRENT_STATE_BITMASK)
        print "CRC Error: %s" % str(self.error_crc)
        print "Out of range Error: %s" % str(self.error_out_of_range)
        print "Illegal Command: %s" % str(self.error_illegal_cmd)
        print "Unknown Error %s" % str(self.error_unknown)
        print "Current State: %d" % self.current_state

    def parse_r4_resp(self, response):
        self.card_ready         =   ((response[3] & (1 << (R4_READY))) > 0)
        self.num_funcs          =   ((response[3] >>(R4_NUM_FUNCS)) & R4_NUM_FUNCS_BITMASK)
        self.v1p8_mode          =   ((response[3] & (1 << (R4_S18A) )) > 0)
        self.memory_present     =   ((response[3] & (1 << (R4_MEM_PRESENT))) > 0)
        vmin = 20
        vmax = 35
        pos = 8
        for i in range (vmin, vmax, 1):
            self.card_voltage_range[i] = ((response[3] & (1 << R4_IO_OCR + pos)) > 0)
            pos += 1

        #print "card ready: %s" % str(self.card_ready)
        #print "memory present: %s" % str(self.memory_present)
        #print "num funcs: %d" % self.num_funcs
        #print "1.8V Mode: %s" % self.v1p8_mode
        #print "IO Range:"
        #for i in range (vmin, vmax, 1):
        #    print "\t%d: %s" % (i, self.card_voltage_range[i])

    def parse_r5_resp(self, response):
        self.error_crc          =   ((response[3] & 1 << R5_COM_CRC_ERROR) > 0)
        self.error_illegal_cmd  =   ((response[3] & 1 << R5_ILLEGAL_COMMAND) > 0)
        self.current_state      =   ((response[3] >> R5_CURRENT_STATE) & R5_CURRENT_STATE_BITMASK)
        self.error_unknown      =   ((response[3] & 1 << R5_ERROR) > 0)
        self.error_function     =   ((response[3] & 1 << R5_ERROR_FUNC) > 0)
        self.error_out_of_range =   ((response[3] & 1 << R5_ERROR_OUT_OF_RANGE) > 0)
        self.read_data_byte     =   (response[3] & DATA_MASK)

    def parse_r6_resp(self, response):
        self.relative_card_address = ((response[3] >> R6_REL_ADDR) & R6_REL_ADDR_BITMASK)
        self.error_crc = (response[3] & (1 << R6_STS_CRC_COMM_ERR) > 0)
        self.error_illegal_cmd = (response[3] & (1 << R6_STS_ILLEGAL_CMD) > 0)
        self.error_unknown = (response[3] & (1 << R6_STS_ERROR) > 0)
        #print "Relative Address: 0x%04X" % self.relative_card_address
        #print "CRC Error: %s" % str(self.error_crc)
        #print "Illegal Command: %s" % str(self.error_illegal_cmd)
        #print "Unknown Error %s" % str(self.error_unknown)

    def parse_r7_resp(self, response):
        pass

    def set_voltage_range(self, vmin = 2.0, vmax = 3.6):
        #print "Voltage Range: %f - %f" % (vmin, vmax)
        if vmin >= vmax:
            raise SDHostException("Vmin is greater than Vmax")

        for key in self.voltage_range.keys():
            self.voltage_range[key] = False

        vmin = int(vmin * 10)
        vmax = int(vmax * 10)
        #print "Voltage Range: %d - %d" % (vmin, vmax)

        vmin_range = 20
        vmax_range = 35
        fval = vmin_range
        while (fval < vmax_range + 1):
            #print "fval: %d" % fval
            if fval >= vmax:
                #print "\tDone!"
                break
            if fval < vmin:
                #print "vmin < fval: %d < %d" % (vmin, fval)
                fval = fval + 1
                continue

            self.voltage_range[fval] = True
            fval += 1

        #print "dict: %s" % str(self.voltage_range)
        #print "voltage:"
        vmin_range = 20
        vmax_range = 35
        fval = vmin_range
        while (fval < vmax_range + 1):
            #print "\t%d: %s" % (fval, self.voltage_range[fval])
            fval += 1

# Commands
    def cmd_phy_sel(self, spi_mode = False):
        try:
            self.send_command(CMD_PHY_MODE)
        except SDHostException:
            print "No Response"
            return
            pass

    def cmd_io_send_op_cond(self, enable_1p8v):
        command_arg = 0x00
        if enable_1p8v:
            command_arg |=  1 << OP_COND_BIT_EN_1P8V
        pos = OP_COND_BIT_OCR_LOW
        for i in range (20, 36, 1):
            if (self.voltage_range[i]):
                command_arg |= 1 << pos
            pos += 1

        self.send_command(CMD_OP_COND, command_arg)

    def cmd_get_relative_card_address(self):
        command_arg = 0x00

        self.send_command(CMD_SEND_RELATIVE_ADDR)

    def cmd_enable_card(self, select_enable):
        if self.relative_card_address == 0:
            print "Card Select/Deslect is not configured yet!"
            print "Calling card config to get an address"
            self.cmd_get_relative_card_address()
        command_arg = 0x00
        if select_enable:
            command_arg |= self.relative_card_address << R6_REL_ADDR

        try:
            self.send_command(CMD_SEL_DESEL_CARD, command_arg)
        except SDHostException:
            return

    def cmd_go_inactive_state(self):
        try:
            self.send_command(CMD_GO_INACTIVE)
        except SDHostException:
            pass

        self.inactive = True
        print "Inactive State, reset to continue"

    def write_config_byte(self, address, data, read_after_write = False):
        data = [data]
        return self.write_sd_data(function_id = 0,
                              address = address,
                              data = data,
                              read_after_write = read_after_write)

    def read_config_byte(self, address):
        return self.read_sd_data(function_id = 0,
                                address = address)

    def write_sd_data(self, function_id, address, data, fifo_mode = False, read_after_write = False):
        if len(data) == 1:
            #This seems overly complicated but I chose to add this to exercise the SDIO Device Core
            return self.rw_byte(True, function_id, address, data[0], read_after_write)

        if  self.func_block_size[function_id] == 0 or               \
            ( len(data) <= self.func_block_size[function_id] and    \
              len(data) <= 512):

            #Block mode
            print "Go to write multiple bytes"
            return self.rw_multiple_bytes(True, function_id, address, data, fifo_mode)

        return self.rw_block(True, function_id, address, data, byte_count = 0, fifo_mode = fifo_mode)

    def read_sd_data(self, function_id, address, byte_count = 1, fifo_mode = False):
        if byte_count == 1:
            return self.rw_byte(False, function_id, address, [0], False)

        if (self.func_block_size[function_id] == 0) or (byte_count < self.func_block_size[function_id]):
            return self.rw_multiple_bytes(rw_flag = False,
                                          function_id = function_id,
                                          address = address,
                                          data = [0],
                                          byte_count = byte_count,
                                          fifo_mode = fifo_mode)

        raise Exception("Not implemented yet")
        #return self.rw_block(False, function_id, address, data, fifo_mode)

    def rw_byte(self, rw_flag, function_id, address, data, read_after_write):
        command_arg = 0
        if rw_flag:
            command_arg |= (1 << DATA_RW_FLAG)
            command_arg |= (data & DATA_MASK)
        command_arg |= ((function_id & DATA_FUNC_BITMASK) << DATA_FUNC_INDEX)
        command_arg |= ((address & DATA_ADDR_BITMASK) << DATA_ADDR)
        self.send_command(CMD_SINGLE_DATA_RW, command_arg)
        return self.read_data_byte

    def rw_multiple_bytes(self, rw_flag, function_id, address, data, fifo_mode, byte_count = 1, timeout = 0.2):
        command_arg = 0
        command_arg |= ((function_id & DATA_FUNC_BITMASK) << DATA_FUNC_INDEX)
        command_arg |= ((address & DATA_ADDR_BITMASK) << DATA_ADDR)

        if not fifo_mode:
            print "Increment Address!"
            command_arg |= (1 << DATA_RW_OP_CODE)

        if rw_flag:
            self.dma_writer.set_size(512)
            command_arg |= (1 << DATA_RW_FLAG)
            command_arg |= (len(data) & DATA_RW_COUNT_BITMODE)

            self.send_command(CMD_DATA_RW, command_arg)

            print "Initiate Data Transfer (Outbound)"
            self.write_memory(self.MEM_BASE_0, data)
            self.set_register_bit(CONTROL, CONTROL_DATA_WRITE_FLAG)
            self.set_register_bit(CONTROL, CONTROL_ENABLE_DMA_WR)
            #Initiate transfer from memory to FIFO
            self.write_register(REG_MEM_0_SIZE, len(data) / 4)
            self.write_register(SD_DATA_BYTE_COUNT, len(data))
            #time.sleep(0.1)
            self.set_register_bit(CONTROL, CONTROL_DATA_BIT_ACTIVATE)
            to = time.time() + timeout
            while (time.time() < to) and self.is_sd_busy():
                print ".",
            print ""
            #Disable the DMA Write Flag
            print "Waiting till data has finished sending..."
            to = time.time() + timeout
            while (time.time() < to) and (self.dma_writer.get_available_memory_blocks() != 3):
                print "This should change to an asynchrounous Wait"
                time.sleep(0.01)

            self.clear_register_bit(CONTROL, CONTROL_ENABLE_DMA_WR)

        else:
            print "Initiate Data Transfer (Inbound)"
            self.dma_reader.set_size(512)
            command_arg |= (byte_count & DATA_RW_COUNT_BITMODE)

            self.clear_register_bit(CONTROL, CONTROL_DATA_WRITE_FLAG)
            self.set_register_bit(CONTROL, CONTROL_ENABLE_DMA_RD)
            self.set_register_bit(CONTROL, CONTROL_DATA_BIT_ACTIVATE)
            self.write_register(SD_DATA_BYTE_COUNT, byte_count)
            self.write_register(REG_MEM_0_SIZE, byte_count / 4)

            self.send_command(CMD_DATA_RW, command_arg)
            word_count = byte_count / 4
            if word_count == 0:
                word_count = 1

            #Disable the DMA Write Flag
            self.clear_register_bit(CONTROL, CONTROL_ENABLE_DMA_RD)
            self.set_register_bit(CONTROL, CONTROL_DATA_WRITE_FLAG)

    def set_function_block_size(self, func_num, block_size):
        '''
        Sets the read/write block size for the specified function.
        When user performs a read/write command with the block mode set to true
        Then this value must be set. The value can be anything between 1 - 2048

        Users must not use block mode without setting this value!

        Args:
            func_num (Integer): Function between 0 - 7
            block_size (Integer): Size of block to read/write

        Returns:
            Nothing

        Raises:
            SDHostException:
                Value besides 1 - 2048 was given
        '''
        if func_num < 0:
            raise SDHostException("Only function number between 0 and 7 allowed: %d not valid" % func_num)

        if func_num > 7:
            raise SDHostException("Only function number between 0 and 7 allowed: %d not valid" % func_num)

        if block_size > 2048:
            raise SDHostException("Only values between 1 - 2048 allowed: %d not valid" % block_size)

        if block_size < 1:
            raise SDHostException("Only values between 1 - 2048 allowed: %d not valid" % block_size)

        address = 0x100 * func_num + 0x10

        lower_byte = block_size & 0xFF
        upper_byte = ((block_size >> 8) & 0xFF)
        self.write_config_byte(address, lower_byte)
        self.write_config_byte(address + 1, upper_byte)
        self.func_block_size[func_num] = block_size

    def rw_block(self, rw_flag, function_id, address, data, byte_count, fifo_mode, timeout = 0.2):
        print "RW Block"
        command_arg = 0
        command_arg |= ((function_id & DATA_FUNC_BITMASK) << DATA_FUNC_INDEX)
        command_arg |= ((address & DATA_ADDR_BITMASK) << DATA_ADDR)

        #Set Block Transfer Mode
        command_arg |= (1 << DATA_RW_BLOCK_MODE)

        if not fifo_mode:
            print "Increment Address!"
            command_arg |= (1 << DATA_RW_OP_CODE)


        if rw_flag:
            #Setup the DMA Read or Write Block Size
            self.dma_writer.set_size(self.func_block_size[function_id])
            command_arg |= (len(data) & DATA_RW_COUNT_BITMODE)
            command_arg |= (1 << DATA_RW_FLAG)
            self.send_command(CMD_DATA_RW, command_arg)
            print "Initiate Data Transfer (Outbound)"
            self.set_register_bit(CONTROL, CONTROL_ENABLE_DMA_WR)
            self.write_register(SD_DATA_BYTE_COUNT, len(data))
            self.set_register_bit(CONTROL, CONTROL_DATA_BIT_ACTIVATE)
            self.set_register_bit(CONTROL, CONTROL_ENABLE_INTERRUPT)
            self.dma_writer.write(data)

            to = time.time() + timeout
            while (time.time() < to) and (self.dma_writer.get_available_memory_blocks() != 3):
                print "This should change to an asynchrounous Wait"
                time.sleep(0.01)


            self.clear_register_bit(CONTROL, CONTROL_ENABLE_DMA_WR)
            self.clear_register_bit(CONTROL, CONTROL_ENABLE_INTERRUPT)

        else:
            self.dma_reader.set_size(self.func_block_size[function_id])
            command_arg |= (byte_count & DATA_RW_COUNT_BITMODE)
            self.send_command(CMD_DATA_RW, command_arg)
            self.write_register(SD_DATA_BYTE_COUNT, len(data))

    def send_single_byte(self, function_id, address, data, read_after_write):
        command_arg = 0
        write_flag = DATA_RW_FLAG
        cmd = CMD_SINGLE_DATA_RW

    def set_data_bus_dir_output(self, enable):
        self.enable_register_bit(CONTROL, CONTROL_DATA_WRITE_FLAG, enable)


