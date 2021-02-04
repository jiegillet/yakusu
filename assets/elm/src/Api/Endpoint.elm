module Api.Endpoint exposing
    ( Endpoint
    , allPages
    , githubLogIn
    , githubUrl
    , graphql
    , mutationRequest
    , pages
    , queryRequest
    , request
    )

import Graphql.Http exposing (Request)
import Graphql.Operation exposing (RootMutation, RootQuery)
import Graphql.SelectionSet exposing (SelectionSet)
import Http exposing (Body, Expect, Header)
import Maybe.Extra as Maybe
import Url.Builder exposing (QueryParameter)



-- TYPES


type Endpoint
    = Endpoint String


unwrap : Endpoint -> String
unwrap (Endpoint str) =
    str


url : List String -> List QueryParameter -> Endpoint
url path queries =
    Url.Builder.absolute path queries
        |> Endpoint



-- HTTP


request :
    { method : String
    , headers : List Header
    , url : Endpoint
    , body : Body
    , expect : Expect msg
    , timeout : Maybe Float
    , tracker : Maybe String
    }
    -> Cmd msg
request config =
    Http.request
        { body = config.body
        , expect = config.expect
        , headers = config.headers
        , method = config.method
        , timeout = config.timeout
        , url = unwrap config.url
        , tracker = config.tracker
        }



-- GRAPHQL


mutationRequest : Endpoint -> SelectionSet a RootMutation -> Request a
mutationRequest endpoint =
    Graphql.Http.mutationRequest (unwrap endpoint)


queryRequest : Endpoint -> SelectionSet a RootQuery -> Request a
queryRequest endpoint =
    Graphql.Http.queryRequest (unwrap endpoint)



-- ENDPOINTS


graphql : Endpoint
graphql =
    url [ "api" ] []


pages : Endpoint
pages =
    url [ "api", "rest", "pages" ] []


allPages : String -> Endpoint
allPages bookId =
    url [ "api", "rest", "pages", "all", bookId ] []


githubUrl : Endpoint
githubUrl =
    url [ "api", "oauth", "github" ] []


githubLogIn : Maybe String -> Maybe String -> Endpoint
githubLogIn maybeCode maybeState =
    let
        toQuery key maybeValue =
            maybeValue
                |> Maybe.toList
                |> List.map (Url.Builder.string key)

        queries =
            toQuery "code" maybeCode ++ toQuery "state" maybeState
    in
    url [ "api", "oauth", "callback" ] queries
