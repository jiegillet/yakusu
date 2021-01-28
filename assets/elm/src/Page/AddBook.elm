module Page.AddBook exposing (Model, Msg, init, subscriptions, update, view)

import Animation
import Base64
import Browser.Dom as Dom
import Browser.Events
import Bytes exposing (Bytes, Endianness(..))
import Bytes.Decode
import Bytes.Encode
import Common exposing (Context, height, width)
import DnDList
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
import Html.Attributes as Attributes
import Html.Events
import Http exposing (Response(..))
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import RemoteData exposing (RemoteData(..), WebData)
import Route
import Style
import Svg
import Svg.Attributes as S
import Task
import Types exposing (Category, Language)



-- TYPES


type alias Model =
    { context : Context
    , categories : RemoteData (Error (List Category)) (List Category)
    , languages : RemoteData (Error (List Language)) (List Language)
    , title : String
    , author : String
    , category : Maybe Category
    , language : SelectLanguage
    , languageDropdown : LanguageDropdown
    , hoverUploadBox : Bool
    , previews : List Image
    , dnd : DnDList.Model
    , crossAnimation : Animation.State
    }


init : Context -> ( Model, Cmd Msg )
init context =
    ( { context = context
      , hoverUploadBox = False
      , previews = []
      , categories = Loading
      , languages = Loading
      , languageDropdown = Closed
      , dnd = system.model
      , title = ""
      , author = ""
      , language = Japanese
      , category = Nothing
      , crossAnimation =
            Animation.style
                [ Animation.rotate (Animation.deg 0)
                , Animation.transformOrigin (Animation.percent 50) (Animation.percent 50) (Animation.percent 0)
                ]
      }
    , Cmd.batch [ getCategories, getlanguages ]
    )


type LanguageDropdown
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


type alias Image =
    { file : Bytes
    , preview : String
    }


emptyImage : Image
emptyImage =
    Image (Bytes.Encode.sequence [] |> Bytes.Encode.encode) ""


config : DnDList.Config Image
config =
    { beforeUpdate = \_ _ list -> list
    , movement = DnDList.Free
    , listen = DnDList.OnDrag
    , operation = DnDList.Rotate
    }


system : DnDList.System Image Msg
system =
    DnDList.create config DnDMsg



-- HELPER


maybeToList : Maybe a -> List a
maybeToList maybe =
    case maybe of
        Nothing ->
            []

        Just a ->
            [ a ]


setAt : Int -> a -> List a -> List a
setAt index a list =
    if index >= 0 && index < List.length list then
        List.take index list ++ a :: List.drop (index + 1) list

    else
        list



-- UPDATE


