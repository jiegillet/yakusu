module Page.Login exposing (..)

import Api exposing (Cred(..), User)
import Api.Endpoint as Endpoint
import Browser.Events
import Browser.Navigation as Navigation
import Common exposing (Context)
import Dict exposing (Dict)
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Http exposing (Error)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import RemoteData exposing (RemoteData(..), WebData)
import Route exposing (Route)
import Style
import Url.Builder



-- TYPES


type alias Model =
    { context : Context
    , loginInfo : LoginInfo
    , cred : WebData Cred
    , routeBackTo : Maybe Route
    , showBlank : Bool
    }


init : Maybe Route -> Context -> ( Model, Cmd Msg )
init maybeRoute context =
    let
        ( show, cmd ) =
            case ( maybeRoute, context.cred ) of
                _ ->
                    ( False, Cmd.none )
    in
    ( { context = context
      , loginInfo = LoginInfo "" ""
      , cred = NotAsked
      , routeBackTo = maybeRoute
      , showBlank = show
      }
    , cmd
    )


type alias LoginInfo =
    { username : String
    , password : String
    }



-- UPDATE


type Msg
    = EnteredLoginInfo LoginInfo
    | GotCred (WebData Cred)
    | PressedKey Key
    | ClickedLogOut


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EnteredLoginInfo login ->
            ( { model | loginInfo = login }, Cmd.none )

        GotCred result ->
            let
                currentContext =
                    model.context
            in
            case result of
                Success cred ->
                    ( { model
                        | cred = result
                        , context = { currentContext | cred = Just cred }
                        , showBlank = False
                      }
                    , Cmd.batch
                        [ model.routeBackTo
                            |> Maybe.withDefault Route.Books
                            |> Route.replaceUrl model.context.key
                        , Api.storeCreds cred
                        ]
                    )

                _ ->
                    ( { model
                        | cred = result
                        , showBlank = False
                      }
                    , Cmd.none
                    )

        PressedKey key ->
            case ( key, model.loginInfo /= LoginInfo "" "" ) of
                -- ( Enter, True ) ->
                --     ( model, slateLogin model.loginInfo )
                _ ->
                    ( model, Cmd.none )

        ClickedLogOut ->
            ( model, Cmd.none )



-- VIEW


view : Model -> { title : String, body : Element Msg }
view model =
    { title = "Sign in"
    , body =
        El.column [ El.width (El.px (model.context |> .windowWidth)) ]
            [ Common.viewHeader model.context ClickedLogOut
            , if model.showBlank then
                El.none

              else
                El.column [ El.spacing 25, El.padding 30 ]
                    [ El.el [ Font.bold, Font.size 20 ] (El.text "Sign in")
                    , viewCandidateLogin model.loginInfo
                    , Common.viewErrors model.cred
                    ]
            ]
    }


viewCandidateLogin : LoginInfo -> Element Msg
viewCandidateLogin ({ username, password } as login) =
    El.column [ El.spacing 15 ]
        [ El.text "Please enter the email and password you used for your application"
        , Input.username [ El.width (El.px 200) ]
            { onChange =
                \s -> EnteredLoginInfo (LoginInfo s password)
            , text = username
            , placeholder = Just (Input.placeholder [] (El.text "OIST Admissions Email"))
            , label = Input.labelHidden "OIST Admissions Email"
            }
        , Input.currentPassword [ El.width (El.px 200) ]
            { onChange =
                \s -> EnteredLoginInfo (LoginInfo username s)
            , text = password
            , placeholder = Just (Input.placeholder [] (El.text "OIST Admissions Password"))
            , label = Input.labelHidden "OIST Admissions Password"
            , show = False
            }
        , El.link []
            { url =
                Url.Builder.crossOrigin "https://apply.oist.jp"
                    [ "account", "reset" ]
                    -- TODO return url
                    []
            , label =
                El.text "Forgot your password?"
                    |> El.el [ Font.underline, Font.color Style.oistRed ]
            }
        , Input.button
            [ Background.color Style.oistRed
            , El.spacing 5
            , El.paddingXY 40 5
            , Font.color Style.white
            ]
            { onPress =
                Cred (User "Jeremie") "token_blabla"
                    |> Success
                    |> GotCred
                    |> Just
            , label = El.text "Log in"
            }
        ]



-- SUBSCRIPTIONS


type Key
    = Enter
    | Other


keyDecoder : Decoder Key
keyDecoder =
    Decode.map toKey (Decode.field "key" Decode.string)


toKey : String -> Key
toKey string =
    case string of
        "Enter" ->
            Enter

        _ ->
            Other


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Browser.Events.onKeyPress (Decode.map PressedKey keyDecoder)
        ]



--API
-- slateLogin : LoginInfo -> Cmd Msg
-- slateLogin { username, password } =
--     Api.noCredGet (Endpoint.slateLogIn username password)
--         GotCred
--         Api.credDecoder
