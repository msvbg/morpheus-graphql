{-# LANGUAGE OverloadedStrings #-}

module Main
  ( main
  ) where

import           Control.Monad.IO.Class (liftIO)

--import           Example.Mythology      (mythologyApi)
import           Example.Schema         (gqlApi)
import           Web.Scotty

main :: IO ()
main = scotty 3000 $ post "/api" $ raw =<< (liftIO . gqlApi =<< body)
