# Simple tests for an adder module
import cocotb
import logging
from cocotb.result import TestFailure
from model import dma as dmam
from nysa.host.driver.dma import DMA
from model.sim_host import NysaSim
import time

CLK_PERIOD = 4

@cocotb.test(skip = True)
def first_test(dut):
    """
    Description:
        Very Basic Functionality
            Startup Nysa
            Startup DMA Controller

    Test ID: 0

    Expected Results:
        Write to all registers
    """

    dut.test_id = 0
    nysa = NysaSim(dut)
    yield(nysa.reset())
    nysa.read_sdb()

    nysa.pretty_print_sdb()
    dma = DMA(nysa, nysa.find_device(DMA)[0])
    yield cocotb.external(dma.setup)()
    yield cocotb.external(dma.get_channel_count)()

    dut.log.info("DMA Opened!")
    dut.log.info("Ready")

def get_register_range(signal, top_bit, bot_bit):
    #print "top_bit: %d" % top_bit
    mask = (((1 << (top_bit)) - (1 << bot_bit)) >> (bot_bit))
    value = signal.value.get_value()
    value &= ((1 << top_bit) - (1 << bot_bit));
    value = (value >> bot_bit) & mask
    return value

def is_bit_set(signal, bit):
    return ((signal & 1 << bit) > 0)

