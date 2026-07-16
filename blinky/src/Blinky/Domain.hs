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

{- | 12 MHz oscillator clock of the iCEbreaker board (pin 35). Default 'vSystem'
reset (asynchronous, active-high) is kept; @Blinky@ ties it permanently
de-asserted so it never reaches hardware.
-}
createDomain
  vSystem
    { vName = "Dom12"
    , vPeriod = hzToPeriod 12_000_000
    }

{- | Same 12 MHz clock, but with an /asynchronous, active-low/ reset — used by
@BlinkyWithReset@, whose reset is wired to the iCEbreaker user button (it
idles high through a pull-up and shorts to ground when pressed, so a low
level means \"reset asserted\"). Mirrors the SpinalHDL
@resetKind = ASYNC, resetActiveLevel = LOW@ choice and parallels the upstream
orangecrab domain, which likewise drives an active-low button reset.
-}
createDomain
  vSystem
    { vName = "Dom12Rst"
    , vPeriod = hzToPeriod 12_000_000
    , vResetKind = Asynchronous
    , vResetPolarity = ActiveLow
    }
