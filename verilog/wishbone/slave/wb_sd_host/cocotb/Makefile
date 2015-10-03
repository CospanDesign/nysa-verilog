
TOPLEVEL_LANG ?= verilog
PWD=$(shell pwd)
TOPDIR=$(PWD)/..
COCOTB	:= $(shell $(python) nysa paths -c -s)
NYSA		:= $(shell $(python) nysa paths -s -v nysa-verilog)
SDIO_DEV:= $(shell $(python) nysa paths -s -v sdio-device)
XILINX 	:= $(shell $(python) nysa paths -s -x)
PYTHONPATH := ./model:$(PYTHONPATH)
export PYTHONPATH

EXTRA_ARGS+=-I$(TOPDIR)/rtl/ -I$(NYSA)/verilog/ -DSIMULATION -DCOCOTB_WORKAROUND -I${SDIO_DEV}/rtl/ -I${SDIO_DEV}/rtl/cia -DCOCOTB_SIMULATION

#Dependencies
VERILOG_SOURCES = $(NYSA)/verilog/wishbone/master/wishbone_master.v
VERILOG_SOURCES += $(NYSA)/verilog/sim/wishbone/interconnect/example_2port_interconnect/wishbone_interconnect.v

#Simulation Devices

#RAM
VERILOG_SOURCES += ${NYSA}/verilog/generic/bram.v
VERILOG_SOURCES += ${NYSA}/verilog/wishbone/slave/wb_bram/rtl/wb_bram.v

VERILOG_SOURCES += ${TOPDIR}/sim/arbiter_2_masters.v
VERILOG_SOURCES += ${TOPDIR}/sim/wishbone_mem_interconnect.v
VERILOG_SOURCES += ${NYSA}/verilog/wishbone/common/wb_mem_2_ppfifo/rtl/wb_mem_2_ppfifo.v
VERILOG_SOURCES += ${NYSA}/verilog/wishbone/common/wb_ppfifo_2_mem/rtl/wb_ppfifo_2_mem.v
VERILOG_SOURCES += ${NYSA}/verilog/generic/cross_clock_enable.v
VERILOG_SOURCES += ${NYSA}/verilog/generic/blk_mem.v
VERILOG_SOURCES += ${NYSA}/verilog/generic/ppfifo.v
VERILOG_SOURCES += ${TOPDIR}/rtl/generic/sd_crc_16.v
VERILOG_SOURCES += ${TOPDIR}/rtl/generic/sd_crc_7.v

#SDIO Device
VERILOG_SOURCES += ${SDIO_DEV}/rtl/platform/sd_dev_platform_cocotb.v
VERILOG_SOURCES += ${SDIO_DEV}/rtl/sdio_data_control.v
VERILOG_SOURCES += $(SDIO_DEV)/sim/demo_function.v
VERILOG_SOURCES += $(SDIO_DEV)/rtl/generic/crc7.v
VERILOG_SOURCES += $(SDIO_DEV)/rtl/generic/crc16.v
VERILOG_SOURCES += $(SDIO_DEV)/rtl/cia/sdio_fbr.v
VERILOG_SOURCES += $(SDIO_DEV)/rtl/cia/sdio_cccr.v
VERILOG_SOURCES += $(SDIO_DEV)/rtl/cia/sdio_cis.v
VERILOG_SOURCES += $(SDIO_DEV)/rtl/cia/sdio_cia.v
VERILOG_SOURCES += $(SDIO_DEV)/rtl/control/sdio_card_control.v
VERILOG_SOURCES += $(SDIO_DEV)/rtl/phy/sdio_phy.v
VERILOG_SOURCES += $(SDIO_DEV)/rtl/phy/sdio_data_phy.v
VERILOG_SOURCES += $(SDIO_DEV)/rtl/sdio_device_stack.v

#SD Host
VERILOG_SOURCES += ${TOPDIR}/rtl/platform/sd_host_platform_cocotb.v
VERILOG_SOURCES += ${TOPDIR}/rtl/sd_host_defines.v
VERILOG_SOURCES += ${TOPDIR}/rtl/phy/sd_sd4_phy.v
VERILOG_SOURCES += ${TOPDIR}/rtl/phy/sd_phy_layer.v
VERILOG_SOURCES += ${TOPDIR}/rtl/cmd/sd_cmd_layer.v
VERILOG_SOURCES += ${TOPDIR}/rtl/sd_host_stack.v
VERILOG_SOURCES += ${TOPDIR}/rtl/wb_sd_host.v


#DUT
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


