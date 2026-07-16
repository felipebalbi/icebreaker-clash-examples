{- |
Blinking LED for the iCEbreaker (Lattice iCE40 UP5K).

A free-running counter divides the 12 MHz board clock; its most-significant bit
drives the on-board LED. This is the Clash port of the SpinalHDL @Blinky@
(@BOOT@-reset variant) from the sibling @icebreaker-spinalhdl-examples@ repo.

== Why there is no reset port

The iCE40 has no global user-reset pin, so — exactly like Spinal's @BOOT@ reset —
registers come up at their @init@ value straight from the bitstream and we never
generate a reset net. In Clash that means we hand 'topEntity' a permanently
de-asserted reset ('unsafeFromActiveHigh' of a constant 'False'); Clash then sees
the reset is unused and emits no @reset@ port, leaving just @clk@ and @led@ for
the pcf to bind.

== Shape vs. the SpinalHDL original

@
| SpinalHDL                       | Clash                                      |
|---------------------------------|--------------------------------------------|
| Reg(UInt(width bits)) init(0)   | register 0 :: a -> Signal a -> Signal a    |
| counter := counter + 1          | counter = register 0 (counter + 1)         |
| io.led := counter.msb           | msb \<$\> counter                          |
@
-}
module Blinky where

import Blinky.Domain (Dom12)
import Clash.Annotations.TH
import Clash.Prelude

{- | Width of the divider counter. @2 ^ 25@ counts at 12 MHz makes the MSB
toggle roughly every 1.4 s — a comfortable, visible blink. The synthesis
top bakes in this width; the test sweeps a much smaller one so a full
period fits in a quick simulation.
-}
type CounterWidth = 25

{- | Synthesis entry point. The @"clk" :::@ / @"led" :::@ named-port
annotations (plus 'makeTopEntity' below) fix the generated Verilog port
names so @icebreaker.pcf@ binds to the right wires.
-}
topEntity ::
  -- | 12 MHz board clock (iCEbreaker pin 35)
  "clk" ::: Clock Dom12 ->
  -- | On-board LED (iCEbreaker pin 11)
  "led" ::: Signal Dom12 Bit
topEntity clk = withClockResetEnable clk noReset enableGen (blink (SNat @CounterWidth))
 where
  -- No user-reset pin on the iCE40: tie reset permanently de-asserted so the
  -- counter relies on its power-up @init@ value (BOOT-reset equivalent) and
  -- Clash emits no @reset@ port.
  noReset = unsafeFromActiveHigh (pure False)

{- | The actual circuit, polymorphic in both the clock domain and the counter
width. The width is passed as an 'SNat' so the same definition elaborates
for synthesis (@25@) and simulation (small) with no duplication.

@counter@ is defined recursively as @register 0 (counter + 1)@: 'register'
delays its argument by one cycle, so this is a free-running counter that
starts at 0, not an infinite loop.
-}
blink ::
  forall dom n.
  (HiddenClockResetEnable dom, KnownNat n, 1 <= n) =>
  -- | Counter width
  SNat n ->
  -- | LED output: the counter's most-significant bit
  Signal dom Bit
blink SNat = msb <$> counter
 where
  counter :: Signal dom (Unsigned n)
  counter = register 0 (counter + 1)

makeTopEntity 'topEntity
