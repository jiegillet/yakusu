module Page.AddBook exposing (Model, init, update, view)

import Common exposing (Context)
import Element as El exposing (Attribute, Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import File exposing (File)
import File.Select as Select
import GraphQLBook.Query as Query
import Graphql.Http exposing (Error)
import Graphql.Operation exposing (RootQuery)
import Graphql.SelectionSet exposing (SelectionSet)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import RemoteData exposing (RemoteData(..))
import Style
import Task
import Types exposing (Category)



-- TYPES


type alias Model =
    { context : Context
    , book : Form
    , hover : Bool
    , previews : List String
    , categories : RemoteData (Error (List Category)) (List Category)
    }


init : Context -> ( Model, Cmd Msg )
init context =
    ( { context = context
      , book = emptyBook
      , hover = False
      , previews = []
      , categories = Loading
      }
    , getCategories
    )


type alias Form =
    { title : String
    , author : String
    , language : String
    , category : Maybe Category
    , images : List File
    , dropdown : Dropdown
    }


emptyBook : Form
emptyBook =
    { title = ""
    , author = ""
    , language = ""
    , images = []
    , category = Nothing
    , dropdown = Closed
    }


type Dropdown
    = Closed
    | Open (Maybe Category)



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
    | GotCategories (RemoteData (Error (List Category)) (List Category))
    | ClickedSelectCategory
    | HoverededCategory Category
    | ClickedCategory Category


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
                Ok _ ->
                    ( model, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        GotCategories result ->
            ( { model | categories = result }, Cmd.none )

        ClickedSelectCategory ->
            ( { model
                | book =
                    { modelBook
                        | dropdown =
                            case modelBook.dropdown of
                                Closed ->
                                    Open Nothing

                                _ ->
                                    Closed
                    }
              }
            , Cmd.none
            )

        HoverededCategory category ->
            ( { model | book = { modelBook | dropdown = Open (Just category) } }, Cmd.none )

        ClickedCategory category ->
            ( { model | book = { modelBook | dropdown = Closed, category = Just category } }, Cmd.none )



-- _VIEW


view : Model -> { title : String, body : Element Msg }
view model =
    { title = "List of Books"
    , body =
        case model.categories of
            Success categories ->
                viewForm model.book model.previews categories
                    |> El.el [ El.padding 30 ]

            _ ->
                El.text "There was a problem retrieving data."
    }


gray : El.Color
gray =
    El.rgb255 200 200 200


viewForm : Form -> List String -> List Category -> Element Msg
viewForm ({ title, author, language, category, dropdown } as book) previews categories =
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
        , viewCategoryDropdown dropdown category categories
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


viewCategoryDropdown : Dropdown -> Maybe Category -> List Category -> Element Msg
viewCategoryDropdown dropdown maybeCategory categories =
    El.row [ El.width El.fill ]
        [ El.text "Category "
        , maybeCategory
            |> Maybe.map .name
            |> Maybe.withDefault "Please select a category"
            |> El.text
            |> El.el
                ([ Border.color Style.black
                 , Border.width 1
                 , El.width El.fill
                 , El.padding 5
                 ]
                    ++ (case dropdown of
                            Closed ->
                                [ Events.onClick ClickedSelectCategory ]

                            Open hoveredCategory ->
                                [ categories
                                    |> List.sortBy .name
                                    |> List.map
                                        (\({ name } as category) ->
                                            El.text name
                                                |> El.el
                                                    ([ El.width El.fill
                                                     , El.padding 2
                                                     , Events.onMouseEnter (HoverededCategory category)
                                                     , Events.onClick (ClickedCategory category)
                                                     ]
                                                        ++ (if Just category == hoveredCategory then
                                                                [ Background.color Style.black, Font.color Style.white ]

                                                            else
                                                                [ Background.color Style.white ]
                                                           )
                                                    )
                                        )
                                    |> El.column [ El.width El.fill, Border.width 1 ]
                                    |> El.below
                                ]
                       )
                )
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



-- REST API


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



-- GRAPHQL


categoriesQuery : SelectionSet (List Category) RootQuery
categoriesQuery =
    Query.categories Types.categorySelection


getCategories : Cmd Msg
getCategories =
    categoriesQuery
        |> Graphql.Http.queryRequest "/api"
        |> Graphql.Http.send (RemoteData.fromResult >> GotCategories)
