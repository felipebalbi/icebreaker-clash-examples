# icebreaker-clash-examples

Bottom-up [Clash](https://clash-lang.org/) (Haskell HDL) bring-up examples for
the [iCEbreaker](https://1bitsquared.com/products/icebreaker) board
(Lattice iCE40-UP5K). The Clash sibling of `icebreaker-spinalhdl-examples`:
same board, same `yosys → nextpnr-ice40 → icepack → iceprog` backend, but the
hardware is described in Haskell/Clash instead of Scala/SpinalHDL.

Each example is laid out to match the upstream
[clash-starters](https://github.com/clash-lang/clash-starters) projects
(`bin/`, `src/`, `tests/` + a `Makefile`), so what you learn here transfers
straight to other Clash projects.

## Examples

| Example | What it is |
|---|---|
| [`blinky/`](blinky/) | Counter-divider drives the on-board LED. The "hello world" smoke test for the whole Clash → bitstream → board toolchain. |

## Toolchain

- [`stack`](https://docs.haskellstack.org/) — fetches GHC + Clash, builds the
  design, runs tests, and generates Verilog (`stack run clash -- <Top> --verilog`).
- `yosys`, `nextpnr-ice40`, `icepack`, `iceprog` — synthesis, place & route,
  bitstream packing, and programming. All ship in the
  [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build/releases).

## Quick start

```sh
cd blinky
stack build      # first run installs GHC + compiles Clash (~10-15 min cold)
stack test       # run the example's test-suite
make             # Clash -> Verilog -> bitstream
make upload      # program the iCEbreaker
```

See each example's `README.md` for details and `AGENTS.md` for the conventions
that keep the examples consistent.

## License

[MIT](LICENSE) © 2026 Felipe Balbi.
