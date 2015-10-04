
TOPLEVEL_LANG ?= verilog
PWD=$(shell pwd)
TOPDIR=$(PWD)/..
COCOTB 	:= $(shell $(python) nysa paths -c -s)
NYSA 	:= $(shell $(python) nysa paths -s -v nysa-verilog)
PYTHONPATH := ./model:$(PYTHONPATH)
export PYTHONPATH

EXTRA_ARGS+=-I$(TOPDIR)/rtl/ -I$(TOPDIR)/rtl/cia -I$(NYSA)/verilog/

#Dependencies

#Simulation Devices
VERILOG_SOURCES += $(NYSA)/verilog/generic/blk_mem.v
VERILOG_SOURCES += $(TOPDIR)/sim/demo_function.v
VERILOG_SOURCES += $(TOPDIR)/rtl/generic/crc7.v
VERILOG_SOURCES += $(TOPDIR)/rtl/generic/crc16.v
VERILOG_SOURCES += $(TOPDIR)/rtl/cia/sdio_fbr.v
VERILOG_SOURCES += $(TOPDIR)/rtl/cia/sdio_cccr.v
VERILOG_SOURCES += $(TOPDIR)/rtl/cia/sdio_cis.v
VERILOG_SOURCES += $(TOPDIR)/rtl/cia/sdio_cia.v
VERILOG_SOURCES += $(TOPDIR)/rtl/control/sdio_card_control.v
VERILOG_SOURCES += $(TOPDIR)/rtl/phy/sdio_phy.v
VERILOG_SOURCES += $(TOPDIR)/rtl/sdio_device_stack.v

#VERILOG_SOURCES += $(TOPDIR)/rtl/sdio_device_phy_sd_hs.v
#VERILOG_SOURCES += $(TOPDIR)/rtl/sdio_device_phy_sd_ls.v
#VERILOG_SOURCES += $(TOPDIR)/rtl/sdio_device_phy_spi.v
#VERILOG_SOURCES += $(TOPDIR)/rtl/cia/sdio_device_cccr.v
#VERILOG_SOURCES += ${TOPDIR}/rtl/wb_sdio_device.v
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


