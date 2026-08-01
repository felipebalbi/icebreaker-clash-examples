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
be driven through the @SB_RGBA_DRV@ hard block. That block is not part of
clash-prelude, but it does not need a hand-written Verilog wrapper either:
@ice40-prim@ ships it as a Clash blackbox, so 'rgbDriver' below instantiates it
from Haskell and @topEntity@ is the only synthesis top there is.
-}
module MoodLight where

import Clash.Annotations.TH
import Clash.Prelude

import Ice40.Rgb (rgbPrim)

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
  -- | The three constant-current pins (iCEbreaker pins 39, 40, 41)
  "rgb" ::: Signal Dom12 (BitVector 3)
topEntity clk btn =
  rgbDriver (withClockResetEnable clk noReset enableGen (moodLight btn))
 where
  noReset = unsafeFromActiveHigh (pure False)

{- | The @SB_RGBA_DRV@ hard block, as a Clash blackbox.

The three RGB pins are constant-current open-drain outputs and cannot be driven
as ordinary I\/O, so this macro is mandatory. 'rgbPrim' comes from @ice40-prim@
and carries the Verilog template with it, which is why there is no hand-written
HDL anywhere in this project.

Half-current mode at the lowest per-channel step, matching the upstream
@sb_rgba_blink@ example: plenty bright for an indicator without washing out.

Bit order is @pack (r, g, b)@ on both sides -- index 2 is red and drives
@RGB0@, which is pin 39. Confirmed on hardware by driving one channel at a time.
-}
rgbDriver ::
  -- | Packed @{red, green, blue}@ PWM
  Signal dom (BitVector 3) ->
  -- | Packed @{RGB0, RGB1, RGB2}@ pin drive
  Signal dom (BitVector 3)
rgbDriver pwm =
  pack <$> rgbPrim "0b1" "0b000001" "0b000001" "0b000001" (pure high) (pure high) r g b
 where
  (r, g, b) = unbundle (unpack <$> pwm)

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
