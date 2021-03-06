{-# LANGUAGE OverloadedStrings #-}
module Network.API.Mandrill.HTTP where

import           Control.Applicative
import           Data.Aeson
import           Data.Monoid
import qualified Data.Text                     as T
import           Network.API.Mandrill.Settings
import           Network.API.Mandrill.Types
import           Network.HTTP.Client
import           Network.HTTP.Client.TLS
import           Network.HTTP.Types

toMandrillResponse :: (MandrillEndpoint ep, FromJSON a, ToJSON rq)
                   => ep
                   -> rq
                   -> Maybe Manager
                   -> IO (MandrillResponse a)
toMandrillResponse ep rq mbMgr = do
  let fullUrl = mandrillUrl <> toUrl ep
  rq' <- parseUrl (T.unpack fullUrl)
  let headers = [(hContentType, "application/json")]
  let jsonBody = encode rq
  let req = rq' {
        method = "POST"
      , requestHeaders = headers
      , requestBody = RequestBodyLBS jsonBody
      }
  mgr <- maybe (newManager tlsManagerSettings) return mbMgr
  res <- responseBody <$> httpLbs req mgr
  case eitherDecode res of
    Left e ->  fail e
    Right v -> return v
