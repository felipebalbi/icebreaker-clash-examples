##----------------------------------------------------------------------------##
#   Project Settings                                                           #
##----------------------------------------------------------------------------##
#
# Two-stage build, as in the sibling blinky example:
#
#   Stage 1  Clash + GHC compile src/ and emit Verilog   (cabal)
#   Stage 2  yosys -> nextpnr-ice40 -> icepack -> iceprog (this Makefile)
#
# Unlike blinky, the module yosys synthesises is NOT the Clash top entity: the
# RGB pins need an SB_RGBA_DRV instance, which lives in a hand-written wrapper.
# Hence CLASH_TOP (what Clash emits) and SYNTH_TOP (what yosys builds).

NAME = MoodLight
CLASH_TOP = topEntity
SYNTH_TOP = icebreaker_top
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

upload: $(BUILDDIR)/03-bitstream/$(SYNTH_TOP).bin
	$(PROG) $<

synth: $(BUILDDIR)/02-net/$(SYNTH_TOP).json

netlist: $(BUILDDIR)/03-bitstream/$(SYNTH_TOP).asc

bitstream: $(BUILDDIR)/03-bitstream/$(SYNTH_TOP).bin

# 4. Pack (ASC -> BIN)
$(BUILDDIR)/03-bitstream/$(SYNTH_TOP).bin: $(BUILDDIR)/03-bitstream/$(SYNTH_TOP).asc
	$(PACK) $< $@

# 3. Place & route (JSON -> ASC)
$(BUILDDIR)/03-bitstream/$(SYNTH_TOP).asc: $(BUILDDIR)/02-net/$(SYNTH_TOP).json $(PCF)
	mkdir -p $(BUILDDIR)/03-bitstream
	$(PNR) --json $< --asc $@ $(PNR_FLAGS)

# 2. Synthesis. Reads the generated .vg AND the hand-written wrapper .v, and
#    builds the wrapper as the top.
$(BUILDDIR)/02-net/$(SYNTH_TOP).json: $(BUILDDIR)/01-hdl/$(CLASH_TOP).vg verilog-support/$(SYNTH_TOP).v
	mkdir -p $(BUILDDIR)/02-net $(BUILDDIR)/log
	$(YOSYS) \
		-l $(BUILDDIR)/log/synth.log \
		-p 'read_verilog $(BUILDDIR)/01-hdl/*.vg verilog-support/*.v; synth_ice40 -top $(SYNTH_TOP) -json $@'

# 1b. Stage the Clash HDL, renaming .v to .vg.
#
#     tokei maps .v to Coq, whose comment syntax is (* *), so it counts
#     Verilog's /* */ and // as code. .vg is tokei's Verilog extension, and it
#     also usefully marks "generated" against the hand-written wrapper's .v.
$(BUILDDIR)/01-hdl/$(CLASH_TOP).vg: verilog/$(NAME).$(CLASH_TOP)/$(CLASH_TOP).v
	mkdir -p $(BUILDDIR)
	rm -Rf $(BUILDDIR)/01-hdl
	cp -a verilog/$(NAME).$(CLASH_TOP) $(BUILDDIR)/01-hdl
	mv $(BUILDDIR)/01-hdl/$(CLASH_TOP).v $@

# 1a. Generate Verilog from Clash.
verilog/$(NAME).$(CLASH_TOP)/$(CLASH_TOP).v: $(shell find src -name '*.hs')
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
