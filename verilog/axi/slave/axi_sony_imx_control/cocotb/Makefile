
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
VERILOG_SOURCES = $(NYSA)/verilog/generic/axi_lite_slave.v
VERILOG_SOURCES += $(NYSA)/verilog/generic/cross_clock_strobe.v
VERILOG_SOURCES += $(TOPDIR)/rtl/axi_sony_imx_control.v
VERILOG_SOURCES += $(TOPDIR)/rtl/rxd_to_rbuf.v
VERILOG_SOURCES += $(NYSA)/verilog/generic/blk_mem.v
VERILOG_SOURCES += $(NYSA)/verilog/generic/adapter_bram_2_axi_stream.v

#Test Benches
VERILOG_SOURCES += $(TOPDIR)/cocotb/rxd_to_rbuf_8test.v
VERILOG_SOURCES += $(TOPDIR)/cocotb/rxd_to_rbuf_10test.v
VERILOG_SOURCES += $(TOPDIR)/cocotb/rxd_to_rbuf_12test.v
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


