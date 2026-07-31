{- Wrapper around Clash's batch compiler, with the moodlight project in scope.

   Generate Verilog with:

       cabal run clash -- MoodLight --verilog

   The HDL lands in verilog/MoodLight.topEntity/. This file is taken verbatim
   from the upstream clash-starters projects. -}

import Clash.Main (defaultMain)
import System.Environment (getArgs)
import Prelude

main :: IO ()
main = getArgs >>= defaultMain
