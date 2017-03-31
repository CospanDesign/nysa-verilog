import cocotb
from cocotb.triggers import RisingEdge, ReadOnly, Lock, Timer
from cocotb.drivers import BusDriver
from cocotb.result import ReturnValue
from cocotb.binary import BinaryValue

import binascii
import array


class VideoOutBusError(Exception):
    pass

class VideoOutBus(BusDriver):
    """
    Generate RGB Video Signals
    """

    _signals = [
        "RGB",
        "HSYNC",
        "VSYNC",
        "DATA_EN",
        "HBLANK",
        "VBLANK"
    ]

    def __init__(self, entity, name, clock, width, height, hblank, vblank):
        BusDriver.__init__(self, entity, name, clock)

        #Drive some sensible defaults
        self.bus.RGB.setimmediatevalue(0)
        self.bus.HSYNC.setimmediatevalue(0)
        self.bus.VSYNC.setimmediatevalue(0)
        self.bus.DATA_EN.setimmediatevalue(0)

        self.bus.HBLANK.setimmediatevalue(1)
        self.bus.VBLANK.setimmediatevalue(1)

        self.width = width
        self.height = height
        self.hblank = hblank
        self.vblank = vblank

        self.write_lock = Lock("%s_busy" % name)

    @cocotb.coroutine
    def write(self, video):
        #print "Video: %s" % video
        yield self.write_lock.acquire()
        yield RisingEdge(self.clock)
        self.bus.DATA_EN               <=  1
        for frame in video:
            for line in frame:
                for pixel in line:
                    self.bus.HBLANK    <=  0
                    self.bus.VBLANK    <=  0
                    self.bus.HSYNC     <=  1
                    self.bus.VSYNC     <=  1

                    self.bus.RGB        <= pixel
                    yield RisingEdge(self.clock)

                #Horizontal Blank
                self.bus.HSYNC         <=  0
                self.bus.HBLANK        <=  1
                for i in range(self.hblank):
                    yield RisingEdge(self.clock)

                self.bus.VSYNC         <=  0
                self.bus.VBLANK        <=  1

            #Vertical Blank
            for i in range(self.vblank):
                yield RisingEdge(self.clock)

        self.bus.DATA_EN                <=  0
        self.write_lock.release()

