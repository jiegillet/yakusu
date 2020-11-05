module Page.AddBook exposing (..)

import Browser
import Common exposing (Context)
import Debug
import Element as El exposing (Attribute, Element)
import Element.Background as Background
import Element.Border as Border
import Element.Input as Input
import File exposing (File)
import File.Select as Select
import Html.Events
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Task
import Types exposing (Book)



-- _TYPES


type alias Model =
    { context : Context
    , book : Form
    , hover : Bool
    , previews : List String
    }


type alias Form =
    { title : String
    , author : String
    , language : String
    , images : List File
    }


emptyBook : Form
emptyBook =
    { title = ""
    , author = ""
    , language = ""
    , images = []
    }


init : Context -> ( Model, Cmd msg )
init context =
    ( { context = context
      , book = emptyBook
      , hover = False
      , previews = []
      }
    , Cmd.none
    )



-- _UPDATE


type Msg
    = InputTitle String
    | InputAuthor String
    | InputLanguage String
    | ClickedSave Form
    | Pick
    | DragEnter
    | DragLeave
    | GotFiles File (List File)
    | GotPreviews (List String)
    | GotImages (Result Http.Error ()) --(List String))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        modelBook =
            model.book
    in
    case msg of
        InputTitle title ->
            ( { model | book = { modelBook | title = title } }, Cmd.none )

        InputAuthor author ->
            ( { model | book = { modelBook | author = author } }, Cmd.none )

        InputLanguage language ->
            ( { model | book = { modelBook | language = language } }, Cmd.none )

        ClickedSave book ->
            ( model, postBook book )

        Pick ->
            ( model
            , Select.files [ "image/*" ] GotFiles
            )

        DragEnter ->
            ( { model | hover = True }
            , Cmd.none
            )

        DragLeave ->
            ( { model | hover = False }
            , Cmd.none
            )

        GotFiles file files ->
            ( { model | hover = False, book = { modelBook | images = file :: files } }
            , Task.perform GotPreviews <|
                Task.sequence <|
                    List.map File.toUrl (file :: files)
            )

        GotPreviews urls ->
            ( { model | previews = urls }
            , Cmd.none
            )

        GotImages result ->
            case result of
                Ok images ->
                    ( model, Debug.log (Debug.toString images) Cmd.none )

                Err err ->
                    ( model, Debug.log "fail" Cmd.none )



-- _VIEW


view : Model -> { title : String, body : Element Msg }
view model =
    { title = "List of Books"
    , body =
        viewForm model.book model.previews
            |> El.el [ El.padding 30 ]
    }


gray : El.Color
gray =
    El.rgb255 200 200 200


viewForm : Form -> List String -> Element Msg
viewForm ({ title, author, language } as book) previews =
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
        , El.column
            [ El.width (El.px 400)
            , El.height El.shrink
            , Border.dashed
            , Border.color gray
            , Border.width 2
            , Border.rounded 10
            , hijackOn "dragenter" (Decode.succeed DragEnter)
            , hijackOn "dragover" (Decode.succeed DragEnter)
            , hijackOn "dragleave" (Decode.succeed DragLeave)
            , hijackOn "drop" dropDecoder
            ]
            [ Input.button [ El.centerX, El.centerY, El.padding 20 ]
                { onPress = Just Pick
                , label =
                    El.text "Upload or Drag Images..."
                        |> El.el [ Background.color gray, El.padding 5 ]
                }
            , List.map viewPreview previews
                |> El.wrappedRow [ El.width El.fill, El.spacing 3, El.centerX ]
                |> El.el [ El.padding 20, El.centerX, El.centerY ]
            ]
        , Input.button []
            { onPress =
                ClickedSave book
                    |> Just
            , label =
                El.text "Add Book"
                    |> El.el [ Background.color gray, El.padding 5 ]
            }
        ]


viewPreview : String -> Element msg
viewPreview url =
    El.el
        [ El.width (El.px 60)
        , El.height (El.px 60)
        , Background.image url
        ]
        El.none


dropDecoder : Decoder Msg
dropDecoder =
    Decode.at [ "dataTransfer", "files" ] (Decode.oneOrMore GotFiles File.decoder)


hijackOn : String -> Decoder msg -> Attribute msg
hijackOn event decoder =
    Html.Events.preventDefaultOn event (Decode.map hijack decoder)
        |> El.htmlAttribute


hijack : msg -> ( msg, Bool )
hijack msg =
    ( msg, True )



-- _API


encodeBook : Form -> Value
encodeBook { title, author, language } =
    Encode.object
        [ ( "title", Encode.string title )
        , ( "author", Encode.string author )
        , ( "language", Encode.string language )
        ]


postBook : Form -> Cmd Msg
postBook ({ images } as book) =
    Http.post
        { url = "api/rest/books"
        , body =
            Http.stringPart "book" (Encode.encode 0 (encodeBook book))
                :: List.map (Http.filePart "pages[]") images
                -- :: List.indexedMap (\i -> Http.filePart ("pages[" ++ String.fromInt i ++ "]")) images
                |> Http.multipartBody
        , expect = Http.expectWhatever GotImages -- Http.expectJson GotImages (Decode.list Decode.string)
        }
