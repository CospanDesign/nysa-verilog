
TOPLEVEL_LANG ?= verilog
PWD=$(shell pwd)
TOPDIR=$(PWD)/..
COCOTB 	:= $(shell $(python) nysa paths -c -s)
NYSA 	:= $(shell $(python) nysa paths -s -v nysa-verilog)
PYTHONPATH := ./model:$(PYTHONPATH)
export PYTHONPATH

EXTRA_ARGS+=-I$(TOPDIR)/rtl/ -I$(NYSA)/verilog/

#Dependencies
VERILOG_SOURCES = $(NYSA)/verilog/wishbone/master/wishbone_master.v
VERILOG_SOURCES += $(NYSA)/verilog/sim/wishbone/interconnect/example_2port_interconnect/wishbone_interconnect.v

#Simulation Devices



VERILOG_SOURCES += ${NYSA}/verilog/wishbone/common/wb_mem_2_ppfifo/rtl/wb_mem_2_ppfifo.v
VERILOG_SOURCES += ${NYSA}/verilog/wishbone/common/wb_ppfifo_2_mem/rtl/wb_ppfifo_2_mem.v
VERILOG_SOURCES += ${NYSA}/verilog/generic/cross_clock_enable.v
VERILOG_SOURCES += ${NYSA}/verilog/generic/blk_mem.v
VERILOG_SOURCES += ${NYSA}/verilog/generic/ppfifo.v
VERILOG_SOURCES += ${TOPDIR}/rtl/sd_bd.v
VERILOG_SOURCES += ${TOPDIR}/rtl/sd_clock_divider.v
VERILOG_SOURCES += ${TOPDIR}/rtl/sd_cmd_master.v
VERILOG_SOURCES += ${TOPDIR}/rtl/sd_crc_16.v
VERILOG_SOURCES += ${TOPDIR}/rtl/sd_crc_7.v
VERILOG_SOURCES += ${TOPDIR}/rtl/sd_cmd_serial_host.v
VERILOG_SOURCES += ${TOPDIR}/rtl/sd_controller_wb.v
VERILOG_SOURCES += ${TOPDIR}/rtl/sd_data_master.v
VERILOG_SOURCES += ${TOPDIR}/rtl/sd_data_serial_host.v

VERILOG_SOURCES += ${TOPDIR}/rtl/sd_rx_fifo.v
#VERILOG_SOURCES += ${TOPDIR}/rtl/sd_rx_fifo_tb.v
VERILOG_SOURCES += ${TOPDIR}/rtl/sd_tx_fifo.v
VERILOG_SOURCES += ${TOPDIR}/rtl/sd_fifo_rx_filler.v
VERILOG_SOURCES += ${TOPDIR}/rtl/sd_fifo_tx_filler.v
#VERILOG_SOURCES += ${TOPDIR}/rtl/sdc_controller.v

VERILOG_SOURCES += ${TOPDIR}/rtl/wb_sdio_host.v
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


