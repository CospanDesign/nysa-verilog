
TOPLEVEL_LANG ?= verilog
PWD=$(shell pwd)
TOPDIR=$(PWD)/..
#COCOTB 	:= $(shell $(python) nysa paths -c -s)
#NYSA 	:= $(shell $(python) nysa paths -s -v nysa-verilog)
COCOTB := ~/Projects/cocotb
NYSA := ../../../../../
PYTHONPATH := ./model:$(PYTHONPATH)
export PYTHONPATH
export PYTHONHOME=$(shell python -c "from distutils.sysconfig import get_config_var; print(get_config_var('prefix'))")

EXTRA_ARGS+=-I$(TOPDIR)/rtl/ -I$(NYSA)/verilog/axi/ -Wall


#DUT
VERILOG_SOURCES = $(NYSA)/verilog/generic/axi_lite_slave.v
VERILOG_SOURCES += $(TOPDIR)/rtl/i2c_master_bit_ctrl.v
VERILOG_SOURCES += $(TOPDIR)/rtl/i2c_master_byte_ctrl.v
VERILOG_SOURCES += $(TOPDIR)/rtl/i2c_master_defines.v
VERILOG_SOURCES += $(TOPDIR)/rtl/i2c_master_top.v
VERILOG_SOURCES += $(TOPDIR)/rtl/axi_lite_i2c.v

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


