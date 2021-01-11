module Page.AddBook exposing (Model, Msg, init, update, view)

import Common exposing (Context, height, width)
import Element as El exposing (Attribute, Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input exposing (OptionState(..))
import File exposing (File)
import File.Select as Select
import GraphQLBook.Query as Query
import Graphql.Http exposing (Error)
import Graphql.Operation exposing (RootQuery)
import Graphql.SelectionSet exposing (SelectionSet)
import Html.Attributes exposing (lang)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import RemoteData exposing (RemoteData(..))
import Route
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
    , language : Language
    , category : Maybe Category
    , images : List File
    , dropdown : Dropdown
    }


emptyBook : Form
emptyBook =
    { title = ""
    , author = ""
    , language = Japanese
    , images = []
    , category = Nothing
    , dropdown = Closed
    }


type Dropdown
    = Closed
    | Open (Maybe Category)


type Language
    = Japanese
    | English
    | Other String



-- UPDATE


type Msg
    = InputTitle String
    | InputAuthor String
    | InputLanguage Language
    | ClickedSave Form
    | Pick
    | DragEnter
    | DragLeave
    | GotFiles File (List File)
    | GotPreviews (List ( String, String ))
    | GotImages (Result Http.Error ()) --(List String))
    | GotCategories (RemoteData (Error (List Category)) (List Category))
      -- | ClickedSelectCategory
      -- | HoverededCategory Category
    | ClickedCategory Category Bool


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
            -- TODO Full check
            case book.category of
                Just { id } ->
                    ( model, postBook book id )

                Nothing ->
                    ( model, Cmd.none )

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
            let
                sortedFiles =
                    List.sortBy File.name (file :: files)
            in
            ( { model | hover = False, book = { modelBook | images = sortedFiles } }
            , sortedFiles
                |> List.map File.toUrl
                |> Task.sequence
                |> Task.map (List.map2 Tuple.pair (List.map File.name sortedFiles))
                |> Task.perform GotPreviews
            )

        GotPreviews urls ->
            ( { model | previews = List.map Tuple.second (List.sort urls) }
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

        -- ClickedSelectCategory ->
        --     ( { model
        --         | book =
        --             { modelBook
        --                 | dropdown =
        --                     case modelBook.dropdown of
        --                         Closed ->
        --                             Open Nothing
        --                         _ ->
        --                             Closed
        --             }
        --       }
        --     , Cmd.none
        --     )
        -- HoverededCategory category ->
        --     ( { model | book = { modelBook | dropdown = Open (Just category) } }, Cmd.none )
        ClickedCategory category _ ->
            ( { model | book = { modelBook | dropdown = Closed, category = Just category } }, Cmd.none )



-- _VIEW


iconPlaceholder : Element msg
iconPlaceholder =
    El.el [ width 25, height 25, Background.color Style.nightBlue ] El.none
        |> El.el [ El.padding 5 ]


view : Model -> { title : String, body : Element Msg }
view model =
    { title = "Add an Original Book"
    , body =
        case model.categories of
            Success categories ->
                El.column
                    [ El.spacing 25
                    , El.paddingXY 20 50
                    , width 1000
                    , El.centerX
                    ]
                    [ Route.link Route.Books
                        [ Font.color Style.grey
                        , Border.color Style.grey
                        , Border.width 2
                        ]
                        (El.row [ El.paddingXY 10 5 ]
                            [ iconPlaceholder
                            , El.text "Back to Mainpage"
                            ]
                        )
                    , viewForm model.book model.previews categories
                    ]

            _ ->
                El.text "There was a problem retrieving data."
    }


viewForm : Form -> List String -> List Category -> Element Msg
viewForm ({ title, author, language, category, dropdown } as book) previews categories =
    El.column [ El.spacing 10, El.width El.fill ]
        [ El.text "To add a new book, please fill the following information and upload photos of the pages"
            |> El.el [ Background.color Style.grey, El.width El.fill, El.padding 10 ]
        , viewLanguageChoice language
        , viewTextInput title "Title" InputTitle
        , viewTextInput author "Author(s)" InputAuthor
        , viewCategories category categories
        , El.row [ El.width El.fill, El.spaceEvenly ]
            [ viewPageDownload previews
            , Input.button
                [ Font.color Style.nightBlue
                , Border.color Style.nightBlue
                , Border.width 2
                , El.alignBottom
                ]
                { onPress =
                    ClickedSave book
                        |> Just
                , label =
                    El.row [ El.paddingXY 10 5 ]
                        [ El.text "Add Book"
                        , iconPlaceholder
                        ]
                }
            ]
        ]


viewTextInput : String -> String -> (String -> Msg) -> Element Msg
viewTextInput text label message =
    Input.text [ Border.color Style.nightBlue, Border.rounded 0, Border.width 2, El.spacing 0, width 400 ]
        { onChange = message
        , text = text
        , placeholder = Nothing
        , label =
            Input.labelLeft [ El.height El.fill, Background.color Style.nightBlue ]
                (El.text label
                    |> El.el
                        [ El.centerY
                        , width 100
                        , El.padding 10
                        ]
                )
        }


viewLanguageChoice : Language -> Element Msg
viewLanguageChoice language =
    Input.radioRow [ El.spacing 30 ]
        { onChange = InputLanguage
        , label =
            Input.labelLeft [ El.paddingEach { top = 0, bottom = 0, left = 0, right = 30 } ]
                (El.text "Original Language"
                    |> El.el
                        [ Background.color Style.nightBlue
                        , El.padding 10
                        ]
                )
        , selected = Just language
        , options =
            [ Input.option Japanese (El.text "Japanese")
            , Input.option English (El.text "English")
            , Input.option (Other "?") (El.text "Other...")
            ]
        }


viewCategories : Maybe Category -> List Category -> Element Msg
viewCategories category categories =
    let
        viewCategory ({ name } as cat) =
            Input.checkbox [ width 150, height 25 ]
                { onChange = ClickedCategory cat
                , checked = Just cat == category
                , icon =
                    \checked ->
                        El.text name
                            |> El.el [ El.centerX, El.centerY, Font.size 18 ]
                            |> El.el
                                [ width 150
                                , height 25
                                , if checked then
                                    Background.color Style.nightBlue

                                  else
                                    Background.color Style.grey
                                ]
                , label = Input.labelHidden name
                }
    in
    El.column [ El.spacing 20 ]
        [ El.row [ Background.color Style.grey, width 250, height 45, Font.size 20 ]
            [ iconPlaceholder
            , El.text "Select Topic"
            ]
        , categories
            |> List.map viewCategory
            |> El.wrappedRow [ El.paddingXY 40 0, El.spacing 10 ]
        ]


viewPageDownload : List String -> Element Msg
viewPageDownload previews =
    El.column [ El.spacing 20 ]
        [ El.row [ Background.color Style.grey, width 250, height 45, Font.size 20 ]
            [ iconPlaceholder
            , El.text "Add Pages"
            ]
        , El.column
            [ width 700
            , El.height (El.minimum 200 El.shrink)
            , Border.color Style.nightBlue
            , Border.width 2
            , hijackOn "dragenter" (Decode.succeed DragEnter)
            , hijackOn "dragover" (Decode.succeed DragEnter)
            , hijackOn "dragleave" (Decode.succeed DragLeave)
            , hijackOn "drop" dropDecoder
            ]
            [ Input.button [ El.centerX, El.centerY, El.padding 15 ]
                { onPress = Just Pick
                , label =
                    El.text "Upload or Drag Images..."
                        |> El.el [ Background.color Style.grey, El.padding 5 ]
                }
            , List.map viewPreview previews
                |> El.wrappedRow [ El.spacingXY 10 30, El.centerX, El.paddingXY 38 10 ]
            ]
            |> El.el [ El.paddingEach { left = 60, right = 0, top = 0, bottom = 0 } ]
        ]


viewPreview : String -> Element msg
viewPreview url =
    El.el
        [ width 80
        , height 80
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



-- viewCategoryDropdown : Dropdown -> Maybe Category -> List Category -> Element Msg
-- viewCategoryDropdown dropdown maybeCategory categories =
--     El.row [ El.width El.fill ]
--         [ El.text "Category "
--         , maybeCategory
--             |> Maybe.map .name
--             |> Maybe.withDefault "Please select a category"
--             |> El.text
--             |> El.el
--                 ([ Border.color Style.black
--                  , Border.width 1
--                  , El.width El.fill
--                  , El.padding 5
--                  ]
--                     ++ (case dropdown of
--                             Closed ->
--                                 [ Events.onClick ClickedSelectCategory ]
--                             Open hoveredCategory ->
--                                 [ categories
--                                     |> List.sortBy .name
--                                     |> List.map
--                                         (\({ name } as category) ->
--                                             El.text name
--                                                 |> El.el
--                                                     ([ El.width El.fill
--                                                      , El.padding 2
--                                                      , Events.onMouseEnter (HoverededCategory category)
--                                                      , Events.onClick (ClickedCategory category)
--                                                      ]
--                                                         ++ (if Just category == hoveredCategory then
--                                                                 [ Background.color Style.black, Font.color Style.white ]
--                                                             else
--                                                                 [ Background.color Style.white ]
--                                                            )
--                                                     )
--                                         )
--                                     |> El.column [ El.width El.fill, Border.width 1 ]
--                                     |> El.below
--                                 ]
--                        )
--                 )
--         ]
-- API


encodeLanguage : Language -> Value
encodeLanguage language =
    case language of
        English ->
            Encode.string "en_US"

        Japanese ->
            Encode.string "ja"

        Other lan ->
            Encode.string lan


encodeBook : Form -> String -> Value
encodeBook { title, author, language } category_id =
    Encode.object
        [ ( "title", Encode.string title )
        , ( "author", Encode.string author )
        , ( "language", encodeLanguage language )
        , ( "category_id", Encode.string category_id )
        ]


postBook : Form -> String -> Cmd Msg
postBook ({ images } as book) category_id =
    Http.post
        { url = "api/rest/books"
        , body =
            Http.stringPart "book" (Encode.encode 0 (encodeBook book category_id))
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
