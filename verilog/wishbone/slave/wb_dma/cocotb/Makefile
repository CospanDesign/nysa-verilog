
TOPLEVEL_LANG ?= verilog
PWD=$(shell pwd)
TOPDIR=$(PWD)/..
COCOTB=/home/cospan/Projects/cocotb
NYSA=/home/cospan/Projects/nysa-verilog
PYTHONPATH := ./model:$(PYTHONPATH)
export PYTHONPATH


EXTRA_ARGS+=-I$(TOPDIR)/rtl/ -I$(NYSA)/verilog/

#Dependencies
VERILOG_SOURCES = $(NYSA)/verilog/generic/blk_mem.v
VERILOG_SOURCES += $(NYSA)/verilog/generic/cross_clock_enable.v
VERILOG_SOURCES += $(NYSA)/verilog/generic/ppfifo.v
VERILOG_SOURCES += $(NYSA)/verilog/wishbone/master/wishbone_master.v
VERILOG_SOURCES += ${NYSA}/verilog/sim/wishbone/interconnect/example_2port_interconnect/wishbone_interconnect.v

#Simulation Devices
VERILOG_SOURCES += $(NYSA)/verilog/wishbone/slave/wb_test_dma_mem/rtl/test_mem_dev.v
VERILOG_SOURCES += $(NYSA)/verilog/wishbone/slave/wb_test_dma_mem/rtl/wb_test_dma_mem.v
#VERILOG_SOURCES += $(TOPDIR)/sim/test_mem_dev.v

#DUT
VERILOG_SOURCES += $(TOPDIR)/rtl/dma.v
VERILOG_SOURCES += $(TOPDIR)/rtl/wb_dma.v

#Test Benches
VERILOG_SOURCES += $(TOPDIR)/cocotb/tb_cocotb.v

TOPLEVEL = tb_cocotb

GPI_IMPL := vpi

export TOPLEVEL_LANG
MODULE=test_dma

include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim

wave:
	gtkwave waveforms.gtkw &
