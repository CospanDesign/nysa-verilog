import cocotb
from cocotb.triggers import RisingEdge, ReadOnly, Lock
from cocotb.drivers import BusDriver
from cocotb.result import ReturnValue
from cocotb.binary import BinaryValue

import binascii
import array

class NESPPU(BusDriver):
    _signals = ["X_OUT", "Y_OUT", "Y_NEXT_OUT", "PULSE_OUT", "VBLANK", "SYS_PALETTE"]

    def __init__(self, entity, name, clock, width, height):
        BusDriver.__init__(self, entity, name, clock)
        self.width = width
        self.height = height
        self.bus.SYS_PALETTE.setimmediatevalue(0)
        self.busy = Lock("%s_busy" % name)

    @cocotb.coroutine
    def run(self, data = None):

        if data is None:
            #Generate a test image
            data = [[0] * self.width] * self.height
            for y in range(self.height):
                for x in range(self.width):
                    #data[y][x] = x % 0x03F
                    data[y][x] = 0x00

        yield self.busy.acquire()


        print "Wait for pulse out to go high"
        while True:
            yield ReadOnly()
            if not self.bus.PULSE_OUT:
                print "Pulse out went high"
                yield RisingEdge(self.clock)
                continue
            yield RisingEdge(self.clock)

            ypos = int(self.bus.Y_OUT)
            xpos = int(self.bus.X_OUT)
            self.bus.SYS_PALETTE <=  data[ypos][xpos]

        print "Exiting run..."
        self.busy.release()

