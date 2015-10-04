
TOPLEVEL_LANG ?= verilog
PWD=$(shell pwd)
TOPDIR=$(PWD)/..
COCOTB 			:= $(shell $(python) nysa paths -c -s)
NYSA 				:= $(shell $(python) nysa paths -s -v nysa-verilog)
SDIO_BASE		:= ${TOPDIR}/rtl/sdio-device-master/rtl
PYTHONPATH 	:= ./model:$(PYTHONPATH)
export PYTHONPATH

EXTRA_ARGS+=-I$(TOPDIR)/rtl/ -I$(NYSA)/verilog/ -I${SDIO_BASE}/ -I${SDIO_BASE}/cia/ -D COCOTB_SIMULATION


#Dependencies
VERILOG_SOURCES = $(NYSA)/verilog/wishbone/master/wishbone_master.v

VERILOG_SOURCES += ${NYSA}/verilog/generic/dpb.v
VERILOG_SOURCES += ${NYSA}/verilog/generic/cross_clock_enable.v
VERILOG_SOURCES += ${NYSA}/verilog/generic/blk_mem.v
VERILOG_SOURCES += ${NYSA}/verilog/generic/ppfifo.v


VERILOG_SOURCES += ${NYSA}/verilog/generic/bram.v
VERILOG_SOURCES += ${NYSA}/verilog/wishbone/slave/wb_bram/rtl/wb_bram.v
VERILOG_SOURCES += $(NYSA)/verilog/sim/wishbone/interconnect/example_2port_interconnect/wishbone_interconnect.v
VERILOG_SOURCES += ${TOPDIR}/sim/arbiter_2_masters.v
VERILOG_SOURCES += ${TOPDIR}/sim/wishbone_mem_interconnect.v

VERILOG_SOURCES += ${SDIO_BASE}/cia/sdio_cccr.v
VERILOG_SOURCES += ${SDIO_BASE}/cia/sdio_cia.v
VERILOG_SOURCES += ${SDIO_BASE}/cia/sdio_cis.v
VERILOG_SOURCES += ${SDIO_BASE}/cia/sdio_fbr.v

VERILOG_SOURCES += ${SDIO_BASE}/control/sdio_card_control.v

VERILOG_SOURCES += ${SDIO_BASE}/generic/crc16.v
VERILOG_SOURCES += ${SDIO_BASE}/generic/crc7.v
VERILOG_SOURCES += ${SDIO_BASE}/phy/sdio_phy.v
VERILOG_SOURCES += ${SDIO_BASE}/phy/sdio_data_phy.v

VERILOG_SOURCES += ${SDIO_BASE}/platform/sd_dev_platform_cocotb.v
VERILOG_SOURCES += ${SDIO_BASE}/sdio_data_control.v
VERILOG_SOURCES += ${SDIO_BASE}/sdio_device_stack.v


VERILOG_SOURCES += ${TOPDIR}/rtl/sdio_memory_function.v
#Add the sources for sdio device

#Simulation Devices
VERILOG_SOURCES += ${TOPDIR}/rtl/wb_sdio_device.v
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