type Msg
    = GotLanguages (RemoteData (Error (List Language)) (List Language))
    | GotCategories (RemoteData (Error (List Category)) (List Category))
    | InputTitle String
    | InputAuthor String
    | ClickedCategory Category Bool
      -- Language and Dropdown
    | InputLanguage SelectLanguage
    | SelectLanguage SelectLanguage
    | EnteredSearchText String
    | ClickedwhileOpenDropDown
    | DropdownInfoChanged DropDownInfo
      -- File Upload
    | ClickedUploadFiles
    | DragEnterUploadBox
    | DragLeaveUploadBox
    | GotUploadedFiles File (List File)
    | GotCompressedImage (WebData ( Int, Image ))
    | DeleteImage Int
    | ClickedSave
    | BookSaved (WebData String)
      -- Drag and Drop
    | DnDMsg DnDList.Msg
    | Animate Animation.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InputTitle title ->
            ( { model | title = title }, Cmd.none )

        InputAuthor author ->
            ( { model | author = author }, Cmd.none )

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
            ( { model | language = language }, Cmd.none )

        ClickedSave ->
            let
                maybeLanguage =
                    case ( model.language, model.languageDropdown ) of
                        ( Other, Set lan ) ->
                            Just lan

                        ( English, _ ) ->
                            Just (Language "en" "English")

                        ( Japanese, _ ) ->
                            Just (Language "jp" "Japanese")

                        _ ->
                            Nothing
            in
            -- TODO Full check: non-empty title author pages
            case ( model.category, maybeLanguage ) of
                ( Just category, Just language ) ->
                    ( model
                    , postBook model.title model.author language category model.previews
                    )

                _ ->
                    ( model, Cmd.none )

        ClickedUploadFiles ->
            ( model, Select.files [ "image/*" ] GotUploadedFiles )

        DragEnterUploadBox ->
            ( { model | hoverUploadBox = True }, Cmd.none )

        DragLeaveUploadBox ->
            ( { model | hoverUploadBox = False }, Cmd.none )

        GotUploadedFiles file files ->
            let
                filteredFiles =
                    List.filter (File.mime >> String.startsWith "image/") (file :: files)

                offset =
                    List.length model.previews
            in
            ( { model
                | hoverUploadBox = False
                , previews =
                    model.previews
                        ++ List.map (always emptyImage) filteredFiles
              }
            , filteredFiles
                |> List.indexedMap (\index -> uploadImage (index + offset))
                |> Cmd.batch
            )

        GotCompressedImage result ->
            case result of
                Success ( index, preview ) ->
                    ( { model | previews = setAt index preview model.previews }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        DeleteImage index ->
            let
                previews =
                    List.take index model.previews ++ List.drop (index + 1) model.previews
            in
            ( { model | previews = previews }, Cmd.none )

        BookSaved result ->
            case result of
                Success id ->
                    ( model, Route.replaceUrl model.context.key (Route.BookAdded id) )

                _ ->
                    ( model, Cmd.none )

        GotCategories result ->
            ( { model | categories = result }, Cmd.none )

        ClickedCategory category _ ->
            ( { model | category = Just category }, Cmd.none )

        GotLanguages result ->
            ( { model | languages = result }, Cmd.none )

        -- DropDown
        EnteredSearchText search ->
            case model.languageDropdown of
                Closed ->
                    ( { model | languageDropdown = Open { emptyDropdownInfo | text = search } }, Cmd.none )

                Set lan ->
                    ( { model
                        | languageDropdown =
                            Open
                                { emptyDropdownInfo
                                    | text = String.right 1 search
                                    , selectedLanguage = Just lan
                                }
                      }
                    , Cmd.none
                    )

                Open info ->
                    ( { model | languageDropdown = Open { info | text = search } }, Cmd.none )

        ClickedwhileOpenDropDown ->
            case model.languageDropdown of
                Open { selectedLanguage } ->
                    case selectedLanguage of
                        Nothing ->
                            ( { model | languageDropdown = Closed }, Cmd.none )

                        Just lan ->
                            ( { model | languageDropdown = Set lan }, Cmd.none )

                other ->
                    ( { model | languageDropdown = other }, Cmd.none )

        DropdownInfoChanged dropdownInfo ->
            case model.languageDropdown of
                Open _ ->
                    ( { model | languageDropdown = Open dropdownInfo }, Cmd.none )

                other ->
                    ( { model | languageDropdown = other }, Cmd.none )

        DnDMsg dndMsg ->
            let
                ( dnd, previews ) =
                    system.update dndMsg model.dnd model.previews

                cross =
                    case system.info dnd of
                        Just _ ->
                            Animation.interrupt
                                [ Animation.to [ Animation.rotate (Animation.deg 45) ] ]
                                model.crossAnimation

                        Nothing ->
                            Animation.interrupt
                                [ Animation.to [ Animation.rotate (Animation.deg 0) ] ]
                                model.crossAnimation
            in
            ( { model | dnd = dnd, previews = previews, crossAnimation = cross }
            , system.commands dnd
            )

        Animate animMsg ->
            ( { model | crossAnimation = Animation.update animMsg model.crossAnimation }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        dropdown =
            case model.languageDropdown of
                Open _ ->
                    [ Browser.Events.onClick (Decode.succeed ClickedwhileOpenDropDown) ]

                _ ->
                    []
    in
    Sub.batch
        (system.subscriptions model.dnd
            :: Animation.subscription Animate [ model.crossAnimation ]
            :: dropdown
        )



-- VIEW


iconPlaceholder : Element msg
iconPlaceholder =
    El.el [ width 25, height 25, Background.color Style.nightBlue ] El.none
        |> El.el [ El.padding 5 ]


view : Model -> { title : String, body : Element Msg }
view model =
    let
        back =
            Route.link Route.Books
                [ Font.color Style.grey
                , Border.color Style.grey
                , Border.width 2
                ]
                (El.row [ El.paddingXY 10 5, height 40 ] [ iconPlaceholder, El.text "Back to Mainpage" ])
                |> El.el [ El.paddingEach { left = 40, right = 0, top = 0, bottom = 0 }, Font.size 20 ]

        explanation =
            El.row [ Background.color Style.grey, El.width El.fill, height 45, El.spacing 5, Font.size 20 ]
                [ iconPlaceholder
                , El.text "To add a new book, please fill the following information and upload photos of the pages"
                ]
    in
    { title = "Add an Original Book"
    , body =
        case ( model.categories, model.languages ) of
            ( Success categories, Success languages ) ->
                El.column
                    [ width 1000
                    , El.spacing 30
                    , El.centerX
                    ]
                    [ back
                    , explanation
                    , viewForm model categories languages
                    ]
                    |> El.el [ El.paddingXY 100 30 ]

            _ ->
                El.text "There was a problem retrieving data."
    }


viewForm : Model -> List Category -> List Language -> Element Msg
viewForm { title, author, language, category, languageDropdown, dnd, previews, crossAnimation } categories languages =
    El.column [ El.spacing 20, El.width El.fill, Font.size 18 ]
        [ viewLanguageChoice languageDropdown language languages
            |> El.el [ El.paddingEach { left = 40, right = 0, top = 0, bottom = 0 } ]
        , viewTextInput title "Title" InputTitle
        , viewTextInput author "Author(s)" InputAuthor
        , viewCategories category categories
        , viewPageDownload dnd crossAnimation previews
        , Input.button
            [ Font.color Style.nightBlue
            , Border.color Style.nightBlue
            , Border.width 2
            , El.alignRight
            ]
            { onPress = Just ClickedSave
            , label =
                El.row [ El.paddingXY 10 5, height 40, width 140 ] [ El.text "Add Book", iconPlaceholder ]
            }
        ]


viewLanguageChoice : LanguageDropdown -> SelectLanguage -> List Language -> Element Msg
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


viewTextInput : String -> String -> (String -> Msg) -> Element Msg
viewTextInput text label message =
    Input.text
        [ Border.color Style.nightBlue
        , Border.rounded 0
        , Border.width 2
        , El.spacing 10
        , width 340
        , height 42
        , El.padding 10

        -- This is for the input-in-radio bug workaround
        , El.htmlAttribute (Attributes.id ("attr-" ++ label))
        ]
        { onChange = message
        , text = text
        , placeholder = Nothing
        , label =
            Input.labelLeft [ El.height El.fill, Background.color Style.nightBlue ]
                (El.el [ width 100, El.padding 10, El.centerY ] (El.text label))
        }
        |> El.el [ El.paddingEach { left = 40, right = 0, top = 0, bottom = 0 } ]


viewLanguageDropdown : LanguageDropdown -> List Language -> Element Msg
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
        ([ width 280
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
                                        [ El.width El.fill
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
                            |> El.el [ El.centerX, El.centerY, Font.size 16 ]
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
            [ iconPlaceholder, El.text "Select Topic" ]
        , categories
            |> List.map viewCategory
            |> El.wrappedRow [ El.paddingXY 40 0, El.spacing 10 ]
        ]
        |> El.el [ El.paddingEach { top = 5, bottom = 0, left = 0, right = 0 } ]


viewPageDownload : DnDList.Model -> Animation.State -> List Image -> Element Msg
viewPageDownload dnd crossAnimation images =
    El.column [ El.spacing 20, El.inFront (ghostView dnd images) ]
        [ El.row
            [ Background.color Style.grey
            , width 250
            , height 45
            , Font.size 20
            , Events.onClick ClickedUploadFiles
            ]
            [ iconPlaceholder, El.text "Add Pages" ]
            |> El.el [ El.paddingEach { top = 5, bottom = 0, left = 0, right = 0 } ]
        , El.row [ El.spacing 10 ]
            [ List.indexedMap (viewPreview dnd) images
                ++ [ viewAddOrDelete dnd crossAnimation ]
                |> El.wrappedRow
                    [ width 620
                    , El.spacingXY 10 30
                    , El.height (El.minimum 200 El.shrink)
                    ]
                |> El.el
                    [ Border.color Style.nightBlue
                    , El.padding 10
                    , Border.width 2
                    , hijackOn "dragenter" (Decode.succeed DragEnterUploadBox)
                    , hijackOn "dragover" (Decode.succeed DragEnterUploadBox)
                    , hijackOn "dragleave" (Decode.succeed DragLeaveUploadBox)
                    , hijackOn "drop" dropDecoder
                    ]
            , El.textColumn [ El.alignTop, Font.size 18, El.width El.fill, Font.color Style.nightBlue, El.spacing 10 ]
                [ El.paragraph [] [ El.text "Click on the + or drag images into the field to upload." ]
                , El.paragraph [] [ El.text "Drag the images to reorder. Drop on the x to remove." ]
                ]
            ]
            |> El.el [ El.paddingEach { top = 0, bottom = 5, left = 40, right = 0 } ]
        ]


dropDecoder : Decoder Msg
dropDecoder =
    Decode.at [ "dataTransfer", "files" ] (Decode.oneOrMore GotUploadedFiles File.decoder)


hijackOn : String -> Decoder msg -> Attribute msg
hijackOn event decoder =
    Html.Events.preventDefaultOn event (Decode.map hijack decoder)
        |> El.htmlAttribute


hijack : msg -> ( msg, Bool )
hijack msg =
    ( msg, True )


viewPreview : DnDList.Model -> Int -> Image -> Element Msg
viewPreview dnd index { preview } =
    let
        itemId : String
        itemId =
            "id-image-" ++ String.fromInt index

        baseAttributes =
            [ width 80
            , height 80
            , Border.width 2
            , Border.color Style.nightBlue
            , El.htmlAttribute (Attributes.id itemId)
            ]
    in
    case system.info dnd of
        Just { dragIndex } ->
            if dragIndex /= index then
                El.el
                    (Background.image preview
                        :: List.map El.htmlAttribute (system.dropEvents index itemId)
                        ++ baseAttributes
                    )
                    El.none

            else
                El.el
                    (Background.color Style.nightBlue :: baseAttributes)
                    El.none

        Nothing ->
            El.el
                (Background.image preview
                    :: baseAttributes
                    ++ List.map El.htmlAttribute (system.dragEvents index itemId)
                )
                El.none


ghostView : DnDList.Model -> List Image -> Element Msg
ghostView dnd previews =
    let
        maybeDragItem : Maybe Image
        maybeDragItem =
            system.info dnd
                |> Maybe.andThen (\{ dragIndex } -> previews |> List.drop dragIndex |> List.head)
    in
    case maybeDragItem of
        Just { preview } ->
            El.el
                (width 80
                    :: height 80
                    :: Background.image preview
                    :: List.map El.htmlAttribute (system.ghostStyles dnd)
                )
                El.none

        Nothing ->
            El.none


viewAddOrDelete : DnDList.Model -> Animation.State -> Element Msg
viewAddOrDelete dnd crossAnimation =
    Svg.svg
        (S.width "80"
            :: S.height "80"
            :: S.viewBox "0 0 80 80"
            :: S.fill "rgb(61, 152, 255)"
            :: Animation.render crossAnimation
        )
        [ Svg.g []
            [ Svg.rect [ S.x "32.5", S.y "10", S.width "15", S.height "60" ] []
            , Svg.rect [ S.x "10", S.y "32.5", S.width "60", S.height "15" ] []
            ]
        ]
        |> El.html
        |> El.el
            [ case system.info dnd of
                Nothing ->
                    Events.onClick ClickedUploadFiles

                Just { dragIndex } ->
                    Events.onMouseUp (DeleteImage dragIndex)
            ]



-- REST API


encodeBook : String -> String -> Language -> Category -> Value
encodeBook title author language category =
    Encode.object
        [ ( "title", Encode.string title )
        , ( "author", Encode.string author )
        , ( "language_id", Encode.string language.id )
        , ( "category_id", Encode.string category.id )
        ]


decodeBookId : Decoder String
decodeBookId =
    Decode.at [ "data", "id" ] Decode.string


postBook : String -> String -> Language -> Category -> List Image -> Cmd Msg
postBook title author language category previews =
    Http.post
        { url = "api/rest/books"
        , body =
            Http.stringPart "book" (Encode.encode 0 (encodeBook title author language category))
                :: List.map (.file >> Http.bytesPart "pages[]" "image/jpeg") previews
                |> Http.multipartBody
        , expect = Http.expectJson (RemoteData.fromResult >> BookSaved) decodeBookId
        }


uploadImage : Int -> File -> Cmd Msg
uploadImage page file =
    Http.post
        { url = "api/rest/pages"
        , body =
            Http.multipartBody
                [ Http.stringPart "page" (String.fromInt page)
                , Http.filePart "image" file
                ]
        , expect = Http.expectBytes (RemoteData.fromResult >> GotCompressedImage) fileImageDecoder
        }


fileImageDecoder : Bytes.Decode.Decoder ( Int, Image )
fileImageDecoder =
    let
        toUrl =
            Base64.fromBytes >> Maybe.withDefault "" >> (++) "data:image/jpeg;base64,"
    in
    Bytes.Decode.map2 Tuple.pair
        (Bytes.Decode.unsignedInt16 BE)
        (Bytes.Decode.unsignedInt32 BE
            |> Bytes.Decode.andThen
                (\length ->
                    Bytes.Decode.bytes length
                        |> Bytes.Decode.andThen
                            (\file -> Bytes.Decode.succeed (Image file (toUrl file)))
                )
        )



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
