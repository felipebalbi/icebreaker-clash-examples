{-# LANGUAGE NumericUnderscores #-}
{-# OPTIONS_GHC -Wno-orphans #-}

{- |
iCEbreaker (Lattice iCE40 UP5K) clock domain for the mood light.

Mirrors @Blinky.Domain@: the 12 MHz board oscillator on pin 35. The period is
consumed only by the simulator; for synthesis the real frequency comes from
@set_frequency@ in @icebreaker.pcf@ and @--freq@ in the Makefile.

The default 'vSystem' reset (asynchronous, active-high) is kept as-is. The top
entity ties it permanently de-asserted, so it never reaches hardware -- the
iCE40 has no user-reset pin, and here the button is needed as the mode input
rather than as a reset.
-}
module MoodLight.Domain where

import Clash.Prelude

-- | 12 MHz oscillator clock of the iCEbreaker board (pin 35).
createDomain
  vSystem
    { vName = "Dom12"
    , vPeriod = hzToPeriod 12_000_000
    }
