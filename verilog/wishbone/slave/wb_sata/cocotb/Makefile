
TOPLEVEL_LANG ?= verilog
PWD=$(shell pwd)
TOPDIR=$(PWD)/..
COCOTB		:= $(shell $(python) nysa paths -c -s)
NYSA		:= $(shell $(python) nysa paths -s -v nysa-verilog)
NYSA_SATA	:= $(shell $(python) nysa paths -s -v nysa-sata)
PYTHONPATH 	:= ./model:$(PYTHONPATH)
export PYTHONPATH


EXTRA_ARGS+=-I$(TOPDIR)/rtl/ -I$(NYSA)/verilog/ -I${NYSA_SATA}/rtl/ -I$(TOPDIR)/../wb_dma/rtl/

#Dependencies
VERILOG_SOURCES =  $(NYSA)/verilog/generic/blk_mem.v
VERILOG_SOURCES += ${NYSA}/verilog/generic/dpb.v
VERILOG_SOURCES += ${NYSA}/verilog/generic/cross_clock_strobe.v
VERILOG_SOURCES += $(NYSA)/verilog/generic/cross_clock_enable.v
VERILOG_SOURCES += $(NYSA)/verilog/generic/ppfifo.v
VERILOG_SOURCES += $(NYSA)/verilog/wishbone/master/wishbone_master.v
VERILOG_SOURCES += ${TOPDIR}/sim/wishbone_interconnect.v
VERILOG_SOURCES += $(NYSA)/verilog/generic/debounce.v

VERILOG_SOURCES += $(NYSA_SATA)/rtl/link/cont_controller.v
VERILOG_SOURCES += $(NYSA_SATA)/rtl/link/crc.v
VERILOG_SOURCES += $(NYSA_SATA)/rtl/link/sata_link_layer.v
VERILOG_SOURCES += $(NYSA_SATA)/rtl/link/sata_link_layer_read.v
VERILOG_SOURCES += $(NYSA_SATA)/rtl/link/sata_link_layer_write.v
VERILOG_SOURCES += $(NYSA_SATA)/rtl/link/scrambler.v
VERILOG_SOURCES += $(NYSA_SATA)/rtl/phy/oob_controller.v
VERILOG_SOURCES += $(NYSA_SATA)/rtl/phy/sata_phy_layer.v
VERILOG_SOURCES += $(NYSA_SATA)/rtl/transport/sata_transport_layer.v
VERILOG_SOURCES += $(NYSA_SATA)/rtl/command/sata_command_layer.v
VERILOG_SOURCES += $(NYSA_SATA)/rtl/sata_stack.v

VERILOG_SOURCES += $(NYSA_SATA)/sim/faux_sata_hd_phy.v
VERILOG_SOURCES += $(NYSA_SATA)/sim/faux_sata_hd_transport.v
VERILOG_SOURCES += $(NYSA_SATA)/sim/faux_sata_hd_command_layer.v
VERILOG_SOURCES += $(NYSA_SATA)/sim/faux_sata_hd.v

VERILOG_SOURCES += $(NYSA_SATA)/sim/test_in.v
VERILOG_SOURCES += $(NYSA_SATA)/sim/test_out.v

VERILOG_SOURCES += $(NYSA_SATA)/sim/hd_data_reader.v
VERILOG_SOURCES += $(NYSA_SATA)/sim/hd_data_writer.v


VERILOG_SOURCES += $(NYSA)/verilog/wishbone/slave/wb_test_dma_mem/rtl/test_mem_dev.v
VERILOG_SOURCES += $(NYSA)/verilog/wishbone/slave/wb_test_dma_mem/rtl/wb_test_dma_mem.v


#Simulation Devices
VERILOG_SOURCES += ${TOPDIR}/rtl/sata_dma_interface.v
VERILOG_SOURCES += ${TOPDIR}/rtl/wb_sata.v
#VERILOG_SOURCES += $(NYSA)/verilog/wishbone/slave/wb_test_dma_mem/rtl/test_mem_dev.v
#VERILOG_SOURCES += $(NYSA)/verilog/wishbone/slave/wb_test_dma_mem/rtl/wb_test_dma_mem.v
#VERILOG_SOURCES += $(TOPDIR)/sim/test_mem_dev.v

#DUT
VERILOG_SOURCES += $(TOPDIR)/../wb_dma/rtl/dma.v
VERILOG_SOURCES += $(TOPDIR)/../wb_dma/rtl/wb_dma.v

#Test Benches
VERILOG_SOURCES += $(TOPDIR)/cocotb/tb_cocotb.v

TOPLEVEL = tb_cocotb

GPI_IMPL := vpi

export TOPLEVEL_LANG
MODULE=test_sata

include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim

wave:
	gtkwave waveforms.gtkw &
