# Simple tests for an adder module
import cocotb
import logging
from cocotb.result import TestFailure
from nysa.host.driver.sata_driver import SATADriver
import nysa.host.driver.dma as dmam
from nysa.host.driver.dma import DMA
from model.sim_host import NysaSim
from cocotb.clock import Clock
import time
from array import array as Array

SATA_CLK_PERIOD = 16
CLK_PERIOD = 10


def setup_sata(dut):
    cocotb.fork(Clock(dut.sata_clk, SATA_CLK_PERIOD).start())
    dut.u2h_write_enable = 0
    dut.u2h_write_count = 2048
    dut.h2u_read_enable = 0

@cocotb.coroutine
def wait_for_sata_ready(nysa, dut):

    while not dut.hd_ready.value.get_value():
        yield(nysa.wait_clocks(1))

    dut.log.info("SATA Stack Ready")
    yield(nysa.wait_clocks(100))

def enable_hd_read(nysa, dut):
    dut.u2h_read_enable = 1

@cocotb.coroutine
def enable_hd_write(nysa, dut, count):
    dut.d2h_write_count = count
    dut.u2h_write_enable = True

@cocotb.coroutine
def enable_sata_hold(nysa, dut, enable):
    dut.hold = enable

@cocotb.test(skip = True)
def first_test(dut):
    """
    Description:
        Very Basic Functionality
            Startup Nysa
            Startup Sata Stack

    Test ID: 0

    Expected Results:
        Write to all registers
    """

    dut.test_id = 0
    nysa = NysaSim(dut, CLK_PERIOD)
    setup_sata(dut)

    yield(nysa.reset())
    nysa.read_sdb()
    #nysa.pretty_print_sdb()

    #Get the driver
    sata = SATADriver(nysa, nysa.find_device(SATADriver)[0])

    #Reset the hard drive
    yield cocotb.external(sata.enable_sata_reset)(False)
    #Wait for SATA to Startup
    yield(wait_for_sata_ready)(nysa, dut)

    dut.log.info("SATA Opened!")
    dut.log.info("Ready")


@cocotb.test(skip = True)
def write_test(dut):
    """
    Description:
        Very Basic Functionality
            Startup Nysa
            Startup Sata Stack

    Test ID: 1

    Expected Results:
        Write to all registers
    """

    dut.test_id = 1
    nysa = NysaSim(dut, CLK_PERIOD)
    setup_sata(dut)

    yield(nysa.reset())
    nysa.read_sdb()
    #nysa.pretty_print_sdb()
    enable_hd_read(nysa, dut)

    #Get the driver
    sata = SATADriver(nysa, nysa.find_device(SATADriver)[0])

    #Reset the hard drive
    yield cocotb.external(sata.enable_sata_reset)(False)
    #Wait for SATA to Startup
    yield(wait_for_sata_ready)(nysa, dut)
    values = Array('B')
    clear_values = Array('B')
    #for i in range (0, 2048 * 4):
    for i in range (0, 2048):
        v = Array('B', [(i >> 24) & 0xFF, (i >> 16) & 0xFF, (i >> 8) & 0xFF, i & 0xFF])
        #values.append(i % 256)
        values.extend(v)
        clear_values.append(0)
        clear_values.extend(Array('B', [0, 0, 0, 0]))

    #yield cocotb.external(sata.set_local_buffer_write_size)(100)
    yield cocotb.external(sata.write_local_buffer)(values)
    yield cocotb.external(sata.load_local_buffer)()


    dut.log.info("SATA Opened!")
    dut.log.info("Ready")
    dut.u2h_write_enable = 1
    dut.u2h_write_count = 2048
    yield cocotb.external(sata.hard_drive_write)(0x01000, 1)
    yield(nysa.wait_clocks(10000))
    dut.u2h_write_enable = 0


@cocotb.test(skip = True)
def read_test(dut):
    """
    Description:
        Very Basic Functionality
            Startup Nysa
            Startup Sata Stack

    Test ID: 1

    Expected Results:
        Write to all registers
    """

    dut.test_id = 2
    nysa = NysaSim(dut, CLK_PERIOD)
    setup_sata(dut)

    yield(nysa.reset())
    nysa.read_sdb()
    #nysa.pretty_print_sdb()
    enable_hd_read(nysa, dut)

    #Get the driver
    sata = SATADriver(nysa, nysa.find_device(SATADriver)[0])

    #Reset the hard drive
    yield cocotb.external(sata.enable_sata_reset)(False)
    #Wait for SATA to Startup
    yield(wait_for_sata_ready)(nysa, dut)
    values = Array('B')
    clear_values = Array('B')

    dut.h2u_read_enable = 1
    yield(nysa.wait_clocks(3000))
    yield cocotb.external(sata.hard_drive_read)(0x01000, 1)
    yield(nysa.wait_clocks(7000))
    data = yield(cocotb.external(sata.read_local_buffer))()
    dut.h2u_read_enable = 0





