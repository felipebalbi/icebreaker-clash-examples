{- |
Unit tests for "MoodLight.Gamma".

The table is built by Template Haskell at compile time, so these assertions
double as a check that the TH spliced what we think it spliced.
-}
module Tests.Gamma (gammaTests) where

import Prelude

import Test.Tasty
import Test.Tasty.HUnit

import qualified Data.List as List

import MoodLight.Gamma (gamma)

-- | Every output level, in input order.
levels :: [Int]
levels = List.map (fromIntegral . gamma . fromIntegral) [0 .. 255 :: Int]

gammaTests :: TestTree
gammaTests =
  testGroup
    "Gamma"
    [ testCase "endpoints are exact" $ do
        assertEqual "gamma 0" 0 (levels List.!! 0)
        assertEqual "gamma 255" 255 (List.last levels)
    , testCase "curve is monotonic non-decreasing" $
        assertBool
          "gamma must never decrease as input rises"
          (List.and (List.zipWith (<=) levels (List.drop 1 levels)))
    , testCase "curve is not the identity" $
        -- A 2.2 curve compresses the low end hard: mid input maps well below mid
        -- output. If this fails, the TH splice probably produced a linear ramp.
        assertBool
          ("expected gamma 128 to be well below 128, got " ++ show (levels List.!! 128))
          (levels List.!! 128 < 80)
    ]
