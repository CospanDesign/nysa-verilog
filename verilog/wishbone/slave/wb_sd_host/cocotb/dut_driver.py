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
DEVICE_TYPE             = "SD Host"
SDB_ABI_VERSION_MINOR   = 1
SDB_VENDOR_ID           = 0x800000000000C594

#Register Constants
ZERO_BIT                = 0



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
SD_RESPOSNE1                = 10
SD_RESPONSE2                = 11
SD_RESPONSE3                = 12
SD_RESPONSE4                = 13

COMMAND_BIT_GO              = 16
COMMAND_BIT_RSP_LONG_FLG    = 17
 
CONFIGURE_EN_CRC            = 4

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

    def set_control(self, control):
        self.write_register(CONTROL, control)

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

    def send_command(self, cmd, cmd_arg, long_rsp = False, timeout = 0):
        #Generate a command bit command
        self.write_register(SD_ARGUMENT, cmd_arg)
        cmd_reg = 0
        if (long_rsp):
            cmd_rsp |= (1 << COMMAND_BIT_RSP_LONG_FLG)

        cmd_reg |= (1 << COMMAND_BIT_GO)
        cmd_reg |= cmd
        print "cmd reg: 0x%08X" % cmd_reg

        self.write_register(SD_ARGUMENT, cmd_arg)
        self.write_register(SD_COMMAND, cmd_reg)
        #TODO Implement timeout
