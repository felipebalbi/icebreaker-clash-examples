{-# LANGUAGE TemplateHaskell #-}

{- |
Perceptual brightness curve for the mood light.

Human brightness perception is roughly logarithmic, so a linear PWM ramp looks
like it spends most of its time near full. A gamma 2.2 curve (the sRGB-ish
exponent) corrects for that, and the difference is obvious by eye.

== Where the arithmetic happens

'gammaTable' is built by Template Haskell: GHC evaluates the 'Double' expression
below at /compile time/ and splices in 256 literals. Nothing floating-point ever
reaches the FPGA -- the hardware only ever sees a constant table. This is the
cleanest example in the project of the elaboration-time / run-time split.

== Cost

Each call site of 'gamma' is an independent 256-entry lookup, and the synthesiser
builds one copy of the mux tree per call. "MoodLight.Mode".'MoodLight.Mode.render'
calls it three times (one per channel), which is the bulk of the design's LUT
usage. That is deliberate: three channels genuinely need three simultaneous
lookups, because unlike a CPU there is no reusing one result across time.
-}
module MoodLight.Gamma (gammaTable, gamma) where

import Clash.Prelude

{- | 256-entry gamma 2.2 curve, mapping linear input to perceptual output.
Monotonic non-decreasing, with exact endpoints @0 -> 0@ and @255 -> 255@.
-}
gammaTable :: Vec 256 (Unsigned 8)
gammaTable =
  $( listToVecTH
       [ round ((fromIntegral i / 255 :: Double) ** 2.2 * 255) :: Unsigned 8
       | i <- [0 .. 255 :: Int]
       ]
   )

-- | Look up one level. Combinational: this is a mux tree, not a memory.
gamma :: Unsigned 8 -> Unsigned 8
gamma i = gammaTable !! i