def get_register_range(signal, top_bit, bot_bit):
    #print "top_bit: %d" % top_bit
    mask = (((1 << (top_bit)) - (1 << bot_bit)) >> (bot_bit))
    value = signal.value.get_value()
    value &= ((1 << top_bit) - (1 << bot_bit));
    value = (value >> bot_bit) & mask
    return value

def is_bit_set(signal, bit):
    return ((signal & 1 << bit) > 0)


def get_source_error_signal(dut, source_addr):
    source_ptr = None
    '''
    XXX

    This is ugly and should be fixed with a generator
    Maybe not, I'm not sure if I can parameterize all the input if I did a
    generator
    '''
    if source_addr == 0:
        source_ptr = dut.tdm0.tmd
    elif source_addr == 1:
        source_ptr = dut.tdm1.tmd
    elif source_addr == 2:
        source_ptr = dut.tdm2.tmd
    elif source_addr == 3:
        #source_ptr = dut.tdm3.tmd
        return dut.s1.dma.read_error

    return source_ptr.m2f_data_error

def get_sink_error_signal(dut, sink_addr):
    sink_ptr = None
    '''
    XXX

    This is ugly and should be fixed with a generator
    Maybe not, I'm not sure if I can parameterize all the input if I did a
    generator
    '''
    if sink_addr == 0:
        sink_ptr = dut.tdm0.tmd
    elif sink_addr == 1:
        sink_ptr = dut.tdm1.tmd
    elif sink_addr == 2:
        sink_ptr = dut.tdm2.tmd
    elif sink_addr == 3:
        #sink_ptr = dut.tdm3.tmd
        return dut.s1.dma.read_error

    return sink_ptr.f2m_data_error



@cocotb.test(skip = True)
def dma_first_test(dut):
    """
    Description:
        Very Basic Functionality
            Startup Nysa
            Startup DMA Controller

    Test ID: 4

    Expected Results:
        Write to all registers
    """

    dut.test_id = 4
    nysa = NysaSim(dut)
    yield(nysa.reset())
    nysa.read_sdb()

    dma = DMA(nysa, nysa.find_device(DMA)[0])
    sata = SATADriver(nysa, nysa.find_device(SATADriver)[0])
    yield cocotb.external(dma.setup)()
    setup_sata(dut)
    yield cocotb.external(sata.enable_sata_reset)(False)

    count = yield cocotb.external(dma.get_channel_count)()
    dut.log.info("DMA Channel Count: %d" % count)

    dut.log.info("SATA Opened!")
    dut.log.info("DMA Opened!")
    dut.log.info("Ready")
    yield nysa.wait_clocks(100)


class ErrorMonitor(cocotb.monitors.Monitor):

    def __init__(self, dut, signal):
        self.dut = dut
        self.signal = signal
        super (ErrorMonitor, self).__init__(callback = None, event = None)

    @cocotb.coroutine
    def _monitor_recv(self):
        while (1):
            yield cocotb.triggers.RisingEdge(self.signal)
            #self._recv(self.dut.get_sim_time())
            self._recv(1)

