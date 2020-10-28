port module Page.AddBook exposing (..)

import Common exposing (Context)
import Debug
import Element as El exposing (Element)
import Element.Background as Background
import Element.Input as Input
import Html.Attributes exposing (title)
import Json.Encode as Encode exposing (Value)



-- TYPES


type alias Model =
    { context : Context
    , book : Book
    }


init : Context -> ( Model, Cmd msg )
init context =
    ( { context = context
      , book = emptyBook
      }
    , Cmd.none
    )


type Book
    = Book
        { title : String
        , author : String
        , language : String
        , translates : Maybe Book
        , notes : String
        , translator : String
        }


emptyBook : Book
emptyBook =
    Book { title = "", author = "", language = "", translates = Nothing, notes = "", translator = "" }



-- UPDATE


type Msg
    = InputTitle String
    | InputAuthor String
    | InputLanguage String
    | ClickedSave Value


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        (Book modelBook) =
            model.book
    in
    case msg of
        InputTitle title ->
            ( { model | book = Book { modelBook | title = title } }, Cmd.none )

        InputAuthor author ->
            ( { model | book = Book { modelBook | author = author } }, Cmd.none )

        InputLanguage language ->
            ( { model | book = Book { modelBook | language = language } }, Cmd.none )

        ClickedSave value ->
            ( model, broadcastBook value )



-- VIEW


view : Model -> { title : String, body : Element Msg }
view model =
    { title = "List of Books"
    , body =
        viewForm model.book
    }


viewForm : Book -> Element Msg
viewForm ((Book { title, author, language }) as book) =
    let
        place text =
            text
                |> El.text
                |> Input.placeholder []
                |> Just
    in
    El.column [ El.spacing 10 ]
        [ Input.text []
            { onChange = InputTitle
            , text = title
            , placeholder = place "つまらない物語"
            , label = Input.labelAbove [] (El.text "Original Title")
            }
        , Input.text []
            { onChange = InputAuthor
            , text = author
            , placeholder = place "田中太郎"
            , label = Input.labelAbove [] (El.text "Author(s)")
            }
        , Input.text []
            { onChange = InputLanguage
            , text = language
            , placeholder = place "日本語"
            , label = Input.labelAbove [] (El.text "Original Language")
            }
        , Input.button []
            { onPress =
                encodeBook book
                    |> ClickedSave
                    |> Just
            , label =
                El.text "Add Book"
                    |> El.el [ Background.color (El.rgb255 200 200 200), El.padding 5 ]
            }
        ]



-- PORTS


port broadcastBook : Encode.Value -> Cmd msg


encodeBook : Book -> Value
encodeBook (Book { title, author, language }) =
    Encode.object
        [ ( "title", Encode.string title )
        , ( "author", Encode.string author )
        , ( "language", Encode.string language )
        ]
