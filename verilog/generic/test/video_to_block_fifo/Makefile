
TOPLEVEL_LANG ?= verilog
PWD=$(shell pwd)
TOPDIR=$(PWD)/..
COCOTB 	:= $(shell $(python) nysa paths -c -s)
NYSA 	:= $(shell $(python) nysa paths -s -v nysa-verilog)
PYTHONPATH := ./model:$(PYTHONPATH)
export PYTHONPATH
export PYTHONHOME=$(shell python -c "from distutils.sysconfig import get_config_var; print(get_config_var('prefix'))")

EXTRA_ARGS+= -Wall -I$(NYSA)/verilog/axi



VERILOG_SOURCES =   	./rgb_generator.v
VERILOG_SOURCES +=   	../../block_fifo.v
VERILOG_SOURCES +=   	../../video_to_block_fifo.v
VERILOG_SOURCES +=   	../../adapter_ppfifo_2_axi_stream.v

#Test Benches
VERILOG_SOURCES += tb_cocotb.v

TOPLEVEL = tb_cocotb

GPI_IMPL := vpi

export TOPLEVEL_LANG
MODULE=test_dut

include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim

.PHONY: wave test
wave:
	gtkwave waveforms.gtkw &


