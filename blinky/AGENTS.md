# AGENTS.md — blinky

Clash port of the SpinalHDL `Blinky` (`BOOT`-reset variant), laid out to match
the upstream [clash-starters `orangecrab`](https://github.com/clash-lang/clash-starters/tree/main/orangecrab)
project rather than the `src/{hw,sim}` shape used by the SpinalHDL repo.

## Cross-project deps

None. Self-contained. The only thing shared with the SpinalHDL `Blinky` is the
pin choice (clk → 35, led → 11); `icebreaker.pcf` is written fresh against the
Clash port names (`clk`, `led`), not copied.

## Source layout (orangecrab-style)

```
blinky/
  bin/   Clash.hs / Clashi.hs   thin Clash.Main wrappers (clash, clashi exes)
  src/   Blinky.hs              topEntity + counter + makeTopEntity
         Blinky/Domain.hs       Dom12 (12 MHz) clock domain
  tests/ unittests.hs           tasty runner main
         Tests/Blinky.hs        the toggle assertion
```

There is **no `src/hw`, `src/sim`, or `src/build`** here — that nesting belongs
to the SpinalHDL repo. Synthesizable code, the domain, and tests are split by
the top-level `src/` vs `tests/` dirs, exactly like orangecrab.

## Build flow (two stages)

1. **Clash → Verilog (stack):** `stack run clash -- Blinky --verilog`, which the
   `bin/Clash.hs` wrapper drives. Output: `verilog/Blinky.topEntity/topEntity.v`.
2. **Gates → board (make):** `Makefile` runs `yosys → nextpnr-ice40 → icepack →
   iceprog`. Tool paths come from `build.cfg` (override in `build.cfg.local`).
   The Makefile also wires in stage 1, so a bare `make` is self-contained.

`make` target order: `synth` → `netlist` → `bitstream` → `upload`. The Makefile
is the iCE40 retarget of orangecrab's ECP5 one (`.asc`/`.bin`/`icepack` replace
`.config`/`.bit`/`ecppack`).

## Clash gotchas worth remembering

- **`makeTopEntity 'topEntity`** derives the `Synthesize` annotation from the
  named-port type signature (`"clk" ::: Clock Dom12 -> "led" ::: Signal Dom12 Bit`).
  Without it, Clash invents port/module names and the pcf stops binding.
- **No reset port by design.** The iCE40 has no user-reset pin, so `topEntity`
  passes `unsafeFromActiveHigh (pure False)` as the reset. Clash sees the reset
  is never asserted and emits no `reset` port; the counter relies on its
  power-up `init` value (BOOT-reset equivalent). Don't "add a reset for safety"
  — it would need a pin and change the pcf.
- **`register 0 (counter + 1)`** is the whole counter. The recursive `let` is
  not an infinite loop: `register` delays its argument by one cycle.
- **`blink` takes the width as an `SNat n`** so the same circuit elaborates at
  width 25 for synthesis and a small width for the test. `topEntity` applies
  `SNat @CounterWidth`.
- **Per-file `LANGUAGE` pragmas are usually unnecessary** in `src/` — the Clash
  compiler enables its needed extensions by default, and `blinky.cabal`'s
  `common-options` supplies them for `stack build`/`stack test`. Only add a
  pragma for an extension that is in *neither* set (e.g. `NumericUnderscores`
  in `Blinky/Domain.hs`).
- The `blinky.cabal` `ghc-options` (`-fexpose-all-unfoldings`, `-fno-worker-wrapper`,
  `-fno-unbox-*-strict-fields`, the three typelits plugins) are load-bearing for
  Clash. They are copied from orangecrab — don't trim them.

## Tests

- `stack test` runs the tasty suite. Blinky has no data inputs, so there is no
  hedgehog property to write (unlike orangecrab's `blink`); the test instead
  `sampleN`s a small-width instance and asserts the LED toggles. Plain Haskell
  on the output stream — no simulator.

## What NOT to do

- Don't reintroduce a `Makefile`-less "stack-only" flow or `src/{hw,sim}`
  nesting; the whole point of this repo is to follow the upstream clash-starters
  conventions.
- Don't bump Clash off the `stack.yaml` pin without updating the
  `clash-prelude` bound in `blinky.cabal`.
- Don't drive the LED through a reset net — see the no-reset note above.
