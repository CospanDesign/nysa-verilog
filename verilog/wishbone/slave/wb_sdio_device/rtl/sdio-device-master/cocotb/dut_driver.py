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
SDB_ABI_VERSION_MINOR   = 1
SDB_VENDOR_ID           = 0x800000000000C594

#Register Constants
CONTROL_ADDR            = 0x00000000
ZERO_BIT                = 0

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

    def enable_control_0_bit(self, enable):
        self.enable_register_bit(CONTROL_ADDR, ZERO_BIT, enable)

    def is_control_0_bit_set(self):
        return self.is_register_bit_set(CONTROL_ADDR, ZERO_BIT)
