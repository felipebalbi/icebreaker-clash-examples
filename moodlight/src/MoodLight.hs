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

== Why the RGB pins need the hard block

Pins 39\/40\/41 are the @SB_RGBA_DRV@ hard block's constant-current sinks, but
the block is not an access gate. The pads can be driven as ordinary open-drain
I\/O, and other iCEbreaker designs do exactly that: @ws2812_blink@ drives pin 39
through a plain @SB_IO@, and @mole@ drives pin 40 from a plain output. Lattice
says the same thing -- set @RGBx_CURRENT@ to @"0b000000"@ and the pad is
released to @SB_IO_OD@.

What makes the macro necessary here is the board, not the chip. The iCEbreaker
runs the RGB LED's three cathodes straight to those pins through normally-closed
solder jumpers, with no series resistors anywhere, while every discrete LED on
the board gets a 330R. That is deliberate: the design assumes the macro's
regulated sink, which 'rgbDriver' configures to 2 mA per channel. Drop it and
the only thing limiting current is the pad's on-resistance against the LED's
forward drop.

@SB_RGBA_DRV@ is not part of clash-prelude, but it needs no hand-written Verilog
either: @ice40-prim@ ships it as a Clash blackbox, so 'rgbDriver' below
instantiates it from Haskell and @topEntity@ is the only synthesis top there is.
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

The macro is what current-limits the RGB LED -- see the note above -- so it is
mandatory on this board even though the pads themselves could be driven as
ordinary I\/O. 'rgbPrim' comes from @ice40-prim@ and carries the Verilog
template with it, which is why there is no hand-written HDL anywhere in this
project.

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
  pack <$> rgbPrim halfCurrent step1 step1 step1 (pure high) (pure high) r g b
 where
  halfCurrent = "0b1"
  step1 = "0b000001"
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
