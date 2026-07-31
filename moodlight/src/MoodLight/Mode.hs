{- |
What colour to show, and when to change it.

Two halves:

  * 'modeFsm', the only real state -- which mode the light is in;
  * 'render', a pure function from mode and phase to three channel duties. It
    has no state at all, which is why the whole visual behaviour can be tested
    as a list of numbers.

== Reading the FSM

'modeFsm' uses 'mealyS', the state-monad Mealy machine. The do-block is sugar for
a pure state update -- there is no @IO@ and nothing is mutated; @modify'@ and
@get@ just thread a value through. It compiles to a two-bit register.
-}
module MoodLight.Mode
  ( Mode (..)
  , nextMode
  , modeFsm
  , debounce
  , render
  ) where

import Clash.Prelude

import Control.Monad (when)
import Control.Monad.State.Strict (State, get, modify')

import MoodLight.Gamma (gamma)
import MoodLight.Pwm (triangle)

{- | The four things the light can be doing.

@Enum@ and @Bounded@ are what let 'nextMode' wrap without a hand-written table:
add a constructor and the cycle grows to fit.
-}
data Mode = Off | Solid | Breathe | Rainbow
  deriving (Generic, NFDataX, Eq, Show, Enum, Bounded)

-- | Advance one step, wrapping at the end.
nextMode :: Mode -> Mode
nextMode m = if m == maxBound then minBound else succ m

{- | Collapse a noisy button line into one clean pulse per press.

This debounces by /slow sampling/: the input is only inspected when an @n@-bit
counter wraps, so any ringing between samples is invisible. At 12 MHz an 'SNat'
of 17 gives a 10.92 ms window, comfortably longer than the few milliseconds a
tactile switch rings for.

The output is a single-cycle pulse on the transition from released to pressed.
@BTN_N@ idles high through a pull-up and shorts to ground when pressed, so
\"pressed\" is a /low/ level; that inversion is handled here, once, and nothing
downstream needs to know the polarity.
-}
debounce ::
  forall n dom.
  (HiddenClockResetEnable dom, KnownNat n) =>
  -- | Sampling window width
  SNat n ->
  -- | Raw button line, active low
  Signal dom Bit ->
  -- | One-cycle pulse per press
  Signal dom Bool
debounce SNat = mealyS step (0, False)
 where
  step :: Bit -> State (Unsigned n, Bool) Bool
  step level = do
    (count, held) <- get
    let tick = count == maxBound
        pressedNow = level == low
        held' = if tick then pressedNow else held
        -- Fire only when a sampling instant sees a new press.
        fired = tick && pressedNow && not held
    modify' (\(c, _) -> (c + 1, held'))
    pure fired

{- | The mode register. One pulse in, one mode advance.

The do-block reads as imperative code and is a pure function.
-}
modeFsm :: (HiddenClockResetEnable dom) => Signal dom Bool -> Signal dom Mode
modeFsm = mealyS step Off
 where
  step :: Bool -> State Mode Mode
  step press = do
    when press (modify' nextMode)
    get

{- | The whole visual behaviour, as a pure function.

No state, no clock, no signals -- just mode and phase in, three duties out. That
is what makes every mode testable without a simulator.

'gamma' is applied per channel, so @Rainbow@ instantiates three independent
lookup tables. Three channels need three simultaneous lookups; there is no
reusing one result across time the way a CPU would.
-}
render ::
  Mode ->
  -- | Current phase
  Unsigned 8 ->
  -- | @(red, green, blue)@ duties
  (Unsigned 8, Unsigned 8, Unsigned 8)
render Off _ = (0, 0, 0)
render Solid _ = (255, 160, 60)
render Breathe p = let d = gamma (triangle p) in (d, d, d)
render Rainbow p =
  -- +85 and +170 are 120 and 240 degrees on an 8-bit phase; the wrap is free.
  ( gamma (triangle p)
  , gamma (triangle (p + 85))
  , gamma (triangle (p + 170))
  )
