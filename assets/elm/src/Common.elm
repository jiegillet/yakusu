module Common exposing (Context, height, showError, showMonth, showWeekday, viewHeader, width)

import Api exposing (Cred)
import Browser.Navigation exposing (Key)
import Element as El exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Element.Lazy as Lazy
import Graphql.Http exposing (Error, HttpError(..), RawError(..))
import Json.Decode as Decode
import RemoteData exposing (RemoteData(..))
import Route
import Style
import Time exposing (Month(..), Weekday(..))
import Url.Builder


type alias Context =
    { cred : Maybe Cred
    , key : Key
    , windowWidth : Int
    }



--VIEW


width : Int -> El.Attribute msg
width =
    El.px >> El.width


height : Int -> El.Attribute msg
height =
    El.px >> El.height


viewHeader : Context -> msg -> Element msg
viewHeader =
    Lazy.lazy2 viewHeaderHelper


viewHeaderHelper : { a | cred : Maybe Cred, windowWidth : Int } -> msg -> Element msg
viewHeaderHelper { windowWidth } _ =
    El.row
        [ height 100
        , width windowWidth
        , Background.color Style.grey
        ]
        [ Route.link Route.Books
            [ width 1000, El.paddingXY 40 0, El.centerX ]
            (El.row []
                [ El.image [ height 32, El.moveUp 3.5 ]
                    { src = Url.Builder.absolute [ "images", "Yakusu.svg" ] []
                    , description = "Yakusu logo"
                    }
                , El.text " - the OIST Tedako Book Translation Interface" |> El.el [ Font.size 24, El.alignBottom ]
                ]
            )
        ]



-- ++ (case cred of
--         Nothing ->
--             []
--         Just c ->
--             [ El.text ("Welcome, " ++ Api.credName c)
--                 |> El.el [ El.alignRight ]
--             , Input.button
--                 [ El.padding 5
--                 , El.alignRight
--                 , Font.color Style.white
--                 , Border.solid
--                 , Border.color Style.white
--                 , Border.width 1
--                 ]
--                 { onPress = Just logout
--                 , label = El.text "Log out"
--                 }
--                 |> El.el [ El.centerY ]
--             ]
--    )
-- viewFeedback : WebData String -> Element msg
-- viewFeedback feedback =
--     case feedback of
--         Success text ->
--             El.text text
--                 |> El.el [ El.centerX ]
--                 |> El.el
--                     [ El.width (El.px 400)
--                     , Border.solid
--                     , Border.color Style.oistRed
--                     , Border.width 1
--                     , El.centerX
--                     , El.padding 12
--                     ]
--         Failure err ->
--             El.paragraph [] [ El.text (showError err) ]
--                 |> El.el [ El.centerX ]
--                 |> El.el
--                     [ El.width (El.px 400)
--                     , Border.solid
--                     , Border.color Style.oistRed
--                     , Border.width 1
--                     , El.centerX
--                     , El.padding 12
--                     ]
--         _ ->
--             El.el [ El.height (El.px 40) ] El.none
-- viewErrors : WebData a -> Element msg
-- viewErrors feedback =
--     case feedback of
--         Failure err ->
--             El.text (showError err)
--                 |> El.el [ El.centerX ]
--                 |> El.el
--                     [ El.width (El.px 400)
--                     , Border.solid
--                     , Border.color Style.oistRed
--                     , Border.width 1
--                     , El.centerX
--                     , El.padding 12
--                     ]
--         _ ->
--             El.el [ El.height (El.px 40) ] El.none


showError : Error a -> String
showError result =
    case result of
        HttpError (BadUrl url) ->
            "The URL " ++ url ++ " is invalid"

        HttpError Timeout ->
            "Unable to reach the server, try again later"

        HttpError NetworkError ->
            "Unable to reach the server, check your network connection"

        HttpError (BadStatus { statusCode, statusText } response) ->
            case statusCode of
                500 ->
                    "The server had a problem with this request"

                400 ->
                    "Verify your information and try again"

                401 ->
                    "You are not authorized to access this resource"

                _ ->
                    "Bad status " ++ String.fromInt statusCode ++ ": " ++ statusText ++ ". " ++ response

        HttpError (BadPayload err) ->
            "Unexpected data received: " ++ Decode.errorToString err

        GraphqlError _ _ ->
            "GraphQL error"


showWeekday : Weekday -> String
showWeekday weekday =
    case weekday of
        Mon ->
            "Mon"

        Tue ->
            "Tue"

        Wed ->
            "Wed"

        Thu ->
            "Thu"

        Fri ->
            "Fri"

        Sat ->
            "Sat"

        Sun ->
            "Sun"


showMonth : Month -> String
showMonth month =
    case month of
        Jan ->
            "January"

        Feb ->
            "February"

        Mar ->
            "March"

        Apr ->
            "April"

        May ->
            "May"

        Jun ->
            "June"

        Jul ->
            "July"

        Aug ->
            "August"

        Sep ->
            "September"

        Oct ->
            "October"

        Nov ->
            "November"

        Dec ->
            "December"
