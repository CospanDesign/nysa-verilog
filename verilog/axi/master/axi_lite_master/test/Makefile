
TOPLEVEL_LANG ?= verilog
PWD=$(shell pwd)
TOPDIR=$(PWD)/..
BASE_DIR=$(PWD)/../../../../..
AXI_DIR=$(PWD)/../../..
PYTHONPATH := ./model:$(PYTHONPATH)
export PYTHONPATH
export PYTHONHOME=$(shell python -c "from distutils.sysconfig import get_config_var; print(get_config_var('prefix'))")


#EXTRA_ARGS+=-I$(TOPDIR)/rtl/ -I$(BASE_DIR) -I$(AXI_DIR) -Wimplicit -Wimplicit-dimensions -Wportbind -Wtimescale -Wselect-range
EXTRA_ARGS+=-I$(TOPDIR) -I$(BASE_DIR) -I$(AXI_DIR) -Wimplicit -Wimplicit-dimensions -Wtimescale -Wselect-range

#DUT
VERILOG_SOURCES = $(TOPDIR)/axi_lite_master.v

#Test Benches
VERILOG_SOURCES += $(TOPDIR)/test/tb_cocotb.v

TOPLEVEL = tb_cocotb

GPI_IMPL := vpi

export TOPLEVEL_LANG
MODULE=test_dut

include $(shell cocotb-config --makefiles)/Makefile.inc
include $(shell cocotb-config --makefiles)/Makefile.sim


.PHONY: wave test
wave:
	gtkwave waveforms.gtkw &


