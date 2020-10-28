module Page.Blank exposing (view)

import Element


view : { title : String, body : Element.Element msg }
view =
    { title = ""
    , body =
        Element.none
    }
