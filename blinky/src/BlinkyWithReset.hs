{- |
Blinking LED with an explicit reset — the @BlinkyWithReset@ variant.

Identical counter to "Blinky", but instead of tying the reset off it exposes an
asynchronous, active-low @reset@ port wired (via @icebreaker-reset.pcf@) to the
iCEbreaker user button on pin 10. Hold the button to clamp the counter at 0
(LED off); release it to run. This is the Clash port of the SpinalHDL
@BlinkyWithReset@.

== How the reset gets its polarity

The active-low behaviour lives entirely in the clock domain: 'Dom12Rst' is
declared with @vResetKind = Asynchronous@ and @vResetPolarity = ActiveLow@, so a
@'Reset' Dom12Rst@ port /is/ an active-low asynchronous reset. The button idles
high (pull-up) and shorts to ground when pressed, which matches active-low
exactly. This is the same pattern the upstream orangecrab project uses for its
button reset — no per-bit polarity juggling in the logic.

The counter itself ('blink', shared with "Blinky") is reused unchanged: it is
polymorphic in the clock domain, so the only difference between the two tops is
what reset reaches the hidden @register@.
-}
module BlinkyWithReset where

import Clash.Annotations.TH
import Clash.Prelude

import Blinky (CounterWidth, blink)
import Blinky.Domain (Dom12Rst)

{- | Synthesis entry point. Unlike "Blinky"'s 'topEntity' this carries a real
@reset@ port; 'makeTopEntity' names it from the @"reset" :::@ annotation so
@icebreaker-reset.pcf@ can bind it to the button.
-}
topEntity ::
  -- | 12 MHz board clock (iCEbreaker pin 35)
  "clk" ::: Clock Dom12Rst ->
  -- | Active-low reset from the user button (iCEbreaker pin 10)
  "reset" ::: Reset Dom12Rst ->
  -- | On-board LED (iCEbreaker pin 11)
  "led" ::: Signal Dom12Rst Bit
topEntity clk reset =
  withClockResetEnable clk reset enableGen (blink (SNat @CounterWidth))

makeTopEntity 'topEntity
