
TOPLEVEL_LANG ?= verilog
PWD=$(shell pwd)
TOPDIR=$(PWD)/..
COCOTB 	:= $(shell $(python) nysa paths -c -s)
NYSA 	:= $(shell $(python) nysa paths -s -v nysa-verilog)
PYTHONPATH := ./model:$(PYTHONPATH)
export PYTHONPATH
export PYTHONHOME=$(shell python -c "from distutils.sysconfig import get_config_var; print(get_config_var('prefix'))")

EXTRA_ARGS+=-I$(TOPDIR)/rtl/ -I$(NYSA)/verilog/ -I${NYSA_SATA}/rtl/ -I$(TOPDIR)/../wb_dma/rtl/

#Dependencies
VERILOG_SOURCES =  $(NYSA)/verilog/generic/blk_mem.v
VERILOG_SOURCES += ${NYSA}/verilog/generic/dpb.v
VERILOG_SOURCES += ${NYSA}/verilog/generic/cross_clock_strobe.v
VERILOG_SOURCES += $(NYSA)/verilog/generic/cross_clock_enable.v
VERILOG_SOURCES += $(NYSA)/verilog/generic/ppfifo.v
VERILOG_SOURCES += $(NYSA)/verilog/wishbone/master/wishbone_master.v
VERILOG_SOURCES += ${TOPDIR}/sim/wishbone_interconnect.v

VERILOG_SOURCES += ${NYSA}/verilog/generic/bram.v
VERILOG_SOURCES += ${NYSA}/verilog/wishbone/slave/wb_bram/rtl/wb_bram.v
VERILOG_SOURCES += ${TOPDIR}/sim/arbiter_2_masters.v
VERILOG_SOURCES += ${TOPDIR}/sim/wishbone_mem_interconnect.v

VERILOG_SOURCES += $(NYSA)/verilog/wishbone/slave/wb_test_dma_mem/rtl/test_mem_dev.v
VERILOG_SOURCES += $(NYSA)/verilog/wishbone/slave/wb_test_dma_mem/rtl/wb_test_dma_mem.v

#DMA
VERILOG_SOURCES += $(TOPDIR)/../wb_dma/rtl/dma.v
VERILOG_SOURCES += $(TOPDIR)/../wb_dma/rtl/wb_dma.v

#Simulation Devices
VERILOG_SOURCES += ${TOPDIR}/rtl/hs_demo.v
VERILOG_SOURCES += ${TOPDIR}/rtl/wb_hs_demo.v

#DUT
#Test Benches
VERILOG_SOURCES += $(TOPDIR)/cocotb/tb_cocotb.v

TOPLEVEL = tb_cocotb

GPI_IMPL := vpi

export TOPLEVEL_LANG
MODULE=test_dut

include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim

.PHONY: wave test
wave:
	gtkwave waveforms.gtkw &