@cocotb.test(skip = False)
def test_setup_dma(dut):
    """
    Description:
        Set Values Within Simulation and make sure they stimulate
        The correct places
            Read Number of Sources
            Read Number of Sinks
            Read Number of Instructions
            Source Testing:
                Enable DMA
                Source Address
                Address Increment
                Address Decrement
                Address No Change
                Set Sink Address
                Set Instruction Address
            Sink Testing:
                Sink Address
                Address Increment
                Address Decrement
                Address No Change
                Quantum
            Instruction
                Continue Testing
                Next Address
                Source Reset Address on Command
                Sink Reset Address on Command
                Egress Enable and Egress Bond Address
                Ingress Enable and Ingress Bond Address

    Test ID: 1

    Expected Results:
        Write to all registers
    """

    dut.test_id = 1
    nysa = NysaSim(dut)
    yield(nysa.reset())
    nysa.read_sdb()

    dma = DMA(nysa, nysa.find_device(DMA)[0])
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.setup)()
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.enable_dma)(True)
    yield nysa.wait_clocks(10)
    #print "Enable dma"

    SINK_ADDR = 2
    INST_ADDR = 7
    NEXT_INST_ADDR =3
    INGRESS_ADDR = 2
    EGRESS_ADDR = 4

    level = logging.INFO
    l = logging.getLogger("cocotb.gpi")
    #print "dma.channel_count: %d" % dma.channel_count

    #Source
    for i in range (0, dma.channel_count):
        #Set Channel Address Increment
        yield cocotb.external(dma.enable_source_address_increment)(i, True)
        l.setLevel(logging.ERROR)
        if not dut.s1.dmacntrl.flag_src_addr_inc[i].value.get_value():
            raise cocotb.result.TestFailure("Channel [%d] source addr increment is false when it should be true" % i)
        l.setLevel(level)
        r = yield cocotb.external(dma.is_source_address_increment)(i)
        if r != True:
            raise cocotb.result.TestFailure("Channel [%d] source Addr should be [%d] but is [%d]" % (i, INST_ADDR, r))

        yield cocotb.external(dma.enable_source_address_increment)(i, False)
        r = yield cocotb.external(dma.is_source_address_increment)(i)
        if r != False:
            raise cocotb.result.TestFailure("Channel [%d] source Addr should be [%d] but is [%d]" % (i, INST_ADDR, r))
        l.setLevel(logging.ERROR)
        if dut.s1.dmacntrl.flag_src_addr_inc[i].value.get_value():
            raise cocotb.result.TestFailure("Channel [%d] source addr increment is false when it should be false" % i)
        l.setLevel(level)

        #Set Channel Address Decrement
        yield cocotb.external(dma.enable_source_address_decrement)(i, True)
        l.setLevel(logging.ERROR)
        if not dut.s1.dmacntrl.flag_src_addr_dec[i].value.get_value():
            raise cocotb.result.TestFailure("Channel [%d] source addr decrement is false when it should be true" % i)
        l.setLevel(level)
        r = yield cocotb.external(dma.is_source_address_decrement)(i)
        if r != True:
            raise cocotb.result.TestFailure("Channel [%d] source Addr should be [%d] but is [%d]" % (i, INST_ADDR, r))

        yield cocotb.external(dma.enable_source_address_decrement)(i, False)
        r = yield cocotb.external(dma.is_source_address_decrement)(i)
        if r != False:
            raise cocotb.result.TestFailure("Channel [%d] source Addr should be [%d] but is [%d]" % (i, INST_ADDR, r))
        l.setLevel(logging.ERROR)
        if dut.s1.dmacntrl.flag_src_addr_dec[i].value.get_value():
            raise cocotb.result.TestFailure("Channel [%d] source addr decrement is true when it should be false" % i)
        l.setLevel(level)

        #Channel Enable
        yield cocotb.external(dma.enable_channel)(i, True)
        l.setLevel(logging.ERROR)
        if not dut.s1.dmacntrl.dma_enable[i].value.get_value():
            raise cocotb.result.TestFailure("Channel [%d] source addr enable is false when it should be true" % i)
        l.setLevel(level)
        r = yield cocotb.external(dma.is_channel_enable)(i)

        if r == False:
            raise cocotb.result.TestFailure("Channel [%d] DMA Enable should be true but it is not" % (i))
        yield cocotb.external(dma.enable_channel)(i, False)
        l.setLevel(logging.ERROR)
        if dut.s1.dmacntrl.dma_enable[i].value.get_value():
            raise cocotb.result.TestFailure("Channel [%d] source addr enable is false when it should be true" % i)
        l.setLevel(level)
        r = yield cocotb.external(dma.is_channel_enable)(i)
        if r:
            raise cocotb.result.TestFailure("Channel [%d] DMA Enable should be false but it is not" % (i))

        #Set Channel Sink Address
        yield cocotb.external(dma.set_channel_sink_addr)(i, SINK_ADDR)
        l.setLevel(logging.ERROR)
        addr = get_register_range(dut.s1.dmacntrl.src_control[i], dmam.BIT_SINK_ADDR_TOP, dmam.BIT_SINK_ADDR_BOT)
        l.setLevel(level)
        if addr != SINK_ADDR:
            cocotb.result.TestFailure("Channel [%d] Sink Address should be [%d] but is [%d]" % (i, SINK_ADDR, addr))
        r = yield cocotb.external(dma.get_channel_sink_addr)(i)
        if SINK_ADDR != r:
            raise cocotb.result.TestFailure("Channel [%d] Sink Addr should be [%d] but is [%d]" % (i, SINK_ADDR, r))

        #Set Channel Instruction Address
        yield cocotb.external(dma.set_channel_instruction_pointer)(i, INST_ADDR)
        l.setLevel(logging.ERROR)
        inst_addr = get_register_range(dut.s1.dmacntrl.src_control[i], dmam.BIT_INST_PTR_TOP, dmam.BIT_INST_PTR_BOT)
        l.setLevel(level)
        if inst_addr != INST_ADDR:
            raise cocotb.result.TestFailure("Channel [%d] Insruction Addr should be [%d] but is [%d]" % (i, INST_ADDR, inst_addr))
        r = yield cocotb.external(dma.get_channel_instruction_pointer)(i)
        if INST_ADDR != r:
            raise cocotb.result.TestFailure("Channel [%d] Insruction Addr should be [%d] but is [%d]" % (i, INST_ADDR, r))

    #Sink
    for i in range (0, dma.sink_count):

        #Enable and Disable the dest incrementing
        yield cocotb.external(dma.enable_dest_address_increment)(i, True)
        l.setLevel(logging.ERROR)
        if not dut.s1.dmacntrl.flag_dest_addr_inc[i].value.get_value():
            raise cocotb.result.TestFailure("Sink [%d] DMA Sink Address Increment not enabled" % (i))
        l.setLevel(level)
        r = yield cocotb.external(dma.is_dest_address_increment)(i)
        if r != True:
            raise cocotb.result.TestFailure("Sink [%d] DMA Sink Address Increment not enabled" % (i))
        yield cocotb.external(dma.enable_dest_address_increment)(i, False)
        l.setLevel(logging.ERROR)
        if dut.s1.dmacntrl.flag_dest_addr_inc[i].value.get_value():
            raise cocotb.result.TestFailure("Sink [%d] DMA Sink Address Increment not enabled" % (i))
        l.setLevel(level)
        r = yield cocotb.external(dma.is_dest_address_increment)(i)
        if r:
            raise cocotb.result.TestFailure("Sink [%d] DMA Sink Address Increment enabled" % (i))


        #Enable and Disable the dest decrementing
        yield cocotb.external(dma.enable_dest_address_decrement)(i, True)
        l.setLevel(logging.ERROR)
        if not dut.s1.dmacntrl.flag_dest_addr_dec[i].value.get_value():
            raise cocotb.result.TestFailure("Sink [%d] DMA Sink Address Decrement not enabled" % (i))
        l.setLevel(level)
        r = yield cocotb.external(dma.is_dest_address_decrement)(i)
        if r != True:
            raise cocotb.result.TestFailure("Sink [%d] DMA Sink Address Decrement not enabled" % (i))

        yield cocotb.external(dma.enable_dest_address_decrement)(i, False)
        if dut.s1.dmacntrl.flag_dest_addr_dec[i].value.get_value():
            raise cocotb.result.TestFailure("Sink [%d] DMA Sink Address Decrement not enabled" % (i))
        l.setLevel(level)
        r = yield cocotb.external(dma.is_dest_address_decrement)(i)
        if r:
            raise cocotb.result.TestFailure("Sink [%d] DMA Sink Address Decrement enabled" % (i))

        #Enable and Disable the sink respect quantum
        yield cocotb.external(dma.enable_dest_respect_quantum)(i, True)
        l.setLevel(logging.ERROR)
        if not dut.s1.dmacntrl.flag_dest_data_quantum[i].value.get_value():
            raise cocotb.result.TestFailure("Sink [%d] DMA Sink Address Respect Quantum not enabled" % (i))
        l.setLevel(level)
        r = yield cocotb.external(dma.is_dest_respect_quantum)(i)
        if r != True:
            raise cocotb.result.TestFailure("Sink [%d] DMA Sink Address Respect Quantum not enabled" % (i))

        yield cocotb.external(dma.enable_dest_respect_quantum)(i, False)
        l.setLevel(logging.ERROR)
        if dut.s1.dmacntrl.flag_dest_data_quantum[i].value.get_value():
            raise cocotb.result.TestFailure("Sink [%d] DMA Sink Address Respect Quantum enabled" % (i))
        l.setLevel(level)
        r = yield cocotb.external(dma.is_dest_respect_quantum)(i)
        if r:
            raise cocotb.result.TestFailure("Sink [%d] DMA Sink Address Respect Quantum enabled" % (i))

    #Instruction
    for i in range(dma.get_instruction_count()):
        #Continue Testing
        yield cocotb.external(dma.enable_instruction_continue)(i, True)
        l.setLevel(logging.ERROR)
        if not dut.s1.dmacntrl.flag_instruction_continue[i].value.get_value():
            raise cocotb.result.TestFailure("Instruction [%d] Instruction Continue Not Enabled When it shouldn't be" % (i))
        l.setLevel(level)
        yield cocotb.external(dma.enable_instruction_continue)(i, False)
        l.setLevel(logging.ERROR)
        if dut.s1.dmacntrl.flag_instruction_continue[i].value.get_value():
            raise cocotb.result.TestFailure("Instruction [%d] Instruction Continue Enabled When it shouldn't be" % (i))
        l.setLevel(level)

        #Next Address
        yield cocotb.external(dma.set_instruction_next_instruction)(i, NEXT_INST_ADDR)
        l.setLevel(logging.ERROR)
        addr = dut.s1.dmacntrl.cmd_next[i].value.get_value()
        l.setLevel(level)
        if addr != NEXT_INST_ADDR:
            raise cocotb.result.TestFailure("Instruction [%d] Next Address Should be [%d] but is [%d]" % (i, NEXT_INST_ADDR, addr))

        yield cocotb.external(dma.set_instruction_next_instruction)(i, 0)
        l.setLevel(logging.ERROR)
        addr = dut.s1.dmacntrl.cmd_next[i].value.get_value()
        l.setLevel(level)
        if addr != 0:
            raise cocotb.result.TestFailure("Instruction [%d] Next Address Should be [%d] but is [%d]" % (i, 0, addr))

        #Source Reset Address on Command
        yield cocotb.external(dma.enable_instruction_src_addr_reset_on_cmd)(i, True)
        l.setLevel(logging.ERROR)
        if not dut.s1.dmacntrl.flag_src_addr_rst_on_cmd[i].value.get_value():
            raise cocotb.result.TestFailure("Instruction [%d] Reset Source Address on command is not set" % (i))
        l.setLevel(level)
        yield cocotb.external(dma.enable_instruction_src_addr_reset_on_cmd)(i, False)
        l.setLevel(logging.ERROR)
        if dut.s1.dmacntrl.flag_src_addr_rst_on_cmd[i].value.get_value():
            raise cocotb.result.TestFailure("Instruction [%d] Reset Source Address on command is set" % (i))
        l.setLevel(level)

        #Sink Reset Address on Command
        yield cocotb.external(dma.enable_instruction_dest_addr_reset_on_cmd)(i, True)
        l.setLevel(logging.ERROR)
        if not dut.s1.dmacntrl.flag_dest_addr_rst_on_cmd[i].value.get_value():
            raise cocotb.result.TestFailure("Instruction [%d] Reset Destination Address on command is not set" % (i))
        l.setLevel(level)

        yield cocotb.external(dma.enable_instruction_dest_addr_reset_on_cmd)(i, False)
        if dut.s1.dmacntrl.flag_dest_addr_rst_on_cmd[i].value.get_value():
            raise cocotb.result.TestFailure("Instruction [%d] Reset Destination Address on command is set" % (i))
        l.setLevel(level)

        #Egress Enable and Egress Bond Address
        yield cocotb.external(dma.set_instruction_egress)(i, EGRESS_ADDR)
        yield cocotb.external(dma.enable_egress_bond)(i, True)
        l.setLevel(logging.ERROR)
        addr = dut.s1.dmacntrl.egress_bond_ip[i].value.get_value()

        if not dut.s1.dmacntrl.flag_egress_bond[i].value.get_value():
            raise cocotb.result.TestFailure("Instruction [%d] Egress is not Enabled when it should be" % (i))
        l.setLevel(level)

        if addr != EGRESS_ADDR:
            raise cocotb.result.TestFailure("Instruction [%d] Egress Address Should be [%d] but is [%d]" % (i, EGRESS_ADDR, addr))

        yield cocotb.external(dma.enable_egress_bond)(i, False)
        if dut.s1.dmacntrl.flag_egress_bond[i].value.get_value():
            raise cocotb.result.TestFailure("Instruction [%d] Egress is Enabled when it shouldn't be" % (i))

        #Ingress Enable and Ingress Bond Address
        yield cocotb.external(dma.set_instruction_ingress)(i, INGRESS_ADDR)
        yield cocotb.external(dma.enable_ingress_bond)(i, True)
        l.setLevel(logging.ERROR)
        addr = dut.s1.dmacntrl.ingress_bond_ip[i].value.get_value()
        if not dut.s1.dmacntrl.flag_ingress_bond[i].value.get_value():
            raise cocotb.result.TestFailure("Instruction [%d] Ingress is not Enabled when it should be" % (i))
        l.setLevel(level)
        if addr != INGRESS_ADDR:
            raise cocotb.result.TestFailure("Instruction [%d] Ingress Address Should be [%d] but is [%d]" % (i, EGRESS_ADDR, addr))

        yield cocotb.external(dma.enable_ingress_bond)(i, False)

        l.setLevel(logging.ERROR)
        if dut.s1.dmacntrl.flag_ingress_bond[i].value.get_value():
            raise cocotb.result.TestFailure("Instruction [%d] Ingress is Enabled when it shouldn't be" % (i))
        l.setLevel(level)


    print "Finished"


    yield nysa.wait_clocks(10)


