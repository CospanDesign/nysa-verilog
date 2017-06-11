
TOPLEVEL_LANG ?= verilog
PWD=$(shell pwd)
TOPDIR=$(PWD)/..
COCOTB 	:= $(shell $(python) nysa paths -c -s)
NYSA 	:= $(shell $(python) nysa paths -s -v nysa-verilog)
PYTHONPATH := ./model:$(PYTHONPATH)
export PYTHONPATH
export PYTHONHOME=$(shell python -c "from distutils.sysconfig import get_config_var; print(get_config_var('prefix'))")

EXTRA_ARGS+=-I$(TOPDIR)/rtl/ -I$(NYSA)/verilog/axi/


#DUT
VERILOG_SOURCES =  $(NYSA)/verilog/generic/axi_lite_slave.v
VERILOG_SOURCES += $(NYSA)/verilog/generic/block_fifo.v
VERILOG_SOURCES += $(NYSA)/verilog/generic/adapter_ppfifo_2_axi_stream.v


VERILOG_SOURCES += $(TOPDIR)/rtl/nes_hci.v
VERILOG_SOURCES += $(TOPDIR)/rtl/cart/cart.v

VERILOG_SOURCES += $(TOPDIR)/rtl/cmn/block_ram/dual_port_ram_sync.v
VERILOG_SOURCES += $(TOPDIR)/rtl/cmn/block_ram/single_port_ram_sync.v

VERILOG_SOURCES += $(TOPDIR)/rtl/cmn/fifo/fifo.v
VERILOG_SOURCES += $(TOPDIR)/rtl/cmn/vga_sync/vga_sync.v

VERILOG_SOURCES += $(TOPDIR)/rtl/image_to_ppfifo.v
VERILOG_SOURCES += $(TOPDIR)/rtl/cpu/apu/apu.v
VERILOG_SOURCES += $(TOPDIR)/rtl/cpu/apu/apu_div.v
VERILOG_SOURCES += $(TOPDIR)/rtl/cpu/apu/apu_envelope_generator.v
VERILOG_SOURCES += $(TOPDIR)/rtl/cpu/apu/apu_frame_counter.v
VERILOG_SOURCES += $(TOPDIR)/rtl/cpu/apu/apu_length_counter.v
VERILOG_SOURCES += $(TOPDIR)/rtl/cpu/apu/apu_mixer.v
VERILOG_SOURCES += $(TOPDIR)/rtl/cpu/apu/apu_noise.v
VERILOG_SOURCES += $(TOPDIR)/rtl/cpu/apu/apu_pulse.v
VERILOG_SOURCES += $(TOPDIR)/rtl/cpu/apu/apu_triangle.v

VERILOG_SOURCES += $(TOPDIR)/rtl/cpu/cpu.v
VERILOG_SOURCES += $(TOPDIR)/rtl/cpu/jp.v
VERILOG_SOURCES += $(TOPDIR)/rtl/cpu/rp2a03.v
VERILOG_SOURCES += $(TOPDIR)/rtl/cpu/sprdma.v

VERILOG_SOURCES += $(TOPDIR)/rtl/ppu/rgb_generator.v
VERILOG_SOURCES += $(TOPDIR)/rtl/ppu/ppu.v
VERILOG_SOURCES += $(TOPDIR)/rtl/ppu/ppu_bg.v
VERILOG_SOURCES += $(TOPDIR)/rtl/ppu/ppu_ri.v
VERILOG_SOURCES += $(TOPDIR)/rtl/ppu/ppu_spr.v
VERILOG_SOURCES += $(TOPDIR)/rtl/ppu/ppu_vga.v

VERILOG_SOURCES += $(TOPDIR)/rtl/vram.v
VERILOG_SOURCES += $(TOPDIR)/rtl/wram.v
VERILOG_SOURCES += $(TOPDIR)/rtl/nes_top.v
VERILOG_SOURCES += $(TOPDIR)/rtl/axi_nes.v

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


