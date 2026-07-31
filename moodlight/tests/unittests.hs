import Prelude

import Test.Tasty

import qualified Tests.Gamma
import qualified Tests.Phase
import qualified Tests.Pwm

main :: IO ()
main =
  defaultMain $
    testGroup
      "."
      [ Tests.Gamma.gammaTests
      , Tests.Phase.phaseTests
      , Tests.Pwm.pwmTests
      ]
