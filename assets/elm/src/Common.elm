module Common exposing (Context, height, showMonth, showWeekday, viewErrors, viewFeedback, viewHeader, width)

import Api exposing (Cred)
import Browser.Navigation exposing (Key)
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Lazy as Lazy
import Http exposing (Error(..))
import Json.Decode as Decode exposing (Decoder)
import RemoteData exposing (RemoteData(..), WebData)
import Style
import Time exposing (Month(..), Weekday(..), Zone)


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
viewHeaderHelper { cred, windowWidth } logout =
    El.row
        [ El.height (El.px 100)
        , El.width El.fill
        , El.paddingXY 100 0
        , Background.color Style.grey
        ]
        [ El.link []
            { url = "/"
            , label = El.none

            -- El.image [ El.alignLeft, El.height (El.px 50) ]
            --     { src =
            --         -- if windowWidth >= 820 then
            --         -- "/images/oist-header-en.png"
            --         -- else
            --         "/images/oist-header-en-mobile.png"
            --     , description = "OIST Logo"
            --     }
            }
        , El.paragraph [ El.centerY ]
            [ El.text "Yakusu"
                |> El.el [ Font.size 36, Font.bold ]
            , El.text " - the OIST Tedako childrens book translation interface"
                |> El.el [ Font.size 24 ]
            ]
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


viewFeedback : WebData String -> Element msg
viewFeedback feedback =
    case feedback of
        Success text ->
            El.text text
                |> El.el [ El.centerX ]
                |> El.el
                    [ El.width (El.px 400)
                    , Border.solid
                    , Border.color Style.oistRed
                    , Border.width 1
                    , El.centerX
                    , El.padding 12
                    ]

        Failure err ->
            El.paragraph [] [ El.text (showError err) ]
                |> El.el [ El.centerX ]
                |> El.el
                    [ El.width (El.px 400)
                    , Border.solid
                    , Border.color Style.oistRed
                    , Border.width 1
                    , El.centerX
                    , El.padding 12
                    ]

        _ ->
            El.el [ El.height (El.px 40) ] El.none


viewErrors : WebData a -> Element msg
viewErrors feedback =
    case feedback of
        Failure err ->
            El.text (showError err)
                |> El.el [ El.centerX ]
                |> El.el
                    [ El.width (El.px 400)
                    , Border.solid
                    , Border.color Style.oistRed
                    , Border.width 1
                    , El.centerX
                    , El.padding 12
                    ]

        _ ->
            El.el [ El.height (El.px 40) ] El.none



-- HELPER FUNCTIONS


showError : Error -> String
showError error =
    case error of
        BadUrl url ->
            "The URL " ++ url ++ " was invalid"

        Timeout ->
            "Unable to reach the server, try again later"

        NetworkError ->
            "Unable to reach the server, check your network connection"

        BadStatus 500 ->
            "The server had a problem, try again later"

        BadStatus 400 ->
            "Verify your information and try again"

        BadStatus 401 ->
            "You are not authorized to access this resource"

        BadStatus i ->
            "Bas status: error " ++ String.fromInt i

        BadBody errorMessage ->
            errorMessage


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
