{- |
Timing for the mood light: the PWM carrier and the slow phase ramp.

Two timebases come off the one 12 MHz clock:

  * the PWM carrier, an 8-bit counter that free-runs at 12 MHz / 256 = 46.875 kHz
    -- far above flicker;
  * the phase ramp, advanced once per prescaler wrap, which is what makes the
    breathing slow enough to look deliberate.

The separation matters. If the duty value changed every clock the comparator
would never see a stable value for a whole carrier period and the output would
average into mush.
-}
module MoodLight.Pwm (pwmRGB, phase, triangle) where

import Clash.Prelude

import Control.Monad.State.Strict (State, get, modify')

{- | Fold a rising sawtooth into a triangle, so brightness ramps back down
instead of snapping to zero.

Pure, so it is tested as a plain list. Peaks at 254 rather than 255: @127 * 2@.
-}
triangle :: Unsigned 8 -> Unsigned 8
triangle p = if p < 128 then p * 2 else (255 - p) * 2

{- | Three PWM channels sharing one carrier counter.

One counter and three comparators, not three counters -- the channels must stay
phase-aligned, and it is less hardware.

The output bit order is @pack (r, g, b)@, so index 2 is red, index 1 green and
index 0 blue. @icebreaker.pcf@ and 'MoodLight.rgbDriver' both depend on that
ordering.
-}
pwmRGB ::
  (HiddenClockResetEnable dom) =>
  -- | Per-channel duty
  Signal dom (Unsigned 8, Unsigned 8, Unsigned 8) ->
  -- | Packed @{red, green, blue}@
  Signal dom (BitVector 3)
pwmRGB = mealyS step 0
 where
  step :: (Unsigned 8, Unsigned 8, Unsigned 8) -> State (Unsigned 8) (BitVector 3)
  step (r, g, b) = do
    c <- get
    modify' (+ 1)
    pure (pack (boolToBit (c < r), boolToBit (c < g), boolToBit (c < b)))

{- | A slow 8-bit sawtooth, advanced once every @2 ^ n@ clocks.

The prescaler width is an 'SNat' so the same definition elaborates at 17 for
synthesis (10.92 ms per step, so a 2.796 s sweep) and at a tiny width for the
tests -- the same trick blinky uses for its counter width.
-}
phase ::
  forall n dom.
  (HiddenClockResetEnable dom, KnownNat n) =>
  -- | Prescaler width
  SNat n ->
  Signal dom (Unsigned 8)
phase SNat = mealyS step (0, 0) (pure ())
 where
  step :: () -> State (Unsigned n, Unsigned 8) (Unsigned 8)
  step _ = do
    (presc, p) <- get
    let tick = presc == maxBound
    modify' (\(pr, ph) -> (pr + 1, if tick then ph + 1 else ph))
    pure p
