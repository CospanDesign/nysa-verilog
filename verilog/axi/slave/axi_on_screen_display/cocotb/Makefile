
TOPLEVEL_LANG ?= verilog
PWD=$(shell pwd)
TOPDIR=$(PWD)/..
COCOTB 	:= $(shell $(python) nysa paths -c -s)
NYSA 	:= $(shell $(python) nysa paths -s -v nysa-verilog)
PYTHONPATH := ./model:$(PYTHONPATH)
export PYTHONPATH
export PYTHONHOME=$(shell python -c "from distutils.sysconfig import get_config_var; print(get_config_var('prefix'))")

EXTRA_ARGS+=-I$(TOPDIR)/rtl/ -I$(NYSA)/verilog/axi/

VERILOG_SOURCES =  $(NYSA)/verilog/generic/ppfifo.v
VERILOG_SOURCES += $(NYSA)/verilog/generic/axi_lite_slave.v
VERILOG_SOURCES += $(NYSA)/verilog/generic/adapter_ppfifo_2_axi_stream.v
VERILOG_SOURCES += $(NYSA)/verilog/generic/bram.v
VERILOG_SOURCES += $(TOPDIR)/rtl/character_buffer.v
VERILOG_SOURCES += $(TOPDIR)/rtl/console_osd.v

#DUT
VERILOG_SOURCES += $(TOPDIR)/rtl/axi_on_screen_display.v

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


