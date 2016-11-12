module Admin exposing (..)

import Platform.Cmd exposing (none)
import Date exposing (..)
import Dict exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import List exposing (..)
import String exposing (..)
import Task exposing (Task, perform, succeed)
import Navigation
import RouteUrl

import Admin.AdminApi exposing (..)
import Admin.Routes exposing (..)
import Admin.Types exposing (..)
import Admin.Views exposing (..)
import Blog.Api as Api
import Blog.Types as BlogTypes


type alias InvokeOptions = { username : String }

main : Program InvokeOptions
main =
    RouteUrl.programWithFlags
        { delta2url = delta2url
        , location2messages = location2messages
        , init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }


init : InvokeOptions -> (Model, Cmd Msg)
init options =
  let
      state =
          { route = AdminMainR, user = options.username, content = Nothing}
  in
      ( state, none )

update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        NoOp ->
          model ! []
        GoToAdminMain ->
          { model | content = Nothing, route = AdminMainR } ! []
        FromAdminBackend backend ->
          case backend of
            AdminResultResp _ ->
              { model | content = Nothing } ! []
            _ ->
              { model | content = Just backend } ! []
        FromAdminFrontend frontend ->
          case frontend of
            AdminGetList someList ->
              case someList of
                ListPosts ->
                  { model | route = AdminPostListR } ! [ retrieveList ListPosts ]
                ListUsers ->
                  { model | route = AdminUserListR } ! [ retrieveList ListUsers ]
                ListSeries ->
                  { model | route = AdminSeriesListR } ! [ retrieveList ListSeries ]
            AdminGetDetail someThing ->
              case someThing of
                DetailPost postId ->
                  { model | route = AdminPostDetailR postId } ! [ retrievePost postId ]
                DetailSeries seriesId ->
                    { model | route = AdminSeriesDetailR seriesId } ! [ retrieveSeries seriesId ]
                DetailUser userId ->
                  { model | route = AdminUserDetailR userId } ! [ retrieveUser userId ]
            AdminDelete item ->
              model ! [ deleteItem item ]
            AdminCreate item ->
              model ! [ createItem item ]
            AdminEdit item ->
              model ! [ editItem item ]
        Error error ->
          { model | content = Just <| BackendError error } ! []


retrieveList : ListThing -> Cmd Msg
retrieveList listRequested = case listRequested of
  ListPosts -> Api.getPost
    |> Task.mapError toString
    |> Task.perform Error (\posts -> FromAdminBackend <| AdminPostList posts)
  ListSeries -> Api.getSeries
    |> Task.mapError toString
    |> Task.perform Error (\series -> FromAdminBackend <| AdminSeriesList series)
  ListUsers -> getAdminUser
    |> Task.mapError toString
    |> Task.perform Error (\posts -> FromAdminBackend <| AdminUserList posts)

retrievePost : BlogTypes.BlogPostId -> Cmd Msg
retrievePost postId = Api.getPostById postId |> postDetailResponse

retrieveSeries : SeriesId -> Cmd Msg
retrieveSeries seriesId = Api.getSeriesById seriesId |> seriesDetailResponse

retrieveUser : UserId -> Cmd Msg
retrieveUser userId = getAdminUserById userId |> userDetailResponse

createItem : Item -> Cmd Msg
createItem item = case item of
  PI post -> postAdminPost post |> postDetailResponse
  AI author -> postAdminUser author |> userDetailResponse
  SI series -> postAdminSeries series |> seriesDetailResponse

deleteItem : Item -> Cmd Msg
deleteItem item = case item of
  PI post -> deleteAdminPostById post.bid |> genericResponse
  AI author -> deleteAdminUserById author.aid |> genericResponse
  SI series -> deleteAdminSeriesById series.sid |> genericResponse

editItem : Item -> Cmd Msg
editItem item = case item of
  PI post -> putAdminPostById post.bid post |> genericResponse
  AI author -> putAdminUserById author.aid author |> genericResponse
  SI series -> putAdminSeriesById series.sid series |> genericResponse


-- Task Response Boilerplate --
genericResponse : Task Http.Error ResultResp -> Cmd Msg
genericResponse task = task
  |> Task.mapError toString
  |> Task.perform Error (\rr -> FromAdminBackend <| AdminResultResp rr)

userDetailResponse : Task Http.Error (Author) -> Cmd Msg
userDetailResponse task = task
  |> Task.mapError toString
  |> Task.perform Error (\user -> FromAdminBackend <| AdminUserDetail user)

postDetailResponse : Task Http.Error (BlogPost) -> Cmd Msg
postDetailResponse task = task
  |> Task.mapError toString
  |> Task.perform Error (\post -> FromAdminBackend <| AdminPostDetail post)

seriesDetailResponse : Task Http.Error (BlogSeries) -> Cmd Msg
seriesDetailResponse task = task
  |> Task.mapError toString
  |> Task.perform Error (\series -> FromAdminBackend <| AdminSeriesDetail series)
