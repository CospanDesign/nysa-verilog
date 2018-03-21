
TOPLEVEL_LANG ?= verilog
PWD=$(shell pwd)
TOPDIR=$(PWD)/..
COCOTB := ~/Projects/cocotb
NYSA := ../../../../../

PYTHONPATH := ./model:$(PYTHONPATH)
export PYTHONPATH
export PYTHONHOME=$(shell python -c "from distutils.sysconfig import get_config_var; print(get_config_var('prefix'))")

EXTRA_ARGS+=-I$(TOPDIR)/rtl/ -I$(NYSA)/verilog/axi/ -DSIMULATION -DBUS_WIDTH=8

#DUT
VERILOG_SOURCES = $(NYSA)/verilog/generic/blk_mem.v
VERILOG_SOURCES += $(TOPDIR)/rtl/axis_to_bram.v
VERILOG_SOURCES += $(TOPDIR)/rtl/bram_to_axis.v
VERILOG_SOURCES += $(TOPDIR)/rtl/axi_master_bram.v

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


