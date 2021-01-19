module Page.AddBook exposing (Model, Msg, init, subscriptions, update, view)

import Browser.Dom as Dom
import Browser.Events
import Common exposing (Context, height, width)
import DnDList
import Element as El exposing (Attribute, Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input exposing (OptionState(..), search)
import File exposing (File)
import File.Select as Select
import GraphQLBook.Query as Query
import Graphql.Http exposing (Error)
import Graphql.Operation exposing (RootQuery)
import Graphql.SelectionSet exposing (SelectionSet)
import Html.Attributes as Attributes
import Html.Events
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import RemoteData exposing (RemoteData(..))
import Route
import Style
import Task
import Types exposing (Category, Language)



-- TYPES


type alias Model =
    { context : Context
    , book : Form
    , hover : Bool
    , previews : List Preview
    , categories : RemoteData (Error (List Category)) (List Category)
    , languages : RemoteData (Error (List Language)) (List Language)
    , dropdown : Dropdown
    , dnd : DnDList.Model
    }


init : Context -> ( Model, Cmd Msg )
init context =
    ( { context = context
      , book = emptyBook
      , hover = False
      , previews = []
      , categories = Loading
      , languages = Loading
      , dropdown = Closed
      , dnd = system.model
      }
    , Cmd.batch [ getCategories, getlanguages ]
    )


type alias Form =
    { title : String
    , author : String
    , language : SelectLanguage
    , category : Maybe Category
    , images : List File
    }


emptyBook : Form
emptyBook =
    { title = ""
    , author = ""
    , language = Japanese
    , images = []
    , category = Nothing
    }


type Dropdown
    = Closed
    | Set Language
    | Open DropDownInfo


type alias DropDownInfo =
    { text : String
    , selectedLanguage : Maybe Language
    , hoveredLanguage : Maybe Language
    }


emptyDropdownInfo : DropDownInfo
emptyDropdownInfo =
    DropDownInfo "" Nothing Nothing


type SelectLanguage
    = Japanese
    | English
    | Other


type alias Preview =
    { file : File
    , url : String
    }



-- UPDATE


type Msg
    = InputTitle String
    | InputAuthor String
    | InputLanguage SelectLanguage
    | SelectLanguage SelectLanguage
    | ClickedSave Form
    | Pick
    | DragEnter
    | DragLeave
    | GotFiles File (List File)
    | GotPreviews (List Preview)
    | GotImages (Result Http.Error ()) --(List String))
    | GotCategories (RemoteData (Error (List Category)) (List Category))
    | ClickedCategory Category Bool
    | GotLanguages (RemoteData (Error (List Language)) (List Language))
      -- Dropdown
    | EnteredSearchText String
    | ClickedwhileOpenDropDown
    | DropdownInfoChanged DropDownInfo
      -- Drag and Drop
    | DnDMsg DnDList.Msg


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
            case language of
                Other ->
                    ( model
                    , Task.perform (always (SelectLanguage Other)) (Task.succeed ())
                    )

                _ ->
                    ( model
                      -- This is for the input-in-radio bug workaround https://github.com/mdgriffith/elm-ui/issues/250
                    , Task.attempt (always (SelectLanguage language)) (Dom.focus "attr-Title")
                    )

        SelectLanguage language ->
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
                |> Task.map (List.map2 Preview sortedFiles)
                |> Task.perform GotPreviews
            )

        GotPreviews previews ->
            ( { model | previews = previews }
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

        ClickedCategory category _ ->
            ( { model | book = { modelBook | category = Just category } }, Cmd.none )

        GotLanguages result ->
            ( { model | languages = result }, Cmd.none )

        -- DropDown
        EnteredSearchText search ->
            case model.dropdown of
                Closed ->
                    ( { model | dropdown = Open { emptyDropdownInfo | text = search } }, Cmd.none )

                Set lan ->
                    ( { model
                        | dropdown =
                            Open
                                { emptyDropdownInfo
                                    | text = String.right 1 search
                                    , selectedLanguage = Just lan
                                }
                      }
                    , Cmd.none
                    )

                Open info ->
                    ( { model | dropdown = Open { info | text = search } }, Cmd.none )

        ClickedwhileOpenDropDown ->
            case model.dropdown of
                Open { selectedLanguage } ->
                    case selectedLanguage of
                        Nothing ->
                            ( { model | dropdown = Closed }, Cmd.none )

                        Just lan ->
                            ( { model | dropdown = Set lan }, Cmd.none )

                other ->
                    ( { model | dropdown = other }, Cmd.none )

        DropdownInfoChanged dropdownInfo ->
            case model.dropdown of
                Open _ ->
                    ( { model | dropdown = Open dropdownInfo }, Cmd.none )

                other ->
                    ( { model | dropdown = other }, Cmd.none )

        DnDMsg dndMsg ->
            let
                ( dnd, previews ) =
                    system.update dndMsg model.dnd model.previews
            in
            ( { model | dnd = dnd, previews = previews }
            , system.commands dnd
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        dropdown =
            case model.dropdown of
                Open _ ->
                    [ Browser.Events.onClick (Decode.succeed ClickedwhileOpenDropDown) ]

                _ ->
                    []
    in
    Sub.batch (system.subscriptions model.dnd :: dropdown)



-- VIEW


iconPlaceholder : Element msg
iconPlaceholder =
    El.el [ width 25, height 25, Background.color Style.nightBlue ] El.none
        |> El.el [ El.padding 5 ]


view : Model -> { title : String, body : Element Msg }
view model =
    { title = "Add an Original Book"
    , body =
        case ( model.categories, model.languages ) of
            ( Success categories, Success languages ) ->
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
                    , viewForm model.book model.dropdown model.dnd model.previews categories languages
                    ]

            _ ->
                El.text "There was a problem retrieving data."
    }


viewForm : Form -> Dropdown -> DnDList.Model -> List Preview -> List Category -> List Language -> Element Msg
viewForm ({ title, author, language, category } as book) dropdown dnd previews categories languages =
    El.column [ El.spacing 10, El.width El.fill ]
        [ El.text "To add a new book, please fill the following information and upload photos of the pages"
            |> El.el [ Background.color Style.grey, El.width El.fill, El.padding 10 ]
        , viewLanguageChoice dropdown language languages
        , viewTextInput title "Title" InputTitle
        , viewTextInput author "Author(s)" InputAuthor
        , viewCategories category categories
        , El.row [ El.width El.fill, El.spaceEvenly ]
            [ viewPageDownload dnd previews
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
                    El.row
                        [ El.paddingXY 10 5 ]
                        [ El.text "Add Book"
                        , iconPlaceholder
                        ]
                }
            ]
        ]


