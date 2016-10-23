{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeFamilies      #-}
{-# LANGUAGE TypeOperators     #-}

module Api.User
    ( UserApi
    , userHandlers
    ) where


import           Control.Monad.Except
import           Control.Monad.IO.Class     (liftIO)
import           Data.Maybe
import           Data.Pool                  (withResource)
import           Data.Proxy
import           Data.Text

import           Database.PostgreSQL.Simple

import           Servant

import           Models.Author              (Author)

data SearchType = FirstName Text
                  | LastName Text
                  | BlogTitle Text
                  | RowId Int


type UserApi = "user" :> Capture "firstName" Text  :> Get  '[JSON] [Author]
  :<|> "user" :> Capture "lastName" Text  :> Get  '[JSON] [Author]
  :<|> "user" :> Capture "id" Int  :> Get  '[JSON] Author

userHandlers conn = userFNameSearchH
                   :<|> userLNameSearchH
                   :<|> userDetailH
  where userFNameSearchH name = withResource conn $ flip getUser (FirstName name)
        userLNameSearchH name = withResource conn $ flip getUser (LastName name)
        userDetailH userId = withResource conn $ flip getUserById userId

getUser :: Connection -> SearchType -> Handler [Author]
getUser conn searchValue = case searchValue of
    FirstName fname -> do
      let q = "select from author where firstName = ?"
      liftIO $ query conn q (Only fname)
    LastName lname -> do
      let q = "select from author where lastName = ?"
      liftIO $ query conn q (Only lname)
    _ -> return []

getUserById :: Connection -> Int -> Handler Author
getUserById conn userId = do
  let q = "select * from author where id = ?"
  res <- liftIO $ query conn q (Only userId)
  case res of
    (x:_) -> return x
    _ -> throwError err404
