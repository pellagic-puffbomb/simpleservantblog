{-# LANGUAGE DataKinds     #-}
{-# LANGUAGE TypeFamilies  #-}
{-# LANGUAGE TypeOperators #-}

module Api
    ( PostApi
    , adminProxyApi
    , postApi
    , createAllTables
    , withAssets
    , withAssetsApp
    , withoutAssets
    , withoutAssetsApp
    , withoutAssetsServer
    ) where


import           Data.Pool                               (Pool)
import           Data.Proxy
import           Database.PostgreSQL.Simple              hiding ((:.))
import           Network.Wai                             (Application, Request)
import           Network.Wai.MakeAssets
import           Servant
import           Servant.Server.Experimental.Auth        (AuthHandler)
import           Servant.Server.Experimental.Auth.Cookie
import           Web.Users.Types                         (UserStorageBackend (..))

import           Api.Admin
import           Api.Login
import           Api.Post
import           Html.About
import           Html.Contact
import           Html.Home
import           Html.Projects
import           Models.Author                           (createAuthorTable)
import           Models.Media                            (createPostMediaTable)
import           Models.Post                             (createPostTable,
                                                          createSeriesTable)


-- This one is separate so elm can generate for it
type WithHtml = HomePage
                :<|> "posts" :> BlogMain
                :<|> "about" :> AboutPage
                :<|> ContactApi
                :<|> ProjectsApi
                :<|> PostApi

apihandlers :: Pool Connection -> Server WithHtml
apihandlers conn = homePage
                  :<|> blogMain
                  :<|> aboutPage
                  :<|> contactServer
                  :<|> projectsServer
                  :<|> postHandlers conn

-- Used in production
type WithoutAssets =  WithHtml
                    :<|> LoginApi
                    :<|> AdminBackend

withoutAssetsServer :: Pool Connection -> AuthCookieSettings -> RandomSource -> PersistentServerKey -> IO (Server WithoutAssets)
withoutAssetsServer conn settings rs key = return $ apihandlers conn
                                      :<|> loginServer conn settings rs key
                                      :<|> adminBackendHandlers conn

withoutAssetsApp :: Pool Connection -> AuthCookieSettings -> RandomSource -> PersistentServerKey -> IO Application
withoutAssetsApp conn settings rs key = do
  let context = (defaultAuthHandler settings key :: AuthHandler Request (WithMetadata Username)) :. EmptyContext
  server <- withoutAssetsServer conn settings rs key
  return $ serveWithContext withoutAssets context server


-- Used in development
type WithAssets =  WithHtml
                  :<|> LoginApi
                  :<|> AdminBackend
                  :<|> "assets" :> Raw

withAssetsServer :: Pool Connection -> AuthCookieSettings -> RandomSource -> PersistentServerKey -> IO (Server WithAssets)
withAssetsServer conn settings rs key =
  return (apihandlers conn
            :<|> loginServer conn settings rs key
            :<|> adminBackendHandlers conn
            :<|> serveDirectoryFileServer "assets")

withAssetsApp :: Pool Connection -> AuthCookieSettings -> RandomSource -> PersistentServerKey -> IO Application
withAssetsApp conn settings rs key = do
  let context = (defaultAuthHandler settings key :: AuthHandler Request (WithMetadata Username)) :. EmptyContext
  server <- withAssetsServer conn settings rs key
  return $ serveWithContext withAssets context server


-- Auxiliary, helper things
createAllTables :: Connection -> IO ()
createAllTables conn = initUserBackend conn >>
    execute_ conn createAuthorTable >>
      execute_ conn createSeriesTable >>
        execute_ conn createPostTable >>
          execute_ conn createPostMediaTable >>
            return ()

postApi :: Proxy PostApi
postApi = Proxy

adminBackendProxyApi :: Proxy AdminBackend
adminBackendProxyApi = Proxy

adminProxyApi :: Proxy AdminApi
adminProxyApi = Proxy

withAssets :: Proxy WithAssets
withAssets = Proxy

withoutAssets :: Proxy WithoutAssets
withoutAssets = Proxy