viewTextInput : String -> String -> (String -> Msg) -> Element Msg
viewTextInput text label message =
    Input.text
        [ Border.color Style.nightBlue
        , Border.rounded 0
        , Border.width 2
        , El.spacing 0
        , width 400

        -- This is for the input-in-radio bug workaround
        , El.htmlAttribute (Attributes.id ("attr-" ++ label))
        ]
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


viewLanguageChoice : Dropdown -> SelectLanguage -> List Language -> Element Msg
viewLanguageChoice dropdown language languages =
    Input.radioRow [ El.spacing 30 ]
        { onChange = InputLanguage
        , label =
            Input.labelLeft [ El.paddingEach { top = 0, bottom = 0, left = 0, right = 30 } ]
                (El.text "Original Language"
                    |> El.el [ El.padding 10, El.centerY ]
                    |> El.el
                        [ Background.color Style.nightBlue
                        , height 42
                        ]
                )
        , selected = Just language
        , options =
            [ Input.option Japanese (El.text "Japanese" |> El.el [ El.centerY ] |> El.el [ height 42 ])
            , Input.option English (El.text "English" |> El.el [ El.centerY ] |> El.el [ height 42 ])
            , Input.option Other (viewLanguageDropdown dropdown languages)
            ]
        }


maybeToList : Maybe a -> List a
maybeToList maybe =
    case maybe of
        Nothing ->
            []

        Just a ->
            [ a ]


