module Page.Books exposing (..)

import Common exposing (Context)
import Element as El exposing (Element)
import Element.Input as Input
import Types exposing (Book)



-- TYPES


type alias Model =
    { context : Context
    , books : List Book
    }


init : Context -> ( Model, Cmd msg )
init context =
    ( { context = context
      , books = []
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = Msg


update msg model =
    ( model, Cmd.none )



-- VIEW


view : Model -> { title : String, body : Element msg }
view model =
    { title = "List of Books"
    , body =
        viewBooks model.books
    }


viewBooks : List Book -> Element msg
viewBooks books =
    let
        viewBook { title } =
            El.text title
    in
    books
        |> List.map viewBook
        |> El.column []
