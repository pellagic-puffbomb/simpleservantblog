{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings          #-}

module Config where

import           Control.Exception                    (throwIO)
import           Control.Monad.Except                 (ExceptT, MonadError)
import           Control.Monad.Reader                 (MonadIO, MonadReader,
                                                       ReaderT)
import           Control.Monad.Trans.Maybe            (MaybeT (..), runMaybeT)
import qualified Data.ByteString.Char8                as BS
import           Data.Monoid                          ((<>))
import           Data.Pool
import           Database.PostgreSQL.Simple

import qualified Data.Word                            as W
import           Network.Wai                          (Middleware)
import           Network.Wai.Middleware.RequestLogger (logStdout, logStdoutDev)
import           Servant
import           Servant.Server
import           System.Environment                   (lookupEnv)


newtype App a
    = App
    { runApp :: ReaderT Config Handler a
    } deriving ( Functor, Applicative, Monad, MonadReader Config,
                 MonadError ServantErr, MonadIO)


data Config
    = Config
    { getPool :: Pool Connection
    , getEnv  :: Environment
    }

data Environment
    = Local
    | Dev
    | Staging
    | Test
    | Production
    deriving (Eq, Show, Read, Enum, Ord)

-- | This returns a 'Middleware' based on the environment that we're in.
setLogger :: Environment -> Middleware
setLogger Test = id
setLogger _    = logStdout


-- see: http://codeundreamedof.blogspot.com/2015/01/a-connection-pool-for-postgresql-in.html
makePool :: IO (Pool Connection)
makePool = do
  connString <- runMaybeT $ do
        let keys = [ "host="
                   , " port="
                   , " user="
                   , " password="
                   , " dbname="
                   ]
            envs = [ "DB_HOST"
                    , "DB_PORT"
                    , "DB_USER"
                    , "DB_PASSWD"
                    , "DB_NAME"
                    ]
        envVars <- traverse (MaybeT . lookupEnv) envs
        return $ mconcat . zipWith (<>) keys $ BS.pack <$> envVars
  case connString of
    Nothing -> throwIO (userError "Database Configuration not present in environment.")
    Just info -> createPool (connectPostgreSQL info) close 1 10 10
