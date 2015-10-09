#PUT LICENCE HERE!

"""
wb_sdio_device Driver

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
DEVICE_TYPE             = "SDIO Device"
SDB_ABI_VERSION_MINOR   = 0x01
SDB_VENDOR_ID           = 0x800000000000C594

BUFFER_SIZE             = 0x00000400

#Register Constants
CONTROL_ADDR            = 0x00000000
STATUS_ADDR             = 0x00000001
BUFFER_OFFSET           = 0x00000400
ZERO_BIT                = 0

CNTRL_BIT_ENABLE            = 0
CNTRL_BIT_INTERRUPT         = 1
CNTRL_BIT_SEND_INTERRUPT    = 2


class wb_sdio_deviceDriver(driver.Driver):

    """ wb_sdio_device

        Communication with a DutDriver wb_sdio_device Core
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
        super(wb_sdio_deviceDriver, self).__init__(nysa, urn, debug)

    def set_control(self, control):
        self.write_register(CONTROL_ADDR, control)

    def get_control(self):
        return self.read_register(CONTROL_ADDR)

    def write_local_buffer(self, addr, data):
        #Make sure data is 32-bit Aligned
        data = Array('B', data)
        while len(data) % 4 > 0:
            data.append(0x00)

        self.write(BUFFER_OFFSET + addr, data)

    def read_local_buffer(self, addr, length):
        return self.read(BUFFER_OFFSET + addr, length)

    def enable_interrupt(self, enable):
        self.enable_register_bit(CONTROL_ADDR, CNTRL_BIT_INTERRUPT, enable)

    def is_interrupt_enable(self):
        return self.is_register_bit_set(CONTROL_ADDR, CNTRL_BIT_INTERRUPT)

    def enable_sdio_device(self, enable):
        self.enable_register_bit(CONTROL_ADDR, CNTRL_BIT_ENABLE, enable)

    def is_sdio_device_enabled(self):
        return self.is_register_bit_set(CONTROL_ADDR, CNTRL_BIT_ENABLE)

    def enable_interrupt_to_host(self, enable):
        self.enable_register_bit(CONTROL_ADDR, CNTRL_BIT_SEND_INTERRUPT, enable)

    def is_interrupt_to_host_enabled(self):
        return self.is_register_bit_set(CONTROL_ADDR, CNTRL_BIT_SEND_INTERRUPT)


