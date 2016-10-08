
TOPLEVEL_LANG ?= verilog
PWD=$(shell pwd)
TOPDIR=$(PWD)/..
COCOTB 	:= $(shell $(python) nysa paths -c -s)
NYSA 	:= $(shell $(python) nysa paths -s -v nysa-verilog)
PYTHONPATH := ./model:$(PYTHONPATH)
export PYTHONPATH
export PYTHONHOME=$(shell python -c "from distutils.sysconfig import get_config_var; print(get_config_var('prefix'))")

EXTRA_ARGS+=-I$(TOPDIR)/rtl/ -I$(NYSA)/verilog/ -I$(TOPDIR)/sim/

#Dependencies
VERILOG_SOURCES = $(NYSA)/verilog/wishbone/master/wishbone_master.v

VERILOG_SOURCES += ${NYSA}/verilog/generic/uart_v3.v
VERILOG_SOURCES += ${NYSA}/verilog/wishbone/host_interface/uart/uart_io_handler.v
VERILOG_SOURCES += ${NYSA}/verilog/generic/bram.v
VERILOG_SOURCES += ${NYSA}/verilog/wishbone/slave/wb_bram/rtl/wb_bram.v
VERILOG_SOURCES += $(NYSA)/verilog/sim/wishbone/interconnect/example_2port_interconnect/wishbone_interconnect.v
VERILOG_SOURCES += ${TOPDIR}/sim/arbiter_2_masters.v
VERILOG_SOURCES += ${TOPDIR}/sim/wishbone_mem_interconnect.v

#Simulation Devices
VERILOG_SOURCES += ${TOPDIR}/rtl/uart_if_tester.v
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


