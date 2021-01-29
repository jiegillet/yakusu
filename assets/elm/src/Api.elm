port module Api exposing
    ( Cred(..)
    , User
    , application
    , credDecoder
    , credName
    , get
    , logout
    , mutationRequest
    , noCredGet
    , patch
    , post
    , queryRequest
    , storeChanged
    , storeCreds
    )

import Api.Endpoint as Endpoint exposing (Endpoint)
import Browser
import Browser.Navigation exposing (Key)
import Graphql.Http exposing (Error)
import Graphql.Operation exposing (RootMutation, RootQuery)
import Graphql.SelectionSet exposing (SelectionSet)
import Http exposing (Body, Expect)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Json.Encode.Extra as Encode
import Maybe.Extra as Maybe
import RemoteData exposing (RemoteData, WebData)
import Url exposing (Url)



-- USER CREDENTIALS


type Cred
    = Cred User String


type alias User =
    { name : String }


credName : Cred -> String
credName cred =
    case cred of
        Cred { name } _ ->
            name


getToken : Cred -> String
getToken cred =
    case cred of
        Cred _ token ->
            token


credEncoder : Cred -> Value
credEncoder cred =
    Encode.object
        (case cred of
            Cred { name } token ->
                [ ( "name", Encode.string name )
                , ( "token", Encode.string token )
                ]
        )


decodeAndMap : Decoder a -> Decoder (a -> b) -> Decoder b
decodeAndMap decoderA =
    Decode.andThen (\aToB -> Decode.map aToB decoderA)


credDecoder : Decoder Cred
credDecoder =
    Decode.oneOf
        [ Decode.map Cred (Decode.map User (Decode.field "name" Decode.string))
        ]
        |> decodeAndMap (Decode.field "token" Decode.string)



-- PORTS


port store : Maybe Value -> Cmd msg


storeCreds : Cred -> Cmd msg
storeCreds cred =
    Encode.object
        [ ( "user", credEncoder cred )
        ]
        |> Just
        |> store


port onStoreChange : (Value -> msg) -> Sub msg


storeChanged : (Maybe Cred -> msg) -> Sub msg
storeChanged toMsg =
    onStoreChange (decodeStore >> toMsg)


decodeStore : Value -> Maybe Cred
decodeStore value =
    decodeCred value


decodeCred : Value -> Maybe Cred
decodeCred value =
    value
        |> Decode.decodeValue (Decode.field "user" credDecoder)
        |> Result.toMaybe


logout : Cmd msg
logout =
    store Nothing



-- APPLICATION


application :
    { init : Maybe Cred -> Url -> Key -> ( model, Cmd msg )
    , onUrlChange : Url -> msg
    , onUrlRequest : Browser.UrlRequest -> msg
    , subscriptions : model -> Sub msg
    , update : msg -> model -> ( model, Cmd msg )
    , view : model -> Browser.Document msg
    }
    -> Program Value model msg
application config =
    let
        init flags url navKey =
            config.init (decodeCred flags) url navKey
    in
    Browser.application
        { init = init
        , onUrlChange = config.onUrlChange
        , onUrlRequest = config.onUrlRequest
        , subscriptions = config.subscriptions
        , update = config.update
        , view = config.view
        }



-- HTTP


credHeader : Cred -> Http.Header
credHeader cred =
    Http.header "authorization" ("Bearer " ++ getToken cred)


noCredGet : Endpoint -> (WebData a -> msg) -> Decoder a -> Cmd msg
noCredGet url toMsg decoder =
    Endpoint.request
        { method = "GET"
        , url = url
        , expect = Http.expectJson (RemoteData.fromResult >> toMsg) decoder
        , headers = []
        , body = Http.emptyBody
        , timeout = Nothing
        , tracker = Nothing
        }


get : Endpoint -> Cred -> (WebData a -> msg) -> Decoder a -> Cmd msg
get url cred toMsg decoder =
    Endpoint.request
        { method = "GET"
        , url = url
        , expect = Http.expectJson (RemoteData.fromResult >> toMsg) decoder
        , headers = [ credHeader cred ]
        , body = Http.emptyBody
        , timeout = Nothing
        , tracker = Nothing
        }


post : Endpoint -> Cred -> Body -> Expect msg -> Cmd msg
post url cred body expect =
    Endpoint.request
        { method = "POST"
        , url = url
        , expect = expect
        , headers = [ credHeader cred ]
        , body = body
        , timeout = Nothing
        , tracker = Nothing
        }


patch : Endpoint -> Cred -> Value -> (WebData a -> msg) -> Decoder a -> Cmd msg
patch url cred bodyEncoder toMsg decoder =
    Endpoint.request
        { method = "PATCH"
        , url = url
        , expect = Http.expectJson (RemoteData.fromResult >> toMsg) decoder
        , headers = [ credHeader cred ]
        , body = Http.jsonBody bodyEncoder
        , timeout = Nothing
        , tracker = Nothing
        }



-- GRAPHQL


queryRequest : Cred -> SelectionSet a RootQuery -> (RemoteData (Error a) a -> msg) -> Cmd msg
queryRequest cred query toMsg =
    query
        |> Endpoint.queryRequest Endpoint.graphql
        |> Graphql.Http.withHeader "authorization" ("Bearer " ++ getToken cred)
        |> Graphql.Http.send (RemoteData.fromResult >> toMsg)


mutationRequest : Cred -> SelectionSet a RootMutation -> (RemoteData (Error a) a -> msg) -> Cmd msg
mutationRequest cred mutation toMsg =
    mutation
        |> Endpoint.mutationRequest Endpoint.graphql
        |> Graphql.Http.withHeader "authorization" ("Bearer " ++ getToken cred)
        |> Graphql.Http.send (RemoteData.fromResult >> toMsg)
