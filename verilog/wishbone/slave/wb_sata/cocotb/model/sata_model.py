# -*- coding: utf-8 -*-
#
# This file is part of Nysa (wiki.cospandesign.com/index.php?title=Nysa).
#
# Nysa is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# any later version.
#
# Nysa is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Nysa; If not, see <http://www.gnu.org/licenses/>.

from array import array as Array

import cocotb
import threading
from cocotb.triggers import Timer
from cocotb.triggers import Join
from cocotb.triggers import RisingEdge
from cocotb.triggers import ReadOnly
from cocotb.triggers import FallingEdge
from cocotb.triggers import ReadWrite
from cocotb.triggers import Event

from cocotb.result import ReturnValue
from cocotb.result import TestFailure
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb import bus
import json
import cocotb.monitors

from sim_host import NysaSim

CLK_PERIOD = 10
SATA_CLK_PERIOD = 16
RESET_PERIOD = 20



class SataSim (NysaSim):
    def __init__(self, dut):
        super(SataSim, self).__init__(dut)
        cocotb.fork(Clock(dut.sata_clk, SATA_CLK_PERIOD).start())

    @cocotb.coroutine
    def wait_for_sata_ready(self):
        
        while not self.dut.hd_ready.value.get_value():
            yield(self.wait_clocks(1)) 

        self.dut.log.info("SATA Stack Ready")
        yield(self.wait_clocks(100)) 

