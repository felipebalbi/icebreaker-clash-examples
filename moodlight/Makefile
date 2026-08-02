##----------------------------------------------------------------------------##
#   Project Settings                                                           #
##----------------------------------------------------------------------------##
#
# Two-stage build, as in the sibling blinky example:
#
#   Stage 1  Clash + GHC compile src/ and emit Verilog   (cabal)
#   Stage 2  yosys -> nextpnr-ice40 -> icepack -> iceprog (this Makefile)
#
# The SB_RGBA_DRV hard block the RGB pins require comes from ice40-prim as a
# Clash blackbox, so there is no hand-written HDL and no wrapper module: the
# Clash top entity is also the synthesis top, exactly as in blinky.

NAME = MoodLight
TOP = topEntity
BUILDDIR = _build/$(NAME)

PCF ?= icebreaker.pcf

PNR_FLAGS = \
	--up5k \
	--package sg48 \
	--pcf $(PCF) \
	--freq 12

-include build.cfg
-include build.cfg.local

##----------------------------------------------------------------------------##
#   Build Rules                                                                #
##----------------------------------------------------------------------------##

default: bitstream

upload: $(BUILDDIR)/03-bitstream/$(TOP).bin
	$(PROG) $<

synth: $(BUILDDIR)/02-net/$(TOP).json

netlist: $(BUILDDIR)/03-bitstream/$(TOP).asc

bitstream: $(BUILDDIR)/03-bitstream/$(TOP).bin

# 4. Pack (ASC -> BIN)
$(BUILDDIR)/03-bitstream/$(TOP).bin: $(BUILDDIR)/03-bitstream/$(TOP).asc
	$(PACK) $< $@

# 3. Place & route (JSON -> ASC)
$(BUILDDIR)/03-bitstream/$(TOP).asc: $(BUILDDIR)/02-net/$(TOP).json $(PCF)
	mkdir -p $(BUILDDIR)/03-bitstream
	$(PNR) --json $< --asc $@ $(PNR_FLAGS)

# 2. Synthesis (Verilog -> JSON).
$(BUILDDIR)/02-net/$(TOP).json: $(BUILDDIR)/01-hdl/$(TOP).vg
	mkdir -p $(BUILDDIR)/02-net $(BUILDDIR)/log
	$(YOSYS) \
		-l $(BUILDDIR)/log/synth.log \
		-p 'read_verilog $(BUILDDIR)/01-hdl/*.vg; synth_ice40 -top $(TOP) -json $@'

# 1b. Stage the Clash HDL, renaming .v to .vg.
#
#     tokei maps .v to Coq, whose comment syntax is (* *), so it counts
#     Verilog's /* */ and // as code. .vg is tokei's Verilog extension, so the
#     generated HDL gets counted as Verilog rather than silently as Coq.
$(BUILDDIR)/01-hdl/$(TOP).vg: verilog/$(NAME).$(TOP)/$(TOP).v
	mkdir -p $(BUILDDIR)
	rm -Rf $(BUILDDIR)/01-hdl
	cp -a verilog/$(NAME).$(TOP) $(BUILDDIR)/01-hdl
	mv $(BUILDDIR)/01-hdl/$(TOP).v $@

# 1a. Generate Verilog from Clash.
verilog/$(NAME).$(TOP)/$(TOP).v: $(shell find src -name '*.hs')
	$(CLASH) $(NAME) --verilog

##----------------------------------------------------------------------------##
#   Tests                                                                      #
##----------------------------------------------------------------------------##

test:
	$(TEST)

##----------------------------------------------------------------------------##
#   Formatting (fourmolu)                                                      #
##----------------------------------------------------------------------------##

HS = $(wildcard src/*.hs src/*/*.hs tests/*.hs tests/*/*.hs bin/*.hs)

format:
	$(FOURMOLU) --mode inplace $(HS)

format-check:
	$(FOURMOLU) --check-idempotence --mode check $(HS)

##----------------------------------------------------------------------------##
#   Cleanup                                                                    #
##----------------------------------------------------------------------------##

clean:
	rm -Rf _build verilog

##----------------------------------------------------------------------------##
#   Special Targets                                                            #
##----------------------------------------------------------------------------##

.PHONY: default clean upload synth netlist bitstream test format format-check
.SECONDARY:
