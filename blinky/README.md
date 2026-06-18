# blinky

The "hello, world" of FPGA examples, in [Clash](https://clash-lang.org/): a
free-running counter divides the 12 MHz iCEbreaker clock and its
most-significant bit drives the on-board LED. If the LED blinks after
`make upload`, your whole Clash → bitstream → board toolchain is healthy.

This is a Clash port of the SpinalHDL `Blinky` (`BOOT`-reset variant) from the
sibling [`icebreaker-spinalhdl-examples`](https://github.com/) repo, laid out
to match the upstream
[clash-starters `orangecrab`](https://github.com/clash-lang/clash-starters/tree/main/orangecrab)
project.

## What it teaches

- A minimal synthesizable Clash `topEntity` with **named ports**
  (`"clk" ::: Clock Dom12`) and `makeTopEntity`.
- `register` as the one register primitive — `counter = register 0 (counter + 1)`
  is a free-running counter (the recursion is fine: `register` delays by a cycle).
- The **no-reset / BOOT** idiom: the iCE40 has no user-reset pin, so reset is
  tied permanently de-asserted and Clash emits no `reset` port.
- A custom 12 MHz clock domain (`Blinky.Domain`).
- The standard Clash **two-stage build**: stack for Verilog, `make` for gates.

## Layout

```
blinky/
  bin/
    Clash.hs         clash wrapper   -> stack run clash -- Blinky --verilog
    Clashi.hs        clashi REPL     -> stack run clashi
  src/
    Blinky.hs        topEntity + the counter, makeTopEntity
    Blinky/Domain.hs Dom12 (12 MHz iCEbreaker domain)
  tests/
    unittests.hs     tasty runner
    Tests/Blinky.hs  asserts the LED toggles
  blinky.cabal       library + clash/clashi exes + test-suite
  stack.yaml         resolver pin (Clash 1.10.0)
  Makefile           synth -> netlist -> bitstream -> upload (iCE40)
  build.cfg          tool paths (override via build.cfg.local)
  icebreaker.pcf     clk -> pin 35 (12 MHz), led -> pin 11
```

## Quick start

Tools: `stack` (fetches GHC + Clash automatically), plus `yosys`,
`nextpnr-ice40`, `icepack`, `iceprog` (all in the
[OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build/releases)).

```sh
stack build                          # compile (first run is slow: builds Clash)
stack test                           # run the toggle test
stack run clash -- Blinky --verilog  # just generate verilog/Blinky.topEntity/topEntity.v
stack run clashi                     # Clash REPL with Blinky in scope

make                                 # full pipeline -> _build/03-bitstream/topEntity.bin
make upload                          # program the iCEbreaker
make clean                           # remove _build/ and verilog/
```

`make` targets (each depends on the previous): `synth` → `netlist` → `bitstream`
→ `upload`. Unlike upstream orangecrab, `make` also runs the Clash→Verilog step
itself, so a bare `make` builds end-to-end.

**First build is slow.** `stack build` installs GHC and compiles `clash-ghc`
and its dependencies (~10–15 min cold); everything after is cached.

## Hardware

- **Board**: iCEbreaker (Lattice iCE40 UP5K, sg48 package).
- **Pins** (`icebreaker.pcf`):
  - `clk` → pin 35 (12 MHz)
  - `led` → pin 11 (green user LED)
  - no reset pin — BOOT/power-up state only.

## Knobs

| Parameter | Where | Effect |
|---|---|---|
| `CounterWidth` | `src/Blinky.hs` | Blink rate = clk / 2^CounterWidth. `25` ≈ 1.4 s MSB toggle at 12 MHz. |
| `blink`'s `SNat` width | `tests/Tests/Blinky.hs` | Small (4) so a full period fits in a quick simulation. |
