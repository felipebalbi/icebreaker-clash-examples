{- |
Unit tests for "MoodLight.Mode".

This is the module that justifies the whole approach: button bounce is miserable
to verify on hardware and trivial to verify as a list.

The bounce tests drive the /full chain/ -- 'debounce' feeding 'modeFsm' -- with a
raw active-low waveform, because that is the only arrangement that actually
exercises debouncing. Driving 'modeFsm' alone would just be testing @succ@.

Every stimulus starts at cycle 1 or later: 'C.sampleN' runs the System domain,
whose 'C.resetGen' asserts reset during cycle 0, so anything there is swallowed.
-}
module Tests.Mode (modeTests) where

import Prelude

import Test.Tasty
import Test.Tasty.HUnit

import qualified Clash.Prelude as C
import qualified Data.List as List

import MoodLight.Mode (Mode (..), debounce, modeFsm, nextMode, render)

{- | Debounce window used by the tests: @2 ^ 4@ = 16 cycles.

Small enough that a press fits in a short simulation, large enough that the
bounce burst below is shorter than one window -- which is the physical
precondition for any debouncer to work.
-}
type TestWindow = 4

-- | Run a raw active-low button waveform through the whole chain.
runRaw :: [C.Bit] -> [Mode]
runRaw raw =
  List.drop
    1
    ( C.sampleN @C.System
        (List.length raw + 1)
        (modeFsm (debounce (C.SNat @TestWindow) (C.fromList (C.high : raw ++ List.repeat C.high))))
    )

-- | Idle (released) for @n@ cycles. Active low, so released is high.
released :: Int -> [C.Bit]
released n = List.replicate n C.high

-- | Settled press for @n@ cycles.
pressed :: Int -> [C.Bit]
pressed n = List.replicate n C.low

{- | A contact bouncing for 12 cycles as it closes: it rings between open and
closed before settling. Shorter than one 16-cycle debounce window.
-}
bounce :: [C.Bit]
bounce = List.concat (List.replicate 6 [C.low, C.high])

-- | One complete press: idle, ring, hold, release.
onePress :: [C.Bit]
onePress = released 20 ++ bounce ++ pressed 60 ++ released 60

modeTests :: TestTree
modeTests =
  testGroup
    "Mode"
    [ testCase "nextMode steps and wraps" $ do
        assertEqual "Off -> Solid" Solid (nextMode Off)
        assertEqual "Solid -> Breathe" Breathe (nextMode Solid)
        assertEqual "Breathe -> Rainbow" Rainbow (nextMode Breathe)
        assertEqual "Rainbow wraps to Off" Off (nextMode Rainbow)
    , testCase "a clean press advances exactly one mode" $
        assertEqual
          "final mode"
          Solid
          (List.last (runRaw (released 20 ++ pressed 60 ++ released 60)))
    , testCase "a BOUNCING press still advances exactly one mode" $
        -- The whole point. On hardware this needs a scope; here it is a list.
        assertEqual "final mode" Solid (List.last (runRaw onePress))
    , testCase "four bouncing presses return to the starting mode" $
        assertEqual
          "final mode"
          Off
          (List.last (runRaw (List.concat (List.replicate 4 onePress))))
    , testCase "holding the button does not keep advancing" $
        -- One press, held a long time, must still be one advance.
        assertEqual
          "final mode"
          Solid
          (List.last (runRaw (released 20 ++ pressed 400 ++ released 60)))
    , testCase "render is dark when off and lit when solid" $ do
        assertEqual "Off" (0, 0, 0) (render Off 128)
        assertBool "Solid must be lit" (render Solid 128 /= (0, 0, 0))
    , testCase "render Breathe is grey, Rainbow is not" $ do
        let (r1, g1, b1) = render Breathe 200
        assertBool "Breathe channels must match" (r1 == g1 && g1 == b1)
        let (r2, g2, b2) = render Rainbow 200
        assertBool "Rainbow channels must differ" (not (r2 == g2 && g2 == b2))
    ]
