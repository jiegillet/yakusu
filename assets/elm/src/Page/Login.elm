module Page.Login exposing (..)

import Api exposing (Cred(..), User)
import Browser.Events
import Common exposing (Context)
import Element as El exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Json.Decode as Decode exposing (Decoder)
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
                --     ( model, apiLogin model.loginInfo )
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
            [ if model.showBlank then
                El.none

              else
                El.column [ El.spacing 25, El.padding 30 ]
                    [ El.el [ Font.bold, Font.size 20 ] (El.text "Sign in")
                    , viewCandidateLogin model.loginInfo

                    -- , Common.viewErrors model.cred
                    ]
            ]
    }


viewCandidateLogin : LoginInfo -> Element Msg
viewCandidateLogin { username, password } =
    El.column [ El.spacing 15 ]
        [ El.text "Authentification has not been implemented yet"
        , Input.username [ El.width (El.px 200) ]
            { onChange =
                \s -> EnteredLoginInfo (LoginInfo s password)
            , text = username
            , placeholder = Just (Input.placeholder [] (El.text "Click Log in"))
            , label = Input.labelHidden "Email"
            }
        , Input.currentPassword [ El.width (El.px 200) ]
            { onChange =
                \s -> EnteredLoginInfo (LoginInfo username s)
            , text = password
            , placeholder = Just (Input.placeholder [] (El.text "Click Log in"))
            , label = Input.labelHidden "Password"
            , show = False
            }
        , El.link []
            { url =
                Url.Builder.crossOrigin "https://google.com"
                    []
                    []
            , label =
                El.text "Forgot your password?"
                    |> El.el [ Font.underline, Font.color Style.lightCyan ]
            }
        , Input.button
            [ Background.color Style.lightCyan
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
subscriptions _ =
    Sub.batch
        [ Browser.Events.onKeyPress (Decode.map PressedKey keyDecoder)
        ]



--API
-- apiLogin : LoginInfo -> Cmd Msg
-- apiLogin { username, password } =
--     Api.noCredGet (Endpoint.apiLogIn username password)
--         GotCred
--         Api.credDecoder