@cocotb.test(skip = False)
def test_execute_single_instruction(dut):
    """
    Description:
        -Setup source and sink for 0x200 word transaction
        -Setup the source address to increment
        -Setup the sink address to increment
        -setup instruction

    Test ID: 5

    Expected Results:
        Data is all transferred from one memory device to the next
    """
    dut.test_id = 5
    nysa = NysaSim(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield nysa.wait_clocks(2000)

    dma = DMA(nysa, nysa.find_device(DMA)[0])
    sata = SATADriver(nysa, nysa.find_device(SATADriver)[0])
    setup_sata(dut)

    yield cocotb.external(sata.enable_sata_reset)(False)
    yield cocotb.external(dma.setup)()
    yield cocotb.external(dma.enable_dma)(True)
    yield nysa.wait_clocks(10)
    yield cocotb.external(sata.enable_dma_control)(True)

    WORD_COUNT = 0x1000
    CHANNEL_ADDR = 1
    SINK_ADDR = 3
    INST_ADDR = 7

    SOURCE_ADDRESS  = 0x0000000000000000
    DEST_ADDRESS    = 0x0000000000000200

    source_error = get_source_error_signal(dut, CHANNEL_ADDR)
    sink_error = get_sink_error_signal(dut, SINK_ADDR)
    source_error_monitor = ErrorMonitor(dut, source_error)
    sink_error_monitor = ErrorMonitor(dut, sink_error)

    yield cocotb.external(dma.set_channel_sink_addr)            (CHANNEL_ADDR,  SINK_ADDR           )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.set_channel_instruction_pointer)  (CHANNEL_ADDR,  INST_ADDR           )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.enable_source_address_increment)  (CHANNEL_ADDR,  True                )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.enable_dest_address_increment)    (SINK_ADDR,     True                )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.enable_dest_respect_quantum)      (SINK_ADDR,     False              )
    #yield cocotb.external(dma.enable_dest_respect_quantum)      (SINK_ADDR,     True                )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.set_instruction_source_address)   (INST_ADDR,     SOURCE_ADDRESS      )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.set_instruction_dest_address)     (INST_ADDR,     DEST_ADDRESS        )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.set_instruction_data_count)       (INST_ADDR,     WORD_COUNT          )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.set_channel_instruction_pointer)  (CHANNEL_ADDR,  INST_ADDR           )
    yield nysa.wait_clocks(10)
    #Start
    yield cocotb.external(dma.enable_channel)                   (CHANNEL_ADDR,  True                )

    yield nysa.wait_clocks(8000)
    yield cocotb.external(dma.enable_channel)                   (CHANNEL_ADDR,  False               )
    yield cocotb.external(dma.enable_dma)(False)
    yield nysa.wait_clocks(10)
    #dut.tdm0.m2f_data_error <= 1
    #yield nysa.wait_clocks(10)

    if len(source_error_monitor) > 0:
        raise cocotb.result.TestFailure("Test %d Error on source %d write detected %d errors" % (dut.test_id, CHANNEL_ADDR, len(source_error_monitor)))

    if len(sink_error_monitor) > 0:
        raise cocotb.result.TestFailure("Test %d Error on source %d read detected %d errors" % (dut.test_id, SINK_ADDR, len(sink_error_monitor)))

    source_error_monitor.kill()
    sink_error_monitor.kill()




@cocotb.test(skip = True)
def test_continuous_transfer(dut):
    """
    Description:
        Setup a channel to transfer data

    Test ID: 6

    Expected Results:
        Data is all transferred from one memory device to the next
    """
    dut.test_id = 6
    nysa = NysaSim(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield nysa.wait_clocks(2000)

    dma = DMA(nysa, nysa.find_device(DMA)[0])
    sata = SATADriver(nysa, nysa.find_device(SATADriver)[0])
    setup_sata(dut)

    yield cocotb.external(sata.enable_sata_reset)(False)

    yield cocotb.external(dma.setup)()
    yield cocotb.external(dma.enable_dma)(True)
    #yield nysa.wait_clocks(10)

    CHANNEL_ADDR = 0
    SINK_ADDR = 2
    INST_ADDR = 2

    source_error = get_source_error_signal(dut, CHANNEL_ADDR)
    sink_error = get_sink_error_signal(dut, SINK_ADDR)
    source_error_monitor = ErrorMonitor(dut, source_error)
    sink_error_monitor = ErrorMonitor(dut, sink_error)
    #yield cocotb.external(dma.enable_channel)                   (CHANNEL_ADDR,  False               )



    yield cocotb.external(dma.set_channel_sink_addr)            (CHANNEL_ADDR,  SINK_ADDR           )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.set_channel_instruction_pointer)  (CHANNEL_ADDR,  INST_ADDR           )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.enable_source_address_increment)  (CHANNEL_ADDR,  True                )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.enable_dest_address_increment)    (SINK_ADDR,     True                )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.enable_dest_respect_quantum)      (SINK_ADDR,     False               )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.enable_instruction_continue)      (INST_ADDR,     True                )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.set_instruction_source_address)   (INST_ADDR,     0x0000000000000000  )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.set_instruction_dest_address)     (INST_ADDR,     0x0000000000000010  )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.set_instruction_data_count)       (INST_ADDR,     0x0100              )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.set_instruction_next_instruction) (INST_ADDR,     INST_ADDR           )
    yield nysa.wait_clocks(10)

    #Start
    yield cocotb.external(dma.set_channel_instruction_pointer)  (CHANNEL_ADDR,  INST_ADDR           )
    yield cocotb.external(dma.enable_channel)                   (CHANNEL_ADDR,  True                )

    yield nysa.wait_clocks(2000)
    yield cocotb.external(dma.enable_channel)                   (CHANNEL_ADDR,  False               )
    yield cocotb.external(dma.enable_dma)(False)
    yield nysa.wait_clocks(10)

    if len(source_error_monitor) > 0:
        raise cocotb.result.TestFailure("Test %d Error on source %d read detected %d errors" % (dut.test_id, CHANNEL_ADDR, len(source_error_monitor)))

    if len(sink_error_monitor) > 0:
        raise cocotb.result.TestFailure("Test %d Error on sink %d write detected %d errors" % (dut.test_id, SINK_ADDR, len(sink_error_monitor)))


    source_error_monitor.kill()
    sink_error_monitor.kill()



