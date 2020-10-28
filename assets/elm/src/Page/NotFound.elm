module Page.NotFound exposing (view)

import Element as El
import Element.Font as Font


view : { title : String, body : El.Element msg }
view =
    { title = "Page Not Found"
    , body =
        El.text "404 Page not Found"
            |> El.el [ Font.bold, Font.size 40 ]
    }
