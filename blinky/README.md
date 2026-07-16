# blinky

The "hello, world" of FPGA examples, in [Clash](https://clash-lang.org/): a
free-running counter divides the 12 MHz iCEbreaker clock and its
most-significant bit drives the on-board LED. If the LED blinks after
`make upload`, your whole Clash → bitstream → board toolchain is healthy.

This is a Clash port of the SpinalHDL `Blinky` from the sibling
[`icebreaker-spinalhdl-examples`](https://github.com/) repo, laid out to match
the upstream
[clash-starters `orangecrab`](https://github.com/clash-lang/clash-starters/tree/main/orangecrab)
project. Two top entities ship in the same package:

- **`Blinky`** — bare counter, MSB drives the LED, **no reset pin** (relies on
  the iCE40 `BOOT`/power-up state). Built by default.
- **`BlinkyWithReset`** — same counter with an explicit **asynchronous,
  active-low reset** wired to the user button. Hold the button → LED off;
  release → it blinks.

## What it teaches

- A minimal synthesizable Clash `topEntity` with **named ports**
  (`"clk" ::: Clock Dom12`) and `makeTopEntity`.
- `register` as the one register primitive — `counter = register 0 (counter + 1)`
  is a free-running counter (the recursion is fine: `register` delays by a cycle).
- The two flavours of reset on the iCE40, chosen entirely in the clock domain:
  - **no-reset / BOOT** (`Dom12`): reset tied permanently de-asserted, so Clash
    emits no `reset` port — the counter just powers up at 0 from the bitstream.
  - **async active-low** (`Dom12Rst`): a real `Reset` port whose polarity comes
    from `vResetPolarity = ActiveLow`, matching the button.
- Reusing one circuit (`blink`, polymorphic in the domain) across two tops.
- The standard Clash **two-stage build**: cabal for Verilog, `make` for gates,
  with `make NAME=<Top>` selecting which top (and its pcf) to build.

## Layout

```
blinky/
  bin/
    Clash.hs         clash wrapper   -> cabal run clash -- Blinky --verilog
    Clashi.hs        clashi REPL     -> cabal run clashi
  src/
    Blinky.hs        topEntity + the counter, makeTopEntity
    Blinky/Domain.hs Dom12 (12 MHz iCEbreaker domain)
  tests/
    unittests.hs     tasty runner
    Tests/Blinky.hs  asserts the LED toggles
  blinky.cabal       library + clash/clashi exes + test-suite
  cabal.project      GHC 9.10.3 + Clash 1.10.0 pin (+ cabal.project.freeze lock)
  fourmolu.yaml      Haskell formatting style (make format / format-check)
  Makefile           synth -> netlist -> bitstream -> upload (iCE40)
  build.cfg          tool paths (override via build.cfg.local)
  icebreaker.pcf     clk -> pin 35 (12 MHz), led -> pin 11
```

## Quick start

Tools: GHC 9.10.3 + `cabal` (e.g. via [`ghcup`](https://www.haskell.org/ghcup/);
cabal fetches Clash automatically), plus `yosys`,
`nextpnr-ice40`, `icepack`, `iceprog` (all in the
[OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build/releases)).

```sh
cabal build                          # compile (first run is slow: builds Clash)
cabal test                           # run the toggle test
cabal run clash -- Blinky --verilog  # just generate verilog/Blinky.topEntity/topEntity.v
cabal run clashi                     # Clash REPL with Blinky in scope

make                                 # full pipeline -> _build/03-bitstream/topEntity.bin
make upload                          # program the iCEbreaker
make format                          # fourmolu (rewrite in place)
make format-check                    # fourmolu style gate (CI parity)
make clean                           # remove _build/ and verilog/
```

`make` targets (each depends on the previous): `synth` → `netlist` → `bitstream`
→ `upload`. Unlike upstream orangecrab, `make` also runs the Clash→Verilog step
itself, so a bare `make` builds end-to-end.

**First build is slow.** `cabal build` compiles `clash-ghc`
and its dependencies into the cabal store (~10–15 min cold); everything after is
cached.

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