@cocotb.test(skip = True)
def test_double_buffer(dut):
    """
    Description:
        Setup a channel to transfer data

    Test ID: 7

    Expected Results:
        Data is all transferred from one memory device to the next
    """
    dut.test_id = 7
    nysa = NysaSim(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield nysa.wait_clocks(10)

    dma = DMA(nysa, nysa.find_device(DMA)[0])
    sata = SATADriver(nysa, nysa.find_device(SATADriver)[0])
    setup_sata(dut)

    yield cocotb.external(sata.enable_sata_reset)(False)

    yield cocotb.external(dma.setup)()
    yield cocotb.external(dma.enable_dma)(True)
    #yield nysa.wait_clocks(10)

    #Instructions
    INST_START_ADDR    = 0

    #Channels
    SOURCE_CHANNEL     = 0

    MEM_SINK_CHANNEL   = 2
    MEM_SOURCE_CHANNEL = 2

    SINK_CHANNEL       = 1

    #Addresses
    SOURCE_ADDR        = 0x0000

    MEM_ADDR0          = 0x0000
    MEM_ADDR1          = 0x0000

    SINK_ADDR          = 0x0000

    #Count
    COUNT              = 0x0080

    print "Setup double buffer"

    source_error = get_source_error_signal(dut, SOURCE_CHANNEL)
    sink_error = get_sink_error_signal(dut, SINK_CHANNEL)

    source_error_monitor = ErrorMonitor(dut, source_error)
    sink_error_monitor = ErrorMonitor(dut, sink_error)

    #Setup Address Increments for all sinks and sources
    yield cocotb.external(dma.enable_source_address_increment)(SOURCE_CHANNEL, True)
    yield cocotb.external(dma.enable_dest_address_increment)(SINK_CHANNEL, True)
    yield cocotb.external(dma.enable_dest_respect_quantum)(MEM_SINK_CHANNEL, True)

    yield cocotb.external(dma.enable_source_address_increment)(MEM_SOURCE_CHANNEL, True)
    yield cocotb.external(dma.enable_dest_respect_quantum)(MEM_SINK_CHANNEL, False)
    yield cocotb.external(dma.enable_dest_address_increment)(MEM_SINK_CHANNEL, True)

    yield cocotb.external(dma.set_channel_sink_addr)(SOURCE_CHANNEL,        MEM_SINK_CHANNEL)
    yield cocotb.external(dma.set_channel_sink_addr)(MEM_SOURCE_CHANNEL,    SINK_CHANNEL)


    yield cocotb.external(dma.setup_double_buffer)                      \
                        (    start_inst_addr =   INST_START_ADDR,       \
                             source          =   SOURCE_CHANNEL,        \
                             sink            =   SINK_CHANNEL,          \
                             mem_sink        =   MEM_SINK_CHANNEL,      \
                             mem_source      =   MEM_SOURCE_CHANNEL,    \
                             source_addr     =   SOURCE_ADDR,           \
                             sink_addr       =   SINK_ADDR,             \
                             mem_addr0       =   MEM_ADDR0,             \
                             mem_addr1       =   MEM_ADDR1,             \
                             count           =   COUNT  )

    yield cocotb.external(dma.enable_channel)(SOURCE_CHANNEL, True)
    yield cocotb.external(dma.enable_channel)(MEM_SOURCE_CHANNEL, True)

    yield nysa.wait_clocks(4000)

    yield cocotb.external(dma.enable_channel)(SOURCE_CHANNEL, False)
    yield cocotb.external(dma.enable_channel)(MEM_SOURCE_CHANNEL, False)


    if len(source_error_monitor) > 0:
        raise cocotb.result.TestFailure("Test %d Error on source %d read detected %d errors" % (dut.test_id, SOURCE_CHANNEL, len(source_error_monitor)))

    if len(sink_error_monitor) > 0:
        raise cocotb.result.TestFailure("Test %d Error on sink %d read detected %d errors" % (dut.test_id, SINK_CHANNEL, len(sink_error_monitor)))


    source_error_monitor.kill()
    sink_error_monitor.kill()
    yield nysa.wait_clocks(100)



