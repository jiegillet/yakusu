module Page.NotFound exposing (view)

import Common exposing (width)
import Element as El
import Element.Font as Font


view : { title : String, body : El.Element msg }
view =
    { title = "Page Not Found"
    , body =
        El.text "404 Page not Found"
            |> El.el
                [ Font.size 36
                , Font.family [ Font.typeface "clear_sans_mediumregular" ]
                , El.paddingXY 0 30
                , width 1000
                ]
    }
