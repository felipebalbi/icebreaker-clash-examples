{- |
Unit tests for the phase generator and the triangle fold in "MoodLight.Pwm".

The prescaler width is an 'C.SNat' parameter, so these run a tiny instance whose
full sweep fits in a short simulation -- the same trick blinky uses for its
counter width.
-}
module Tests.Phase (phaseTests) where

import Prelude

import Test.Tasty
import Test.Tasty.HUnit

import qualified Clash.Prelude as C
import qualified Data.List as List

import MoodLight.Pwm (phase, triangle)

triangleLevels :: [Int]
triangleLevels = List.map (fromIntegral . triangle . fromIntegral) [0 .. 255 :: Int]

phaseTests :: TestTree
phaseTests =
  testGroup
    "Phase"
    [ testCase "triangle starts and ends at zero" $ do
        assertEqual "triangle 0" 0 (triangleLevels List.!! 0)
        assertEqual "triangle 255" 0 (List.last triangleLevels)
    , testCase "triangle peaks at 254 in the middle" $
        -- 127 * 2 == 254. The odd width means it never reaches 255; that costs
        -- 0.4% of full brightness and is not worth complicating the fold for.
        assertEqual "peak" 254 (List.maximum triangleLevels)
    , testCase "triangle rises then falls" $ do
        let (up, down) = List.splitAt 128 triangleLevels
        assertBool "first half must not decrease" (List.and (List.zipWith (<=) up (List.drop 1 up)))
        assertBool "second half must not increase" (List.and (List.zipWith (>=) down (List.drop 1 down)))
    , testCase "phase advances once per prescaler wrap" $ do
        -- SNat 2 => the prescaler wraps every 4 cycles, so 13 cycles of
        -- simulation must show phase reach at least 2. The first sample is
        -- dropped: System's resetGen asserts at cycle 0.
        let xs = List.drop 1 (C.sampleN @C.System 13 (phase (C.SNat @2)))
        assertBool
          ("expected phase to advance, saw " ++ show xs)
          (List.maximum (List.map fromIntegral xs :: [Int]) >= 2)
    ]