def get_source_error_signal(dut, source_addr):
    source_ptr = None
    '''
    XXX

    This is ugly and should be fixed with a generator
    Maybe not, I'm not sure if I can parameterize all the input if I did a
    generator
    '''
    if source_addr == 0:
        source_ptr = dut.tdm0
    elif source_addr == 1:
        source_ptr = dut.tdm1
    elif source_addr == 2:
        source_ptr = dut.tdm2
    elif source_addr == 3:
        source_ptr = dut.tdm3

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
        sink_ptr = dut.tdm0
    elif sink_addr == 1:
        sink_ptr = dut.tdm1
    elif sink_addr == 2:
        sink_ptr = dut.tdm2
    elif sink_addr == 3:
        sink_ptr = dut.tdm3

    return sink_ptr.f2m_data_error


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

@cocotb.test(skip = True)
def test_execute_single_instruction(dut):
    """
    Description:
        -Setup source and sink for 256 word transaction
        -Setup the source address to increment
        -Setup the sink address to increment
        -setup instruction

    Test ID: 2

    Expected Results:
        Data is all transferred from one memory device to the next
    """
    dut.test_id = 2
    nysa = NysaSim(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield nysa.wait_clocks(2000)

    dma = DMA(nysa, nysa.find_device(DMA)[0])
    yield cocotb.external(dma.setup)()
    yield cocotb.external(dma.enable_dma)(True)
    #yield nysa.wait_clocks(10)

    CHANNEL_ADDR = 0
    SINK_ADDR = 2
    INST_ADDR = 7

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
    yield cocotb.external(dma.set_instruction_source_address)   (INST_ADDR,     0x0000000000000000  )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.set_instruction_dest_address)     (INST_ADDR,     0x0000000000000010  )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.set_instruction_count)            (INST_ADDR,     0x0100              )
    yield nysa.wait_clocks(10)
    yield cocotb.external(dma.set_channel_instruction_pointer)  (CHANNEL_ADDR,  INST_ADDR           )
    yield nysa.wait_clocks(10)
    #Start
    yield cocotb.external(dma.enable_channel)                   (CHANNEL_ADDR,  True                )

    yield nysa.wait_clocks(2000)
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

    Test ID: 3

    Expected Results:
        Data is all transferred from one memory device to the next
    """
    dut.test_id = 3
    nysa = NysaSim(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield nysa.wait_clocks(2000)

    dma = DMA(nysa, nysa.find_device(DMA)[0])
    yield cocotb.external(dma.setup)()
    yield cocotb.external(dma.enable_dma)(True)
    #yield nysa.wait_clocks(10)

    CHANNEL_ADDR = 3
    SINK_ADDR = 1
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
    yield cocotb.external(dma.set_instruction_count)            (INST_ADDR,     0x0100              )
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
        raise cocotb.result.TestFailure("Test %d Error on sink %d read detected %d errors" % (dut.test_id, SINK_ADDR, len(sink_error_monitor)))


    source_error_monitor.kill()
    sink_error_monitor.kill()



@cocotb.test(skip = True)
def test_double_buffer(dut):
    """
    Description:
        Setup a channel to transfer data

    Test ID: 4

    Expected Results:
        Data is all transferred from one memory device to the next
    """
    dut.test_id = 4
    nysa = NysaSim(dut)
    yield(nysa.reset())
    nysa.read_sdb()
    yield nysa.wait_clocks(10)

    dma = DMA(nysa, nysa.find_device(DMA)[0])
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



