module Page.Home exposing (view)

import Element as El exposing (Element)
import Element.Font as Font


view : { title : String, body : El.Element msg }
view =
    { title = "Welcome to the CDC Book Translation App"
    , body = viewHome
    }


viewHome : Element msg
viewHome =
    El.column
        [ El.spacing 20, El.padding 20 ]
        [ viewExplanation
        ]


viewExplanation : Element msg
viewExplanation =
    El.text "hello"
