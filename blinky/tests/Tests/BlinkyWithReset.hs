{- |
Unit test for "BlinkyWithReset".

Exercises the one thing this variant adds over "Blinky": the reset port. The
counter ('blink') is the same, so we drive it through the active-low 'Dom12Rst'
domain with a reset waveform and check the two halves of reset behaviour:

  1. while reset is asserted (button held, line low) the LED stays low — the
     counter is clamped at 0;
  2. once reset is released the counter free-runs again and the LED toggles.

Like the "Blinky" test this is plain Haskell on the sampled output stream — no
simulator. We build the reset from a @[Bool]@ with 'C.unsafeFromActiveLow'
(low = asserted), exactly the polarity the user button presents.
-}
module Tests.BlinkyWithReset (blinkyWithResetTests) where

import Prelude

import Test.Tasty
import Test.Tasty.HUnit

import qualified Clash.Prelude as C
import qualified Data.List as List

import Blinky (blink)
import Blinky.Domain (Dom12Rst)

{- | Run the 4-bit counter with the reset held asserted (low) for @hold@ cycles,
then released (high) for @run@ cycles, in the active-low 'Dom12Rst' domain.
-}
runWithReset :: Int -> Int -> [C.Bit]
runWithReset hold run =
  C.sampleN @Dom12Rst
    (hold + run)
    ( C.withClockResetEnable
        C.clockGen
        (C.unsafeFromActiveLow (C.fromList (List.replicate hold False ++ List.replicate run True)))
        C.enableGen
        (blink (C.SNat @4))
    )

countToggles :: [C.Bit] -> Int
countToggles xs =
  List.length (List.filter id (List.zipWith (/=) xs (List.drop 1 xs)))

blinkyWithResetTests :: TestTree
blinkyWithResetTests =
  testGroup
    "BlinkyWithReset"
    [ testCase "LED stays low while reset is asserted" $
        assertBool
          "LED should be clamped low under reset"
          (all (== C.low) (runWithReset 16 0))
    , testCase "LED toggles after reset is released" $ do
        let toggles = countToggles (List.drop 16 (runWithReset 16 64))
        assertBool
          ("expected the LED to toggle after release, saw " ++ show toggles)
          (toggles >= 2)
    ]
