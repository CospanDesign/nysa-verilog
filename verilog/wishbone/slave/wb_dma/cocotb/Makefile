
TOPLEVEL_LANG ?= verilog
PWD=$(shell pwd)
TOPDIR=$(PWD)/..
COCOTB=/home/cospan/Projects/cocotb
NYSA=/home/cospan/Projects/nysa-verilog
PYTHONPATH := ./model:$(PYTHONPATH)
export PYTHONPATH


EXTRA_ARGS+=-I$(TOPDIR)/rtl/

#Dependencies
VERILOG_SOURCES = $(NYSA)/verilog/generic/blk_mem.v
VERILOG_SOURCES += $(NYSA)/verilog/generic/cross_clock_enable.v
VERILOG_SOURCES += $(NYSA)/verilog/generic/ppfifo.v

#Simulation Devices
VERILOG_SOURCES += $(TOPDIR)/sim/test_mem_dev.v

#DUT
VERILOG_SOURCES += $(TOPDIR)/rtl/dma.v
VERILOG_SOURCES += $(TOPDIR)/rtl/wb_dma.v

#Test Benches
VERILOG_SOURCES += $(TOPDIR)/cocotb/tb_cocotb.v

TOPLEVEL = tb_cocotb

GPI_IMPL := vpi

export TOPLEVEL_LANG
MODULE=tb_cocotb

include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim

wave:
	gtkwave waveforms.gtkw &
