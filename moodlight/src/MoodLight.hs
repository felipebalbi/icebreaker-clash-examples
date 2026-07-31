{- |
The mood light: an RGB LED that breathes, fades and cycles colour, with the
on-board button stepping between modes.

Composition only. Everything interesting lives in the four modules below; this
one just names the pins and wires them together.

== No reset port

Like "Blinky", the reset is tied permanently de-asserted, so Clash emits no
@reset@ port and the registers come up at their @init@ values straight from the
bitstream. The iCE40 has no user-reset pin, and here the button is needed as the
mode input anyway.

== The RGB pins are not ordinary I\/O

Pins 39\/40\/41 on the UP5K are constant-current open-drain outputs that can only
be driven through the @SB_RGBA_DRV@ hard block. Clash has no primitive for it, so
@verilog-support\/icebreaker_top.v@ instantiates it by hand around this module.
That wrapper, not @topEntity@, is what yosys synthesises.
-}
module MoodLight where

import Clash.Annotations.TH
import Clash.Prelude

import MoodLight.Domain (Dom12)
import MoodLight.Mode (debounce, modeFsm, render)
import MoodLight.Pwm (phase, pwmRGB)

{- | Prescaler width for both the phase ramp and the debounce window.

@2 ^ 17@ clocks at 12 MHz is 10.92 ms, which makes a 256-step phase sweep take
2.796 s and gives the debouncer a window far longer than a switch rings for.
-}
type PrescalerWidth = 17

-- | Synthesis entry point.
topEntity ::
  -- | 12 MHz board clock (iCEbreaker pin 35)
  "clk" ::: Clock Dom12 ->
  -- | User button, active low (iCEbreaker pin 10)
  "btn" ::: Signal Dom12 Bit ->
  -- | Packed @{red, green, blue}@ PWM (iCEbreaker pins 39, 40, 41)
  "rgb" ::: Signal Dom12 (BitVector 3)
topEntity clk btn = withClockResetEnable clk noReset enableGen (moodLight btn)
 where
  noReset = unsafeFromActiveHigh (pure False)

-- | The design proper, polymorphic in the domain so it can be simulated.
moodLight ::
  (HiddenClockResetEnable dom) =>
  Signal dom Bit ->
  Signal dom (BitVector 3)
moodLight btn =
  pwmRGB (render <$> mode <*> phase (SNat @PrescalerWidth))
 where
  mode = modeFsm (debounce (SNat @PrescalerWidth) btn)

makeTopEntity 'topEntity
