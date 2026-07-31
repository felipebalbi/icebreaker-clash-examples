import Prelude

import Test.Tasty

import qualified Tests.Gamma
import qualified Tests.Mode
import qualified Tests.Phase
import qualified Tests.Pwm

main :: IO ()
main =
  defaultMain $
    testGroup
      "."
      [ Tests.Gamma.gammaTests
      , Tests.Mode.modeTests
      , Tests.Phase.phaseTests
      , Tests.Pwm.pwmTests
      ]
