import Prelude

import Test.Tasty

import qualified Tests.Blinky
import qualified Tests.BlinkyWithReset

main :: IO ()
main =
  defaultMain $
    testGroup
      "."
      [ Tests.Blinky.blinkyTests
      , Tests.BlinkyWithReset.blinkyWithResetTests
      ]
