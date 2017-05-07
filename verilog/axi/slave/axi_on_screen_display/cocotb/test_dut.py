import os
import sys
import cocotb
import logging
from cocotb.result import TestFailure
from cocotb.clock import Clock
import time
from array import array as Array
from cocotb.triggers import Timer, FallingEdge

from cocotb.drivers.amba import AXI4LiteMaster
from cocotb.drivers.amba import AXI4StreamSlave

CLK_PERIOD = 10

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "rtl")
MODULE_PATH = os.path.abspath(MODULE_PATH)



BIT_CTRL_EN                     = 0
BIT_CTRL_CLEAR_SCREEN_STB       = 1
BIT_CTRL_SCROLL_EN              = 4
BIT_CTRL_SCROLL_UP_STB          = 5
BIT_CTRL_SCROLL_DOWN_STB        = 6

BIT_CHAR_ALT_ENABLE             = 8


REG_CONTROL                     = 0
REG_STATUS                      = 1
REG_IMAGE_WIDTH                 = 2
REG_IMAGE_HEIGHT                = 3
REG_IMAGE_SIZE                  = 4
REG_FG_COLOR                    = 5
REG_BG_COLOR                    = 6
REG_CONSOLE_CHAR                = 7
REG_CONSOLE_COMMAND             = 8
REG_TAB_COUNT                   = 9
REG_X_START                     = 10
REG_X_END                       = 11
REG_Y_START                     = 12
REG_X_END                       = 13
REG_VERSION                     = 14

def load_font_mem(font_mem, font_mem_path):
    f = open(font_mem_path)
    lines = f.readlines()
    f.close()
    for i in range(len(lines)):
        data = int(lines[i], '16')
        font_mem_path[i] = data

def setup_dut(dut):
    cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())

@cocotb.test(skip = True)
def first_test(dut):
    """
    Description:
        *

    Test ID: 0

    Expected Results:
        *
    """
    dut.rst <= 1
    dut.test_id <= 0
    axim = AXI4LiteMaster(dut, "AXIML", dut.clk)
    video_in = AXI4StreamSlave(dut, "AXISS", dut.clk, width=24)

    setup_dut(dut)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)
    dut.log.info("Ready")
    yield Timer(CLK_PERIOD * 300)


@cocotb.test(skip = True)
def write_char_test(dut):
    """
    Description:
        Demonstrate writing characters down. This will also show that the
        line pointers will increment (prev line, curr line, next line)

    Test ID: 1

    Expected Results:
        **
    """
    dut.rst <= 1
    dut.test_id <= 1
    axim = AXI4LiteMaster(dut, "AXIML", dut.clk)
    video_in = AXI4StreamSlave(dut, "AXISS", dut.clk, width=24)

    setup_dut(dut)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)
    dut.log.info("Ready")
    yield Timer(CLK_PERIOD * 300)

    control = 0x00
    control |= 1 << BIT_CTRL_EN
    yield axim.write(REG_CONTROL, control)
    yield Timer(CLK_PERIOD * 10)

    #Write a characer down
    char_val = 0x41
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 10)

    #Write a characer down
    char_val = 0x42
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 100)


@cocotb.test(skip = True)
def write_carriage_return(dut):
    """
    Description:
        Demonstrate writing characters down. This will also show that the
        line pointers will increment (prev line, curr line, next line)

    Test ID: 2

    Expected Results:
        **
    """
    dut.rst <= 1
    dut.test_id <= 2
    axim = AXI4LiteMaster(dut, "AXIML", dut.clk)
    video_in = AXI4StreamSlave(dut, "AXISS", dut.clk, width=24)

    setup_dut(dut)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)
    dut.log.info("Ready")
    yield Timer(CLK_PERIOD * 300)

    control = 0x00
    control |= 1 << BIT_CTRL_EN
    yield axim.write(REG_CONTROL, control)
    yield Timer(CLK_PERIOD * 10)

    #Write a characer down
    char_val = 0x41
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 10)

    #Write a characer down
    char_val = 0x42
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 10)

    #Write a carriage return
    char_val = 0x0D
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 100)


@cocotb.test(skip = True)
def write_tab(dut):
    """
    Description:
        Write a tab down

    Test ID: 3

    Expected Results:
        **
    """
    dut.rst <= 1
    dut.test_id <= 3
    axim = AXI4LiteMaster(dut, "AXIML", dut.clk)
    video_in = AXI4StreamSlave(dut, "AXISS", dut.clk, width=24)

    setup_dut(dut)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)
    dut.log.info("Ready")
    yield Timer(CLK_PERIOD * 300)

    control = 0x00
    control |= 1 << BIT_CTRL_EN
    yield axim.write(REG_CONTROL, control)
    yield Timer(CLK_PERIOD * 10)

    #Write a characer down
    char_val = 0x41
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 10)

    #Write a carriage return
    char_val = 0x09
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 100)