viewLanguageDropdown : Dropdown -> List Language -> Element Msg
viewLanguageDropdown dropdown languages =
    let
        languageList text selectedLanguage =
            maybeToList selectedLanguage
                ++ (languages
                        |> List.filter (\{ language } -> String.contains (String.toLower text) (String.toLower language))
                        |> List.sortBy .language
                        |> List.take 7
                   )

        viewDropdownLanguage info language =
            El.text language.language
                |> El.el
                    ([ El.width El.fill
                     , El.padding 2
                     , Events.onMouseEnter (DropdownInfoChanged { info | hoveredLanguage = Just language })
                     , Events.onClick (DropdownInfoChanged { info | selectedLanguage = Just language })
                     ]
                        ++ (if Just language == info.hoveredLanguage then
                                [ Background.color Style.nightBlue, Font.color Style.white ]

                            else
                                [ Background.color Style.white ]
                           )
                    )
    in
    Input.search
        ([ width 230
         , Border.width 2
         , Border.color Style.nightBlue
         ]
            ++ (case dropdown of
                    Open ({ text, selectedLanguage } as info) ->
                        case languageList text selectedLanguage of
                            [] ->
                                []

                            list ->
                                [ list
                                    |> List.map (viewDropdownLanguage info)
                                    |> El.column
                                        [ width 230
                                        , Border.width 2
                                        , Border.color Style.nightBlue
                                        ]
                                    |> El.below
                                ]

                    _ ->
                        []
               )
        )
        { text =
            case dropdown of
                Closed ->
                    ""

                Set { language } ->
                    language

                Open { text } ->
                    text
        , onChange = EnteredSearchText
        , placeholder = Just (Input.placeholder [] (El.text "Other..."))
        , label = Input.labelHidden "Search language"
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


viewPageDownload : DnDList.Model -> List Preview -> Element Msg
viewPageDownload dnd previews =
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
            , List.indexedMap (viewPreview dnd) previews
                |> El.wrappedRow [ El.spacingXY 10 30, El.centerX, El.paddingXY 38 10 ]
            ]
            |> El.el [ El.paddingEach { left = 60, right = 0, top = 0, bottom = 0 } ]
        ]


viewPreview : DnDList.Model -> Int -> Preview -> Element Msg
viewPreview dnd index { url, file } =
    let
        itemId : String
        itemId =
            "id-" ++ File.name file
    in
    case system.info dnd of
        Just { dragIndex } ->
            if dragIndex /= index then
                El.el
                    (width 80
                        :: height 80
                        :: Background.image url
                        :: El.htmlAttribute (Attributes.id itemId)
                        :: List.map El.htmlAttribute (system.dropEvents index itemId)
                    )
                    El.none

            else
                El.el
                    [ width 80
                    , height 80
                    , Background.color Style.grey
                    , El.htmlAttribute (Attributes.id itemId)
                    ]
                    El.none

        Nothing ->
            El.el
                (width 80
                    :: height 80
                    :: Background.image url
                    :: El.htmlAttribute (Attributes.id itemId)
                    :: List.map El.htmlAttribute (system.dragEvents index itemId)
                )
                El.none



-- Drag and Drop


config : DnDList.Config Preview
config =
    { beforeUpdate = \_ _ list -> list
    , movement = DnDList.Free
    , listen = DnDList.OnDrag
    , operation = DnDList.Rotate
    }


system : DnDList.System Preview Msg
system =
    DnDList.create config DnDMsg



-- REST API


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


encodeLanguage : SelectLanguage -> Value
encodeLanguage language =
    case language of
        English ->
            Encode.string "en"

        Japanese ->
            Encode.string "ja"

        Other ->
            Encode.string "TODO"


encodeBook : Form -> String -> Value
encodeBook { title, author, language } category_id =
    Encode.object
        [ ( "title", Encode.string title )
        , ( "author", Encode.string author )
        , ( "language_id", encodeLanguage language )
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


languagesQuery : SelectionSet (List Language) RootQuery
languagesQuery =
    Query.languages Types.languageSelection


getlanguages : Cmd Msg
getlanguages =
    languagesQuery
        |> Graphql.Http.queryRequest "/api"
        |> Graphql.Http.send (RemoteData.fromResult >> GotLanguages)
