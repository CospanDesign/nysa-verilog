#!/usr/bin/env python

import unittest
import json
import sys
import os
import time
from array import array as Array

sys.path.append(os.path.join(os.path.dirname(__file__),
                             os.pardir,
                             os.pardir))

from nysa.common.status import Status
from nysa.host.driver.utils import *
from nysa.host.driver.logic_analyzer import LogicAnalyzer
from nysa.host.driver.logic_analyzer import *

from nysa.host.platform_scanner import PlatformScanner

DRIVER = LogicAnalyzer

def create_inc_buf(count):
    buf = Array('B')
    for i in range(count):
        buf.append(i % 256)
    return buf

def create_empty_buf(count):
    buf = Array('B')
    for i in range(count):
        buf.append(0x00)
    return buf


class Test (unittest.TestCase):

    def setUp(self):
        self.s = Status()
        plat = ["", None, None]
        pscanner = PlatformScanner()
        platform_dict = pscanner.get_platforms()
        platform_names = platform_dict.keys()

        if "sim" in platform_names:
            #If sim is in the platforms, move it to the end
            platform_names.remove("sim")
            platform_names.append("sim")
        urn = None
        for platform_name in platform_names:
            if plat[1] is not None:
                break

            self.s.Debug("Platform: %s" % str(platform_name))

            platform_instance = platform_dict[platform_name](self.s)
            #self.s.Verbose("Platform Instance: %s" % str(platform_instance))

            instances_dict = platform_instance.scan()

            for name in instances_dict:

                #s.Verbose("Found Platform Item: %s" % str(platform_item))
                n = instances_dict[name]
                plat = ["", None, None]

                if n is not None:
                    self.s.Important("Found a nysa instance: %s" % name)
                    n.read_sdb()
                    #import pdb; pdb.set_trace()
                    if n.is_device_in_platform(DRIVER):
                        plat = [platform_name, name, n]
                        break
                    continue

                #self.s.Verbose("\t%s" % psi)

        if plat[1] is None:
            self.driver = None
            return
        n = plat[2]
        self.n = n
        pcie_urn = n.find_device(DRIVER)[0]
        self.driver = DRIVER(n, pcie_urn)
        self.s.set_level("verbose")

        self.s.Info("Using Platform: %s" % plat[0])
        self.s.Info("Instantiated a PCIE Device Device: %s" % pcie_urn)

    def test_device(self):
        #print "Is enabled: %s" % self.driver.is_enabled()
        self.driver.enable(False)
        #self.driver.set_trigger         (0x00000020)
        #self.driver.set_trigger_mask    (0x00000020)
        #self.driver.set_trigger_edge    (0xFFFFFFFF)

        #self.driver.set_trigger         (0x00200000)
        #self.driver.set_trigger_mask    (0x01E00000)
        #self.driver.set_trigger_edge    (0xFFFFFFFF)
 
        #self.driver.set_trigger_after   (0x00000100)
        #self.driver.set_trigger_after   (0x00000000)
        self.driver.enable(True)
        self.driver.force_trigger()
        while not self.driver.is_finished():
            print "Waiting..."
            time.sleep(0.5)
            
        print "Is Finished: %s" % self.driver.is_finished()
        data = self.driver.read_data()
        clock_rate = self.driver.get_clock_rate()
        buf = create_vcd_buffer(data, count = 32, clock_count = clock_rate, add_clock = True)
        f = open('f.vcd', 'wb')
        f.write(buf)
        f.close()
        #self.driver.enable(False)
        #print "Is Finished: %s" % self.driver.is_finished()


if __name__ == "__main__":
    unittest.main()

