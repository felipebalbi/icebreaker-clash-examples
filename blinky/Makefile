##----------------------------------------------------------------------------##
#   Project Settings                                                           #
##----------------------------------------------------------------------------##
#
# Two-stage build, mirroring the upstream clash-starters `orangecrab` project
# but retargeted from the ECP5 to the iCE40 (iCEbreaker) toolchain:
#
#   Stage 1  Clash + GHC compile src/ and emit Verilog   (stack)
#   Stage 2  yosys -> nextpnr-ice40 -> icepack -> iceprog (this Makefile)
#
# NAME is the Haskell module holding the top entity; TOP is the entity itself
# (a function named `topEntity` or one carrying a Synthesize annotation). Clash
# writes its HDL to verilog/$(NAME).$(TOP)/.

NAME = Blinky
TOP = topEntity
# Build artifacts are keyed on the design (NAME), not just on $(TOP): both tops
# are named `topEntity`, so a shared _build tree would let one design's staged
# HDL/bitstream masquerade as the other's after a `NAME` switch. Per-design
# subdirs keep them independent (and let both bitstreams coexist).
BUILDDIR = _build/$(NAME)

# Pin constraints are per-design, not global: BlinkyWithReset has an extra
# `rst` port that plain Blinky lacks, so the two top entities can't share one
# pcf (nextpnr errors on a port the design doesn't have). Map each top to its
# pcf and select it from NAME, so `make NAME=BlinkyWithReset` picks the right
# pins automatically. Override with `make PCF=...` for a one-off.
PCF_Blinky          = icebreaker.pcf
PCF_BlinkyWithReset = icebreaker-reset.pcf
PCF ?= $(PCF_$(NAME))

# nextpnr-ice40 placement constraints for the iCEbreaker (iCE40 UP5K, sg48).
PNR_FLAGS = \
	--up5k \
	--package sg48 \
	--pcf $(PCF) \
	--freq 12

# Tool paths live in build.cfg; copy it to build.cfg.local to override locally.
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

# 2. Synthesis (Verilog -> JSON)
$(BUILDDIR)/02-net/$(TOP).json: $(BUILDDIR)/01-hdl/$(TOP).v
	mkdir -p $(BUILDDIR)/02-net $(BUILDDIR)/log
	$(YOSYS) \
		-l $(BUILDDIR)/log/synth.log \
		-p 'read_verilog $(dir $^)*.v; synth_ice40 -top $(TOP) -json $@'

# 1b. Stage the Clash-generated HDL into the build tree.
$(BUILDDIR)/01-hdl/$(TOP).v: verilog/$(NAME).$(TOP)/$(TOP).v
	mkdir -p $(BUILDDIR)
	rm -Rf $(BUILDDIR)/01-hdl
	cp -a verilog/$(NAME).$(TOP) $(BUILDDIR)/01-hdl

# 1a. Generate Verilog from Clash. Upstream orangecrab leaves this to a manual
#     `stack run clash -- Blink --verilog`; we wire it into make so the whole
#     pipeline runs from a single `make`.
verilog/$(NAME).$(TOP)/$(TOP).v: $(shell find src -name '*.hs')
	$(CLASH) $(NAME) --verilog

##----------------------------------------------------------------------------##
#   Tests                                                                      #
##----------------------------------------------------------------------------##

# Run the tasty unit-test suite (tests/unittests.hs): pure-Haskell simulation
# of the counter, independent of the FPGA toolchain.
test:
	$(TEST)

##----------------------------------------------------------------------------##
#   Cleanup                                                                    #
##----------------------------------------------------------------------------##

clean:
	rm -Rf _build verilog

##----------------------------------------------------------------------------##
#   Special Targets                                                            #
##----------------------------------------------------------------------------##

.PHONY: default clean upload synth netlist bitstream test
.SECONDARY:
