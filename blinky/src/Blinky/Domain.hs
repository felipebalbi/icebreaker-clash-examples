{-# LANGUAGE NumericUnderscores #-}
{-# OPTIONS_GHC -Wno-orphans #-}

{- |
iCEbreaker (Lattice iCE40 UP5K) clock domain.

Mirrors @Orangecrab.Domain@ from the upstream clash-starters @orangecrab@
project, swapping the 48 MHz OrangeCrab oscillator for the iCEbreaker's 12 MHz
one. The period is only consumed by the simulator; for synthesis the actual
clock frequency comes from @set_frequency@ in @icebreaker.pcf@.

The default 'vSystem' reset (asynchronous, active-high) is kept as-is: the
top entity ties it permanently de-asserted, so it never reaches hardware.
-}
module Blinky.Domain where

import Clash.Prelude

-- | 12 MHz oscillator clock of the iCEbreaker board (pin 35).
createDomain
        vSystem
                { vName = "Dom12"
                , vPeriod = hzToPeriod 12_000_000
                }
