import Prelude

import Test.Tasty

import qualified Tests.Gamma

main :: IO ()
main =
  defaultMain $
    testGroup
      "."
      [ Tests.Gamma.gammaTests
      ]
