{-# LANGUAGE Arrows                #-}
{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE DeriveDataTypeable    #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE NoImplicitPrelude     #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE QuasiQuotes           #-}
{-# LANGUAGE TypeApplications      #-}
{-# LANGUAGE TypeFamilies          #-}

module Models.Post (
  BlogSeries(..)
  , BlogPost(..)
  , PostSeries(..)
  , PostOverview(..)
  , postOverviewAllQuery
  , seriesPostsQuery
  , createSeriesTable
  , createPostTable
  ) where

import           Control.Applicative                ((<$>), (<*>))
import           Control.Lens
import           Data.Aeson                         hiding (Series)
import qualified Data.ByteString.Char8              as B
import           Data.Data
import           Data.Int
import           Data.Maybe
import           Data.Proxy
import qualified Data.Text                          as T
import           Data.Time                          (UTCTime)
import           Database.PostgreSQL.Simple.FromRow (FromRow, field, fromRow)
import           Database.PostgreSQL.Simple.SqlQQ
import           Database.PostgreSQL.Simple.ToField (toField)
import           Database.PostgreSQL.Simple.ToRow   (ToRow, toRow)
import           Database.PostgreSQL.Simple.Types   (Query (..))
import           GHC.Generics
import           Prelude                            (Eq, Int, Show, ($), (.))
import           Servant.Elm
import           Web.FormUrlEncoded                 (FromForm)

--
-- Api Helpers for Frontend --
--

-- PostOverview
data PostOverview = PostOverview {
  pid                  :: !Int
  , ptitle             :: !T.Text
  , psynopsis          :: Maybe T.Text
  , ppubdate           :: Maybe UTCTime
  , pordinal           :: Maybe Int
  , pseriesid          :: Maybe Int
  , pseriesname        :: Maybe T.Text
  , pseriesdescription :: Maybe T.Text
  } deriving (Eq, Show, Generic)
instance ElmType PostOverview
instance ToJSON PostOverview
instance FromJSON PostOverview
instance FromRow PostOverview where
  fromRow = PostOverview <$> field <*> field <*> field
    <*> field <*> field <*> field
    <*> field <*> field

postOverviewAllQuery :: Query
postOverviewAllQuery = Query $ B.unwords [
                                  "select p.id, p.title, p.synopsis, p.pubdate, p.ordinal, "
                                  , "s.id, s.name, s.description from post p left join series s "
                                  , "on p.seriesid = s.id where p.pubdate is NOT NULL "
                                  , "order by p.pubdate DESC"
                                  ]

seriesPostsQuery :: Query
seriesPostsQuery = Query $ B.unwords [
                              "select id, authorid, seriesid, title, body, synopsis, "
                              , "created, modified, pubdate, ordinal "
                              , "from post where seriesid = (select seriesid from post p where p.id = ?) "
                              ,  "and pubdate is NOT NULL "
                              , "order by ordinal"
                              ]
data PostSeries = PostSeries {
  previous  :: [BlogPost]
  , current :: BlogPost
  , next    :: [BlogPost]
  , series  :: BlogSeries
} deriving (Eq, Show, Generic)
instance ElmType PostSeries
instance ToJSON PostSeries
instance FromJSON PostSeries


--
-- Table Definitions --
--
-- Table Definition Series

-- Post
data BlogPost = BlogPost {
  bid        :: !Int
  , authorId :: !Int
  , seriesId :: Maybe Int
  , title    :: !T.Text
  , body     :: Maybe T.Text
  , synopsis:: Maybe T.Text
  , created  :: !UTCTime
  , modified :: Maybe UTCTime
  , pubdate  :: Maybe UTCTime
  , ordinal  :: Maybe Int
  } deriving (Eq, Show, Generic, Data)

instance FromForm BlogPost
instance ElmType BlogPost
instance FromJSON BlogPost
instance ToJSON BlogPost
instance FromRow BlogPost where
  fromRow = BlogPost <$> field <*> field <*> field
    <*> field <*> field <*> field
    <*> field <*> field <*> field
    <*> field

instance ToRow BlogPost where
  toRow p =  [toField $ bid p
             , toField $ authorId p
             , toField $ seriesId p
             , toField $ title p
             , toField $ body p
             , toField $ synopsis p
             , toField $ created p
             , toField $ modified p
             , toField $ pubdate p
             , toField $ ordinal p
             ]


createPostTable :: Query
createPostTable =
   [sql|
         CREATE TABLE IF NOT EXISTS post (
            id            SERIAL UNIQUE,
            authorid      INTEGER NOT NULL,
            seriesid      integer,
            title         character varying(255) NOT NULL,
            body          text,
            synopsis      text,
            created       timestamp with time zone NOT NULL,
            modified      timestamp with time zone,
            pubdate       timestamp with time zone,
            ordinal       integer,
            CONSTRAINT post_pkey PRIMARY KEY (id),
            CONSTRAINT author_id_post_fk FOREIGN KEY (authorid)
                REFERENCES public.author (id) MATCH SIMPLE
                ON UPDATE NO ACTION ON DELETE CASCADE,
            CONSTRAINT series_id_post_fk FOREIGN KEY (seriesid)
                REFERENCES public.series (id) MATCH SIMPLE
                ON UPDATE NO ACTION ON DELETE NO ACTION
         );
   |]


data BlogSeries = BlogSeries {
  sid           :: !Int
  , name        :: !T.Text
  , description :: !T.Text
  , parentid    :: Maybe Int
} deriving (Eq, Show, Generic, Data)

instance ElmType BlogSeries
instance FromJSON BlogSeries
instance ToJSON BlogSeries
instance FromRow BlogSeries where
  fromRow = BlogSeries <$> field <*> field <*> field <*> field

instance ToRow BlogSeries where
  toRow s =  [toField $ sid s
             , toField $ name s
             , toField $ description s
             , toField $ parentid s]

createSeriesTable :: Query
createSeriesTable =
  [sql|
     CREATE TABLE series (
       id          serial primary key,
       name        text NOT NULL,
       description text NOT NULL,
       parentid    integer,
       CONSTRAINT parent_series_fkey FOREIGN KEY (parentid)
           REFERENCES public.series (id) MATCH SIMPLE
           ON UPDATE NO ACTION ON DELETE NO ACTION
    );
  |]
