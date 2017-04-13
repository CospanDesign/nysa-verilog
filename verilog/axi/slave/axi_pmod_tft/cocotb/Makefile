
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
#VERILOG_SOURCES += $(NYSA)/verilog/generic/adapter_axi_stream_2_ppfifo.v
VERILOG_SOURCES += $(NYSA)/verilog/generic/axi_lite_slave.v
VERILOG_SOURCES += $(TOPDIR)/rtl/adapter_axi_stream_2_ppfifo_wl.v
VERILOG_SOURCES += $(TOPDIR)/rtl/pixel_reader.v
VERILOG_SOURCES += $(TOPDIR)/rtl/nh_lcd.v
VERILOG_SOURCES += $(TOPDIR)/rtl/nh_lcd_command.v
VERILOG_SOURCES += $(TOPDIR)/rtl/nh_lcd_data_writer.v

#DUT
VERILOG_SOURCES += $(TOPDIR)/rtl/axi_pmod_tft.v

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


