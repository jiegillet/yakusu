module Style exposing (..)

import Element as El exposing (Color, Element)
import Element.Background as Background
import Url.Builder



-- COLORS


white : Color
white =
    El.rgb255 255 255 255


black : Color
black =
    El.rgb255 0 0 0


grey : Color
grey =
    El.rgb255 235 235 235


lightCyan : Color
lightCyan =
    El.rgb255 92 164 178


lightRed : Color
lightRed =
    El.rgb255 225 98 107


oistRed : Color
oistRed =
    El.rgb255 200 0 25



-- ICONS


makeIcon : String -> String -> Element msg
makeIcon src description =
    El.image
        [ El.width (El.px 25), El.height (El.px 25) ]
        { src = Url.Builder.absolute [ "images", src ] []
        , description = description
        }
        |> El.el [ El.paddingXY 10 0 ]


listIcon : Element msg
listIcon =
    makeIcon "Table_C.svg" "list icon"


upArrow : Element msg
upArrow =
    El.image
        [ El.height (El.px 25), El.width (El.px 25) ]
        { src = Url.Builder.absolute [ "images", "ArrUp_C.svg" ] []
        , description = "up arrow icon"
        }


downArrow : Element msg
downArrow =
    El.image
        [ El.height (El.px 25), El.width (El.px 25) ]
        { src = Url.Builder.absolute [ "images", "ArrDown_C.svg" ] []
        , description = "down arrow icon"
        }


upDownArrow : Element msg
upDownArrow =
    El.image
        [ El.height (El.px 25), El.width (El.px 20) ]
        { src = Url.Builder.absolute [ "images", "ArrUpDown_C.svg" ] []
        , description = "up down arrow icon"
        }


rightArrow : Element msg
rightArrow =
    makeIcon "ArrRight_C.svg" "right arrow"


greyRightArrow : Element msg
greyRightArrow =
    makeIcon "ArrRight_G.svg" "Grey rlght arrow"


leftArrow : Element msg
leftArrow =
    makeIcon "ArrLeft_C.svg" "Cyan left arrow"


greyLeftArrow : Element msg
greyLeftArrow =
    makeIcon "ArrLeft_G.svg" "Grey left arrow"


bigLeftArrow : Element msg
bigLeftArrow =
    El.image
        [ El.height (El.px 70), El.width (El.px 50) ]
        { src = Url.Builder.absolute [ "images", "BigLeftArrow_C.svg" ] []
        , description = "Big left arrow"
        }


bigRightArrow : Element msg
bigRightArrow =
    El.image
        [ El.height (El.px 70), El.width (El.px 50) ]
        { src = Url.Builder.absolute [ "images", "BigRightArrow_C.svg" ] []
        , description = "Big right arrow"
        }


horizontalTag : Element msg
horizontalTag =
    makeIcon "TagHor_C.svg" "horizontal tag icon"


whiteHorizontalTag : Element msg
whiteHorizontalTag =
    makeIcon "TagHor_W.svg" "white horizontal tag icon"


verticalTag : Element msg
verticalTag =
    makeIcon "TagVer_C.svg" "vertical tag icon"


pencil : Element msg
pencil =
    makeIcon "Pencil_C.svg" "pencil icon"


smallPencil : Element msg
smallPencil =
    El.image
        [ El.width (El.px 25), El.height (El.px 25), El.centerX ]
        { src = Url.Builder.absolute [ "images", "Pencil_C.svg" ] []
        , description = "pencil icon"
        }
        |> El.el [ El.paddingXY 5 0, El.width (El.px 40) ]


whitePlus : Element msg
whitePlus =
    makeIcon "Plus_W.svg" "white plus icon"


plus : Element msg
plus =
    makeIcon "Plus_C.svg" "cyan plus icon"


addPage : Element msg
addPage =
    makeIcon "Pages_C.svg" "Add a page icon"


addPageWhite : Element msg
addPageWhite =
    makeIcon "Pages_W.svg" "White add a page icon"


radioFull : Element msg
radioFull =
    El.image
        [ El.width (El.px 25), El.height (El.px 25), El.centerY ]
        { src = Url.Builder.absolute [ "images", "RadioFull_C.svg" ] []
        , description = "Full radio button icon"
        }


radioFullRed : Element msg
radioFullRed =
    El.image
        [ El.width (El.px 25), El.height (El.px 25), El.centerY ]
        { src = Url.Builder.absolute [ "images", "RadioFull_R.svg" ] []
        , description = "Full, red radio button icon"
        }


radioEmpty : Element msg
radioEmpty =
    El.image
        [ El.width (El.px 25), El.height (El.px 25), El.centerY ]
        { src = Url.Builder.absolute [ "images", "RadioEmpty_C.svg" ] []
        , description = "Empty radio button icon"
        }


radioEmptyRed : Element msg
radioEmptyRed =
    El.image
        [ El.width (El.px 25), El.height (El.px 25), El.centerY ]
        { src = Url.Builder.absolute [ "images", "RadioEmpty_R.svg" ] []
        , description = "Empty, red radio button icon"
        }


download : Element msg
download =
    makeIcon "Download_C.svg" "Download icon"


languages : Element msg
languages =
    makeIcon "Lang_C.svg" "A and あ"


languageBox : Element msg
languageBox =
    El.image
        [ El.height (El.px 40), El.width (El.px 40) ]
        { src = Url.Builder.absolute [ "images", "Langbox_C.svg" ] []
        , description = "A and あ"
        }
        |> El.el [ El.padding 8 ]


draw : Element msg
draw =
    El.image
        [ El.height (El.px 40), El.width (El.px 40) ]
        { src = Url.Builder.absolute [ "images", "Draw_C.svg" ] []
        , description = "Finger drawing"
        }
        |> El.el [ El.padding 8 ]


book : Element msg
book =
    makeIcon "Book_C.svg" "Book"


attention : Element msg
attention =
    makeIcon "Attention_R.svg" "Attention sign"


information : Element msg
information =
    makeIcon "Info_C.svg" "Information sign"
