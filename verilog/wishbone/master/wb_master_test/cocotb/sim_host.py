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
from collections import OrderedDict
import cocotb.monitors
from ppfifo_bus import PPFIFOIngress
from ppfifo_bus import PPFIFOEgress

#from nysa.host.nysa import Nysa
from sim.sim import FauxNysa

from nysa.ibuilder.lib.gen_scripts.gen_sdb import GenSDB
from nysa.host.nysa import NysaCommError
from nysa.common.status import Status

CLK_PERIOD = 10
RESET_PERIOD = 20


def create_byte_array_from_dword(dword):
    d = Array('B')
    d.append((dword >> 24) & 0xFF)
    d.append((dword >> 16) & 0xFF)
    d.append((dword >>  8) & 0xFF)
    d.append((dword >>  0) & 0xFF)
    return d

def create_32bit_word(data_array, index):
    return (data_array[index] << 24) | (data_array[index + 1] << 16) | (data_array[index + 2] << 8) | (data_array[index + 3])

def create_thread(function, name, dut, args):
    new_thread = threading.Thread(group=None,
                                  target=hal_read,
                                  name=name,
                                  args=([function]),
                                  kwargs={})

    new_thread.start()
    dut.log.warning("Thread Started")
    return new_thread

class NysaSim (FauxNysa):

    @cocotb.coroutine
    def interrupt_interface(self):
        while(1):
            yield RisingEdge(self.dut.device_interrupt)
            #print "got interrupt... looking for callback"
            for key in self.callbacks:
                if self.callbacks[key] is not None:
                    #print "Found callback for: %s" % str(key)
                    for c in self.callbacks[key]:
                        c()

    def __init__(self, dut, sim_config, period = CLK_PERIOD, user_paths = []):
        self.status = Status()
        self.status.set_level('verbose')
        self.user_paths = user_paths
        self.comm_lock = cocotb.triggers.Lock('comm')
        self.dut                              = dut
        dev_dict                              = json.load(open(sim_config), object_pairs_hook = OrderedDict)
        super (NysaSim, self).__init__(dev_dict, self.status)

        self.timeout                          = 1000
        self.response                         = Array('B')

        self.dut.rst                          <= 0
        self.ingress = PPFIFOIngress(dut, "ingress", dut.clk)
        self.egress  = PPFIFOEgress (dut, "egress",  dut.clk)
        gd = GenSDB()
        self.callbacks = {}
        self.rom = gd.gen_rom(self.dev_dict, user_paths = self.user_paths, debug = False)

        cocotb.fork(Clock(dut.clk, period).start())
        cocotb.fork(self.interrupt_interface())

    @cocotb.coroutine
    def wait_clocks(self, num_clks):
        for i in range(num_clks):
            yield RisingEdge(self.dut.clk)

    def read_sdb(self):
        """read_sdb

        Read the contents of the DRT

        Args:
          Nothing

        Returns (Array of bytes):
          the raw DRT data, this can be ignored for normal operation

        Raises:
          Nothing
        """
        self.s.Verbose("entered")
        gd = GenSDB()
        self.rom = gd.gen_rom(self.dev_dict, user_paths = self.user_paths, debug = False)

        return self.nsm.read_sdb(self)

    def read(self, address, length = 1, disable_auto_inc = False):
        if (address * 4) + (length * 4) <= len(self.rom):
            length *= 4
            address *= 4

            ra = Array('B')
            for count in range (0, length, 4):
                ra.extend(self.rom[address + count :address + count + 4])
            #print "ra: %s" % str(ra)
            return ra

        mem_device = False
        if self.mem_addr is None:
            self.mem_addr = self.nsm.get_address_of_memory_bus()

        if address >= self.mem_addr:
            address = address - self.mem_addr
            mem_device = True

        self._read(address, length, mem_device)
        return self.response

    @cocotb.function
    def _read(self, address, length = 1, mem_device = False):
        yield(self.comm_lock.acquire())
        print "Reading"

        #print "_Read Acquire Lock"
        data_index = 0
        self.response = Array('B')
        yield( self.wait_clocks(10))

        data = Array('B')

        if mem_device:
            data.extend(create_byte_array_from_dword(0x00010002))
        else:
            data.extend(create_byte_array_from_dword(0x00000002))

        data.extend(create_byte_array_from_dword(length))
        data.extend(create_byte_array_from_dword(address))
        yield(self.ingress.write(data))
        yield(self.egress.read(length * 4))
        self.response = self.egress.get_data()
        self.comm_lock.release()
        raise ReturnValue(self.response)

    @cocotb.function
    def write(self, address, data = None, disable_auto_inc=False):
        print "Writing"
        mem_device = False
        write_data = Array('B')

        if self.mem_addr is None:
            self.mem_addr = self.nsm.get_address_of_memory_bus()

        if address >= self.mem_addr:
            address = address - self.mem_addr
            write_data.extend(create_byte_array_from_dword(0x00010001))
        else:
            write_data.extend(create_byte_array_from_dword(0x00000001))

        while (len(data) % 4) != 0:
            data.append(0)

        data_count = len(data) / 4

        write_data.extend(create_byte_array_from_dword(data_count))
        write_data.extend(create_byte_array_from_dword(address))
        write_data.extend(data)

        if data_count == 0:
            raise NysaCommError("Length of data to write is 0!")
        data_index          = 0
        timeout_count       = 0

        yield(self.comm_lock.acquire())
        #while data_index < data_count:
        yield(self.ingress.write(write_data))
        self.comm_lock.release()

    def wait_for_interrupts(self, wait_time = 1):
        self._wait_for_interrupts(wait_time)
        return False

    @cocotb.function
    def _wait_for_interrupts(self, wait_time = 1):
        wait_time = wait_time * 100
        count = 0
        self.interrupt_good = False
        while count < wait_time:
            #print "wait...",
            yield (self.wait_clocks(10))
            #print ".",
            count += 1
            if self.dut.device_interrupt.value.get_value():
                self.interrupt_good = True
                break

        #print "good? %s" % str(self.interrupt_good)

    @cocotb.coroutine
    def dump_core(self):
        pass

    @cocotb.coroutine
    def reset(self):
        yield(self.comm_lock.acquire())
        #print "Reset Acquired Lock"
        yield(self.wait_clocks(RESET_PERIOD / 2))

        self.dut.rst            <= 1
        yield(self.wait_clocks(RESET_PERIOD / 2))
        self.dut.rst            <= 0
        yield(self.wait_clocks(RESET_PERIOD / 2))
        yield( self.wait_clocks(10))
        self.comm_lock.release()
        #print "Reset Release Lock"

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

        timeout_count       =  0

        while timeout_count < self.timeout:
            yield RisingEdge(self.dut.clk)
            timeout_count   += 1
            yield ReadOnly()
            #if self.dut.out_en.value.get_value() == 0:
            #   continue
            #else:
            #    break
            break

        if timeout_count == self.timeout:
            self.dut.log.error("Timed out while waiting for master to respond")
            return
        self.dut.log.info("Master Responded to ping")
        self.dut.log.info("\t0x%08X" % self.out_status.value.get_value())

    def register_interrupt_callback(self, index, callback):
        if index not in self.callbacks:
            self.callbacks[index] = []
        self.callbacks[index].append(callback)

    def unregister_interrupt_callback(self, index, callback = None):
        if callback is None:
            self.callbacks[index] = None
        elif index in self.callbacks:
            i = self.callbacks[index].index(callback)
            del self.callbacks[index][i]

    def get_sdb_base_address(self):
        return 0x0

    def get_board_name(self):
        return "Cocotb"

    def upload(self, filepath):
        pass

    def program(self):
        pass