@cocotb.test(skip = True)
def test_backspace(dut):
    """
    Description:
        Write a tab down

    Test ID: 4

    Expected Results:
        **
    """
    dut.rst <= 1
    dut.test_id <= 4
    axim = AXI4LiteMaster(dut, "AXIML", dut.clk)
    video_in = AXI4StreamSlave(dut, "AXISS", dut.clk, width=24)

    setup_dut(dut)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)
    dut.log.info("Ready")
    yield Timer(CLK_PERIOD * 300)

    control = 0x00
    control |= 1 << BIT_CTRL_EN
    yield axim.write(REG_CONTROL, control)
    yield Timer(CLK_PERIOD * 10)

    #Write a characer down
    char_val = 0x41
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 10)

    #Write a characer down
    char_val = 0x42
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 10)

    #Write a characer down
    char_val = 0x43
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 10)


    #Write a backspace
    char_val = 0x08
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 10)


    #Write a backspace
    char_val = 0x08
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 10)


    #Write a backspace
    char_val = 0x08
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 10)



@cocotb.test(skip = True)
def write_full_page_char_test(dut):
    """
    Description:

    Test ID: 5

    Expected Results:
        **
    """
    #load_font_mem(dut.dut.cosd.font_buffer.mem, "../rtl/fontdata.mem")
    dut.rst <= 1
    dut.test_id <= 5
    axim = AXI4LiteMaster(dut, "AXIML", dut.clk)
    video_in = AXI4StreamSlave(dut, "AXISS", dut.clk, width=24)

    setup_dut(dut)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)
    dut.log.info("Ready")
    yield Timer(CLK_PERIOD * 300)

    #Write a characer down
    char_val = 0x41
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 5)

    #Write a characer down
    char_val = 0x102
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 5)

    char_val = 0x0A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 5)



    control = 0x00
    control |= 1 << BIT_CTRL_EN
    yield axim.write(REG_CONTROL, control)
    yield Timer(CLK_PERIOD * 10)
    #control = 0x00
    #control &= ~(1 << BIT_CTRL_EN)
    #yield axim.write(REG_CONTROL, control)

    yield video_in.read()
    yield Timer(CLK_PERIOD * 2000)
    control |= (1 << BIT_CTRL_CLEAR_SCREEN_STB)
    yield axim.write(REG_CONTROL, control)

    yield Timer(CLK_PERIOD * 4000)

    #Write a characer down
    char_val = 0x41
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)
    #Write a characer down
    char_val = 0x0A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x0A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x41
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x41
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x41
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x41
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x0A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x0A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x0A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x41
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x0A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x41
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x0A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x41
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x0A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x41
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    yield Timer(CLK_PERIOD * 6000)


@cocotb.test(skip = True)
def write_full_page_char_backspace_test(dut):
    """
    Description:
        Test backspaces

    Test ID: 6

    Expected Results:
        **
    """
    #load_font_mem(dut.dut.cosd.font_buffer.mem, "../rtl/fontdata.mem")
    dut.rst <= 1
    dut.test_id <= 6
    axim = AXI4LiteMaster(dut, "AXIML", dut.clk)
    video_in = AXI4StreamSlave(dut, "AXISS", dut.clk, width=24)

    setup_dut(dut)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)
    dut.log.info("Ready")
    yield Timer(CLK_PERIOD * 300)

    #Write a characer down
    char_val = 0x41
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 5)

    #Write a characer down
    char_val = 0x102
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 5)

    char_val = 0x0A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 5)



    control = 0x00
    control |= 1 << BIT_CTRL_EN
    yield axim.write(REG_CONTROL, control)
    yield Timer(CLK_PERIOD * 10)
    #control = 0x00
    #control &= ~(1 << BIT_CTRL_EN)
    #yield axim.write(REG_CONTROL, control)

    yield video_in.read()
    yield Timer(CLK_PERIOD * 100)

    #Write a characer down
    char_val = 0x41
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)
    #Write a characer down
    char_val = 0x0A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x42
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x0A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x43
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x0A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x44
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x0A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)
 
    char_val = 0x45
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x0A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x46
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x0A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x47
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x0A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x48
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x0A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x49
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x0A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x4A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x0A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x0A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)



    '''
    char_val = 0x0A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x4B
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x0A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x4C
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x0A
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)

    char_val = 0x4D
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 1)
    '''



    yield Timer(CLK_PERIOD * 100)

    #Insert a backspace
    char_val = 0x08
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 50)

    char_val = 0x08
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 100)

    char_val = 0x08
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 100)

    char_val = 0x08
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 100)

    char_val = 0x08
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 100)

    '''
    char_val = 0x08
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 100)

    char_val = 0x08
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 100)

    '''



    yield Timer(CLK_PERIOD * 4000)

@cocotb.test(skip = False)
def write_char_test(dut):
    """
    Description:

    Test ID: 7

    Expected Results:
        **
    """
    dut.rst <= 1
    dut.test_id <= 7
    axim = AXI4LiteMaster(dut, "AXIML", dut.clk)
    video_in = AXI4StreamSlave(dut, "AXISS", dut.clk, width=24)

    setup_dut(dut)
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)
    dut.log.info("Ready")
    yield Timer(CLK_PERIOD * 300)

    control = 0x00
    control |= 1 << BIT_CTRL_EN
    yield axim.write(REG_CONTROL, control)
    yield Timer(CLK_PERIOD * 10)

    #Write a characer down
    char_val = 0x0101
    yield axim.write(REG_CONSOLE_CHAR, char_val)
    yield Timer(CLK_PERIOD * 10)

