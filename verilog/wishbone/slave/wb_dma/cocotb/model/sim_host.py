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
from cocotb.triggers import Timer, Join, RisingEdge, ReadOnly, ReadWrite, ClockCycles
from cocotb.clock import Clock
from cocotb.result import ReturnValue, TestFailure
from cocotb.binary import BinaryValue
from cocotb import bus
import cocotb.monitors

from nysa.host.nysa import Nysa
from nysa.host.nysa import NysaCommError


def create_thread(function, name, dut, args):
    new_thread = threading.Thread(group=None,
                                  target=hal_read,
                                  name=name,
                                  args=([function]),
                                  kwargs={})

    new_thread.start()
    dut.log.warning("Thread Started")
    return new_thread


class NysaSim (Nysa):

    def __init__(self, dut, debug = False):
        self.period                           = 10
        self.reset_length                     = 40
        self.dut                              = dut
        super (NysaSim, self).__init__(debug)
        self.timeout                          = 1000
        self.response                         = Array('B')

        self.rst            <= 1
        self.rst            <= 0

        self.master_ready   = self.dut.sim_master_ready

        self.in_ready       = self.dut.top.ih_ready
        self.in_command     = self.dut.sim_in_command
        self.in_address     = self.dut.sim_in_address
        self.in_data        = self.dut.sim_in_data
        self.in_data_count  = self.dut.sim_in_data_count

        self.out_en         = self.dut.sim_out_en
        self.out_ready      = self.dut.sim_out_ready
        self.out_status     = self.dut.sim_out_status
        self.out_address    = self.dut.sim_out_address
        self.out_data       = self.dut.sim_out_data

        self.in_ready       <= 0
        self.out_ready      <= 0

        self.in_command     <= 0
        self.in_address     <= 0
        self.in_data        <= 0
        self.in_data_count  <= 0
        #yield ClockCycles(self.dut.clk, 10)

        self.dut.log.info("Clock Started")

    @cocotb.coroutine
    def read(self, address, length = 1, mem_device = False):
        self.dut.log.info("reading")
        data_index = 0
        self.in_ready       <= 0
        self.out_ready      <= 1
        yield ClockCycles(self.dut.clk, 100)

        self.response = Array('B')

        if (mem_device):
            self.in_command <= 0x00010002
            self.address    <= address
        else:
            self.in_command <= 0x00000002
            self.in_address <= address

        self.in_data_count  <= length
        self.in_data        <= 0

        yield ClockCycles(self.dut.clk, 1)
        self.in_ready       <= 1
        while data_index < length:
            timeout_count   =  0
            while timeout_count < self.timeout:
                yield RisingEdge(self.dut.clk)
                timeout_count   += 1
                yield ReadOnly()
                if self.out_en.value.get_value() == 0:
                    continue
                else:
                    break

            if timeout_count == self.timeout:
                self.dut.log.error("Timed out while waiting for master to respond")
                return

            data_index += 1
            #yield RisingEdge(self.dut.clk)
            #yield ReadOnly()
            value = self.out_data.value.get_value()
            print "%d Received: 0x%08X" % (data_index, value)
            self.response.append(0xFF & (value >> 24))
            self.response.append(0xFF & (value >> 16))
            self.response.append(0xFF & (value >> 8))
            self.response.append(0xFF & value)

        self.out_ready      <= 0

        raise ReturnValue(self.response)

    @cocotb.coroutine
    def _read(self, address, length = 1, mem_device = False):
        data_index = 0
        self.in_ready       <= 0
        self.out_ready      <= 1
        yield ClockCycles(self.dut.clk, 100)

        self.response = Array('B')

        self.address    <= address
        if (mem_device):
            self.in_command <= 0x00010002
        else:
            self.in_command <= 0x00000002

        self.in_data_count  <= length
        self.in_data        <= 0

        yield ClockCycles(self.dut.clk, 1)
        self.in_ready       <= 1
        while data_index < length:
            timeout_count   =  0
            while timeout_count < self.timeout:
                yield RisingEdge(self.dut.clk)
                timeout_count   += 1
                yield ReadOnly()
                if self.out_en.value.get_value() == 0:
                    continue
                else:
                    break

            if timeout_count == self.timeout:
                self.dut.log.error("Timed out while waiting for master to respond")
                return

            data_index += 1
            yield RisingEdge(self.dut.clk)
            yield ReadOnly()
            value = self.out_data.value.get_value()
            print "Received: 0x%08X" % value
            self.response.append(0xFF & (value >> 24))
            self.response.append(0xFF & (value >> 16))
            self.response.append(0xFF & (value >> 8))
            self.response.append(0xFF & value)

        self.out_ready      <= 0

    @cocotb.coroutine
    def write(self, address, data = None, mem_device = False):
        data_count = len(data)
        if data_count == 0:
            raise NysaCommError("Length of data to write is 0!")
        data_index          = 0
        timeout_count       = 0

        self.dut.log.info("Writing data")
        self.in_ready       <= 0
        self.out_ready      <= 1
        self.address        <= address
        if (mem_device):
            self.in_command <= 0x00010001
        else:
            self.in_command <= 0x00000001

        self.in_data_count  <=  len(data)


        yield ClockCycles(self.dut.clk, 1)
        self.in_ready       <= 1

        while data_index < data_count:
            self.in_data        <=  data[data_index]
            data_index          += 1
            timeout_count       =  0
            while timeout_count < self.timeout:
                yield RisingEdge(self.dut.clk)
                timeout_count   += 1
                yield ReadOnly()
                if self.master_ready.value.get_value() == 0:
                    continue
                else:
                    break
            if timeout_count == self.timeout:
                self.dut.log.error("Timed out while waiting for master to be ready")
                return

        timeout_count       =  0
        while timeout_count < self.timeout:
            yield RisingEdge(self.dut.clk)
            timeout_count   += 1
            yield ReadOnly()
            if self.out_en.value.get_value() == 0:
                continue
            else:
                break

        if timeout_count == self.timeout:
            self.dut.log.error("Timed out while waiting for master to respond")
            return

        self.in_ready       <= 0
        self.dut.log.info("Master Responded to write")
        self.dut.log.info("\t0x%08X" % self.out_status.value.get_value())

    @cocotb.coroutine
    def wait_for_interrupts(self, wait_time = 1):
        pass

    @cocotb.coroutine
    def dump_core(self):
        pass

    @cocotb.coroutine
    def reset(self):
        self.dut.log.info("Sending Reset to the bus")
        yield Timer (0)

        self.rst            <= 1
        yield ClockCycles(self.dut.clk, self.reset_length)
        #self.rst            <= 0
        self.in_ready       <= 0
        self.out_ready      <= 0

        self.in_command     <= 0
        self.in_address     <= 0
        self.in_data        <= 0
        self.in_data_count  <= 0

        self.rst            <= 0
        yield ClockCycles(self.dut.clk, self.reset_length)
        yield ClockCycles(self.dut.clk, self.reset_length)

    @cocotb.coroutine
    def ping(self):
        timeout_count       =  0

        while timeout_count < self.timeout:
            yield RisingEdge(self.dut.clk)
            timeout_count   += 1
            yield ReadOnly()
            if self.master_ready.value.get_value() == 0:
                continue
            else:
                break

        if timeout_count == self.timeout:
            self.dut.log.error("Timed out while waiting for master to be ready")
            return

        yield ReadWrite()
        self.in_ready       <=  1
        self.in_command     <=  0
        self.in_data        <=  0
        self.in_address     <=  0
        self.in_data_count  <=  0
        self.out_ready      <=  1

        timeout_count       =  0

        while timeout_count < self.timeout:
            yield RisingEdge(self.dut.clk)
            timeout_count   += 1
            yield ReadOnly()
            if self.out_en.value.get_value() == 0:
                continue
            else:
                break

        if timeout_count == self.timeout:
            self.dut.log.error("Timed out while waiting for master to respond")
            return
        self.in_ready       <= 0

        self.dut.log.info("Master Responded to ping")
        self.dut.log.info("\t0x%08X" % self.out_status.value.get_value())

    def register_interrupt_callback(self, index, callback):
        pass

    def unregister_interrupt_callback(self, index, callback = None):
        pass

    def get_sdb_base_address(self):
        return 0x0

    def get_board_name(self):
        return "Cocotb"

    def upload(self, filepath):
        pass

    def program(self):
        pass
