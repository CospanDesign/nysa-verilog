
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
VERILOG_SOURCES += $(TOPDIR)/rtl/crc7.v
VERILOG_SOURCES += $(TOPDIR)/rtl/crc16.v

VERILOG_SOURCES += $(TOPDIR)/rtl/sdio_device_phy_sd_hs.v
VERILOG_SOURCES += $(TOPDIR)/rtl/sdio_device_phy_sd_ls.v
VERILOG_SOURCES += $(TOPDIR)/rtl/sdio_device_phy_spi.v
VERILOG_SOURCES += $(TOPDIR)/rtl/sdio_device_phy.v
VERILOG_SOURCES += $(TOPDIR)/rtl/sdio_device_data_link.v
VERILOG_SOURCES += $(TOPDIR)/rtl/sdio_device_stack.v
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


