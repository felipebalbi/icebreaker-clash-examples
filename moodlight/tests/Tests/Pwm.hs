{- |
Unit tests for "MoodLight.Pwm".

Checks the two things that are invisible on hardware until they are wrong: the
exact duty ratio, and which bit of the output is which colour.
-}
module Tests.Pwm (pwmTests) where

import Prelude

import Test.Tasty
import Test.Tasty.HUnit

import qualified Clash.Prelude as C
import qualified Data.List as List

import MoodLight.Pwm (pwmRGB)

{- | Count high cycles on one channel over a full 256-cycle PWM period.

Index 2 is red, 1 is green, 0 is blue -- see 'MoodLight.Pwm.pwmRGB'. The first
sample is dropped because the System domain's 'C.resetGen' asserts at cycle 0.
-}
highCycles :: Int -> (C.Unsigned 8, C.Unsigned 8, C.Unsigned 8) -> Int
highCycles i duties =
  List.length
    ( List.filter
        (== 1)
        ( List.map
            (\v -> C.pack (v C.! i))
            (List.drop 1 (C.sampleN @C.System 257 (pwmRGB (pure duties))))
        )
    )

pwmTests :: TestTree
pwmTests =
  testGroup
    "Pwm"
    [ testCase "duty 0 is always low" $
        assertEqual "red" 0 (highCycles 2 (0, 0, 0))
    , testCase "duty 64 is high for 64 of 256 cycles" $
        assertEqual "red" 64 (highCycles 2 (64, 0, 0))
    , testCase "duty 255 is high for 255 of 256 cycles" $
        -- A comparator PWM can never be fully on: c < 255 is false at c == 255.
        assertEqual "red" 255 (highCycles 2 (255, 0, 0))
    , testCase "channels map to the right bits" $ do
        -- Asymmetric duties: if the tuple is packed backwards this fails.
        let duties = (64, 128, 255)
        assertEqual "index 2 is red" 64 (highCycles 2 duties)
        assertEqual "index 1 is green" 128 (highCycles 1 duties)
        assertEqual "index 0 is blue" 255 (highCycles 0 duties)
    ]
