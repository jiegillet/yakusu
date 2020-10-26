module Api.Endpoint exposing
    ( Endpoint
    , availabilities
    , availabilitiesID
    , candidates
    , faculty
    , githubLogIn
    , githubUrl
    , interviewTimes
    , matrix
    , matrixID
    , matrixUser
    , matrixZoom
    , request
    , slateLogIn
    , timeBlocks
    , times
    , userAvailabilities
    , zoomLogIn
    , zoomUrl
    )

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



-- ENDPOINTS


slateLogIn : String -> String -> Endpoint
slateLogIn username password =
    url [ "api", "login", "slate" ]
        [ Url.Builder.string "username" username
        , Url.Builder.string "password" password
        ]


githubUrl : Endpoint
githubUrl =
    url [ "api", "oauth", "github" ] []


zoomUrl : Endpoint
zoomUrl =
    url [ "api", "oauth", "zoom" ] []


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


zoomLogIn : Maybe String -> Maybe String -> Endpoint
zoomLogIn maybeCode maybeState =
    let
        toQuery key maybeValue =
            maybeValue
                |> Maybe.toList
                |> List.map (Url.Builder.string key)

        queries =
            toQuery "code" maybeCode ++ toQuery "state" maybeState
    in
    url [ "api", "oauth", "zoom", "callback" ] queries


timeBlocks : Endpoint
timeBlocks =
    url [ "api", "time_blocks" ] []


interviewTimes : Endpoint
interviewTimes =
    url [ "api", "times" ] []


availabilities : Endpoint
availabilities =
    url [ "api", "availabilities" ] []


availabilitiesID : Int -> Endpoint
availabilitiesID id =
    url [ "api", "availabilities", String.fromInt id ] []


userAvailabilities : Endpoint
userAvailabilities =
    url [ "api", "availabilities", "user" ] []


faculty : Endpoint
faculty =
    url [ "api", "faculty" ] []


candidates : Endpoint
candidates =
    url [ "api", "applicants" ] []


matrix : Endpoint
matrix =
    url [ "api", "matrix" ] []


matrixUser : Endpoint
matrixUser =
    url [ "api", "matrix", "user" ] []


matrixZoom : Int -> Endpoint
matrixZoom id =
    url [ "api", "matrix", "zoom", String.fromInt id ] []


matrixID : Int -> Endpoint
matrixID id =
    url [ "api", "matrix", String.fromInt id ] []


times : Endpoint
times =
    url [ "api", "times" ] []
