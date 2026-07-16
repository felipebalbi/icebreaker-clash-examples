# AGENTS.md

Conventions for AI agents (Copilot, Codex, Cursor, Aider, …) and human
contributors working in this repository. Per-project specifics live in
`<project>/AGENTS.md` and override anything below.

## Repo overview

Bottom-up [Clash](https://clash-lang.org/) (Haskell HDL) bring-up examples for
the **iCEbreaker** (Lattice iCE40-UP5K) board. It is the Clash sibling of
`icebreaker-spinalhdl-examples`; each top-level directory is a self-contained
example laid out to match the upstream
[clash-starters](https://github.com/clash-lang/clash-starters) projects
(notably `orangecrab`).

```
blinky/
```

## Project layout (per example)

Mirrors the upstream clash-starters layout — **not** the SpinalHDL repo's
`src/{hw,sim}` shape:

```
<project>/
  bin/    Clash.hs / Clashi.hs    thin Clash.Main wrappers (clash, clashi exes)
  src/    <Top>.hs + helpers      synthesizable code; one module owns topEntity
  tests/  unittests.hs + Tests/   tasty test-suite, run via `cabal test`
  <project>.cabal                 library + clash/clashi exes + test-suite
  cabal.project + .freeze         GHC 9.10.3 + Clash pin + locked dep graph
  fourmolu.yaml                   Haskell formatting style (make format-check)
  hie.yaml                        pins the HLS cradle to cabal components
  .dir-locals.el                 points haskell-mode's C-c C-l at the clashi REPL
  Makefile  build.cfg            gates + programming (yosys/nextpnr/icepack/iceprog)
  <board>.pcf                    iCE40 pin constraints
```

## Build flow (two stages)

Standard Clash architecture, same as upstream clash-starters:

1. **Clash → Verilog (cabal):** `cabal run clash -- <Top> --verilog`.
   The `bin/Clash.hs` wrapper is a verbatim `Clash.Main.defaultMain` shim.
2. **Verilog → bitstream → board (make):** the `Makefile` drives
   `yosys → nextpnr-ice40 → icepack → iceprog`, with tool paths factored into
   `build.cfg` (overridable via a gitignored `build.cfg.local`). The Makefile
   also invokes stage 1 so a bare `make` is self-contained.

`cabal test` runs each project's tasty suite. `make format-check` runs fourmolu
(style gate); both, plus a Clash→Verilog codegen smoke, are enforced in CI
(`.github/workflows/ci.yml`).

## File conventions

- **LF line endings only.** Run `dos2unix` on anything edited on a Windows host.
- Directory names are **lowercase** (`blinky/`, not `Blinky/`). Haskell module
  identifiers must stay capitalized (`module Blinky`), and a project's top
  entity keeps the upstream name `topEntity`.
- The `<project>.cabal` `common-options` (extensions + `ghc-options`) are adopted from the
  clash-starters projects and are load-bearing for Clash — don't trim them.
- **`cabal.project` + `cabal.project.freeze` pin the toolchain.** `cabal.project`
  fixes GHC (`with-compiler: ghc-9.10.3`), the Hackage `index-state`, and the
  Clash 1.10 constraints (the old Stack extra-deps); the committed `.freeze`
  locks the whole transitive graph (the `stack.yaml.lock` analog). Don't bump
  Clash without regenerating the freeze (`cabal freeze`) and updating the
  `clash-prelude` bound in the cabal file.
- **`fourmolu.yaml` is the one formatting style.** `make format` rewrites in
  place; `make format-check` is the CI gate. HLS reads it too, so format-on-save
  matches CI when the formatting provider is fourmolu. Keep the local fourmolu
  version in step with the one CI pins.
- **`hie.yaml` must enumerate cradle components.** Each project's cabal builds
  two executables (`clash`, `clashi`), each with its own `main-is`, so a bare
  `cradle: cabal:` leaves `cabal repl` unable to pick a main module — it prompts
  interactively, HLS feeds it EOF, and the cradle fails ("the main module to
  load is ambiguous"). List the components by path instead (lib:<project> /
  exe:clash / exe:clashi / test:test-library). It's HLS/editor config, not build
  tooling.
- **`.dir-locals.el` points the REPL at `clashi`.** It overrides haskell-mode's
  process command to `cabal run clashi` so `C-c C-l` loads the buffer into the
  Clash interactive shell (`clashi` is `Clash.Main` run as an executable, not
  something `cabal repl` can load). Editor config like `hie.yaml`; needs
  `interactive-haskell-mode` enabled to supply the buffer<->REPL link.

## Comment / Haddock style

- **Why, not what.** Comments add the rationale a reader can't recover from the
  code: electrical reasons, protocol corners, choices between alternatives.
- Match the depth of `blinky/src/Blinky.hs` (Components, with a design-rationale
  header) and `blinky/src/Blinky/Domain.hs` (terse, for the domain).
- Doc-link breadcrumbs (Clash stdlib pages, datasheet sections) are welcome.

## Commit conventions

- Short imperative subject lines.
- AI-pair-programmed commits include the trailer:
  ```
  Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
  ```

## What NOT to do

- Don't add lint/build/test infrastructure beyond the existing toolchain
  (cabal, fourmolu, yosys, nextpnr-ice40, icepack, iceprog, and the
  `.github/workflows/ci.yml` that runs cabal build/test/codegen + fourmolu).
  It's intentional. (`hie.yaml` and `.dir-locals.el` are not build tooling —
  they're editor config; keep them.)
- Don't run sims or builds the user didn't ask for; running an existing
  `cabal test` after a change is fine.
- Don't create planning `.md` files inside the repo. Use the per-session
  workspace for ephemeral plans.
- Don't restructure an example away from the upstream clash-starters layout
  (no `src/{hw,sim,build}` nesting).
