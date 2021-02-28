module Page.Translation exposing (Model, Msg, init, subscriptions, update, view)

import Api exposing (Cred, GraphQLData)
import Browser.Events
import Common exposing (Context, height, width)
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events
import Element.Font as Font
import Element.Input as Input exposing (OptionState(..))
import GraphQLBook.Mutation as Mutation
import GraphQLBook.Object exposing (Translation, TranslationBook)
import GraphQLBook.Object.Book as GBook
import GraphQLBook.Object.Page as GPage
import GraphQLBook.Object.Translation as GTranslation
import GraphQLBook.Object.TranslationBook as TBook
import GraphQLBook.Object.TranslationPage as GTranslationPage
import GraphQLBook.Query as Query
import GraphQLBook.Scalar exposing (Id(..))
import Graphql.Http exposing (HttpError(..), RawError(..))
import Graphql.Operation exposing (RootMutation)
import Graphql.OptionalArgument as OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Html.Attributes as Attributes
import Json.Decode as Decode exposing (Decoder)
import LanguageSelect
import List.Extra as List
import Maybe.Extra as Maybe
import RemoteData exposing (RemoteData(..))
import Route exposing (Route(..))
import Style
import Svg exposing (Svg)
import Svg.Attributes as A
import Svg.Events
import Types exposing (Language, Page, Translation)
import ZipList exposing (ZipList)



-- TYPES


type alias Model =
    { context : Context
    , cred : Cred

    -- Book Info
    , bookId : String
    , book : GraphQLData (Maybe Book)
    , translationBookId : Maybe String
    , translationBook : GraphQLData (Maybe TranslationBook)
    , title : String
    , author : String
    , language : LanguageSelect.Model Msg
    , translator : String
    , notes : String
    , languages : GraphQLData (List Language)
    , saving : Bool
    , showMissingFields : Bool

    -- Translating
    , drawingState : DrawingState
    , text : String
    , blob : List Position
    , path : String
    , mode : Mode
    , editModeState : FocusState
    , notesInputState : FocusState
    }


init : Context -> Cred -> String -> Maybe String -> ( Model, Cmd Msg )
init context cred bookId translationBookId =
    let
        editParams =
            case translationBookId of
                Nothing ->
                    { book = Loading
                    , translationBook = NotAsked
                    , cmd = [ getBook cred bookId ]
                    , button = "Create Translation"
                    , mode = CreateTranslationBook
                    }

                Just id ->
                    { book = NotAsked
                    , translationBook = Loading
                    , cmd = [ getTranslationBook cred (Id id) ]
                    , button = "Save"
                    , mode = EditTranslationBook id
                    }
    in
    ( { context = context
      , cred = cred
      , bookId = bookId
      , book = editParams.book
      , translationBookId = translationBookId
      , translationBook = editParams.translationBook
      , title = ""
      , author = ""
      , language = LanguageSelect.init "Translation Language" "attr-Translated Title" LanguageMsg
      , translator = ""
      , notes = ""
      , languages = Loading
      , mode = editParams.mode
      , saving = False
      , showMissingFields = False

      -- Translating
      , drawingState = NotDrawing
      , text = ""
      , blob = []
      , path = ""
      , editModeState = Inactive
      , notesInputState = Inactive
      }
    , Cmd.batch (getlanguages cred :: editParams.cmd)
    )


type Mode
    = CreateTranslationBook
    | EditTranslationBook String
    | ReadTranslations String
    | EditTranslation String Translation


type alias Book =
    { id : String
    , title : String
    , author : String
    , language : Language
    }


type alias TranslationBook =
    { id : String
    , originalTitle : String
    , originalAuthor : String
    , title : String
    , author : String
    , language : Language
    , translator : String
    , notes : String
    , pages : ZipList Page
    }


type alias ValidTranslationBook =
    { id : Maybe String
    , bookId : String
    , title : String
    , author : String
    , language : Language
    , translator : String
    , notes : String
    }


type alias Page =
    { id : String
    , image : String
    , width : Int
    , height : Int
    , imageType : String
    , pageNumber : Int
    , translations : List Translation
    }


type alias Translation =
    { id : Maybe String
    , pageId : String
    , text : String
    , path : String
    }


type alias Position =
    { x : Int
    , y : Int
    }


addPos : Position -> Position -> Position
addPos p1 p2 =
    Position (p1.x + p2.x) (p1.y + p2.y)


subPos : Position -> Position -> Position
subPos p1 p2 =
    Position (p1.x - p2.x) (p1.y - p2.y)


multPos : Float -> Position -> Position
multPos a { x, y } =
    Position (round (a * toFloat x)) (round (a * toFloat y))


normPos : Position -> Float
normPos { x, y } =
    sqrt (toFloat x ^ 2 + toFloat y ^ 2)


type DrawingState
    = NotDrawing
    | Drawing Position


type alias Color =
    { red : Int
    , green : Int
    , blue : Int
    , alpha : Float
    }


type FocusState
    = Inactive
    | Clicked
    | Focused


lowerNotesState : FocusState -> FocusState
lowerNotesState state =
    case state of
        Clicked ->
            Focused

        Focused ->
            Inactive

        Inactive ->
            Inactive


toHex : Color -> String
toHex { red, green, blue, alpha } =
    String.concat
        [ "rgb("
        , String.fromInt red
        , ", "
        , String.fromInt green
        , ", "
        , String.fromInt blue
        , ", "
        , String.fromFloat alpha
        , ")"
        ]


mapToPages :
    (a -> a)
    -> RemoteData e (Maybe { b | pages : a })
    -> RemoteData e (Maybe { b | pages : a })
mapToPages f =
    (\({ pages } as book) -> { book | pages = f pages })
        |> Maybe.map
        |> RemoteData.map


mapCurrentTranslations : (List Translation -> List Translation) -> ZipList Page -> ZipList Page
mapCurrentTranslations f ziplist =
    let
        transform page =
            { page | translations = f page.translations }
    in
    ZipList.replace (transform (ZipList.current ziplist)) ziplist


type Action
    = NoAction
    | GoToNextPage
    | GoToPreviousPage
    | EditOtherTranslation Translation
    | BackToBookDetail



-- UPDATE


type Msg
    = InputTitle String
    | InputAuthor String
    | InputTranslator String
    | InputNotes String
    | LanguageMsg LanguageSelect.Msg
    | GotBook (GraphQLData (Maybe Book))
    | GotTranslationBook (String -> Mode) (GraphQLData (Maybe TranslationBook))
    | GotLanguages (GraphQLData (List Language))
    | ClickedSaveBookInfo
    | ShowMissingFields
    | ClickedSaveAndReturnFromBookInfo
      -- Translating
    | StartedDrawing
    | Drew Bool Position
    | StoppedDrawing
    | InputText String
    | ClickedNotes
    | ClickedResetPath
    | ClickedNewTranslation String String
    | ClickedPrevPage
    | ClickedNextPage
    | PressedKey Key
    | ClickedSaveTranslation
    | ClickedTranslation Translation
    | ClickedSomewhereOnPage
    | ClickedDelete String Translation
    | GotTranslationChange (Translation -> Mode) (Translation -> ZipList Page -> ZipList Page) (GraphQLData (Maybe Translation))
    | ClickedSaveAndReturnFromTranslation


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- Book Info
        InputTitle title ->
            ( { model | title = title }, Cmd.none )

        InputAuthor author ->
            ( { model | author = author }, Cmd.none )

        InputTranslator translator ->
            ( { model | translator = translator }, Cmd.none )

        InputNotes notes ->
            ( { model | notes = notes }, Cmd.none )

        ClickedSaveBookInfo ->
            ( { model | saving = True }, saveTranslationBookFromModel model )

        ShowMissingFields ->
            ( { model | showMissingFields = True, language = LanguageSelect.showMissingFields model.language }
            , Cmd.none
            )

        GotBook result ->
            ( { model | book = result }, Cmd.none )

        GotTranslationBook toMode result ->
            case result of
                Success (Just { id, title, author, language, translator, notes }) ->
                    ( { model
                        | title = title
                        , author = author
                        , translator = translator
                        , notes = notes
                        , translationBook = result
                        , language = LanguageSelect.updateLanguage language model.language
                        , mode = toMode id
                        , saving = False
                      }
                    , Cmd.none
                    )

                _ ->
                    ( { model | translationBook = result, saving = False }, Cmd.none )

        GotLanguages result ->
            ( case result of
                Success languages ->
                    { model
                        | languages = result
                        , language = LanguageSelect.updateLanguageList languages model.language
                    }

                _ ->
                    { model | languages = result }
            , Cmd.none
            )

        ClickedSaveAndReturnFromBookInfo ->
            ( { model | saving = True }
            , Cmd.batch
                [ saveTranslationBookFromModel model
                , Route.replaceUrl model.context.key (Route.BookDetail model.bookId False)
                ]
            )

        -- Translating
        LanguageMsg languageMsg ->
            let
                ( language, newMsg ) =
                    LanguageSelect.update languageMsg model.language
            in
            ( { model | language = language }, newMsg )

        StartedDrawing ->
            ( { model | drawingState = Drawing { x = 0, y = 0 }, editModeState = Clicked }
            , Cmd.none
            )

        Drew _ pos ->
            ( { model
                | drawingState = Drawing pos
                , blob =
                    if List.head model.blob == Just pos then
                        model.blob

                    else
                        pos :: model.blob
              }
            , Cmd.none
            )

        StoppedDrawing ->
            ( { model
                | drawingState = NotDrawing
                , blob = []
                , path =
                    model.blob
                        |> List.reverse
                        |> keepEvery 5
                        |> catmullRom
                        |> (++) (" " ++ model.path)
                , editModeState = Clicked
              }
            , Cmd.none
            )

        InputText text ->
            ( { model | text = text }, Cmd.none )

        ClickedNotes ->
            ( { model | notesInputState = Clicked }, Cmd.none )

        ClickedTranslation ({ text, path } as translation) ->
            let
                clickedModel =
                    { model | editModeState = Clicked }
            in
            case model.mode of
                EditTranslation _ trans ->
                    if trans == translation then
                        ( clickedModel, Cmd.none )

                    else
                        saveTranslationAndDo clickedModel (EditOtherTranslation translation)

                ReadTranslations trBookId ->
                    ( { clickedModel | mode = EditTranslation trBookId translation, text = text, path = path }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        ClickedSomewhereOnPage ->
            let
                newModel =
                    { model
                        | editModeState = lowerNotesState model.editModeState
                        , notesInputState = lowerNotesState model.notesInputState
                    }
            in
            case model.editModeState of
                Focused ->
                    saveTranslationAndDo newModel NoAction

                _ ->
                    ( newModel, Cmd.none )

        ClickedDelete trBookId translation ->
            case translation.id of
                Nothing ->
                    ( { model | mode = ReadTranslations trBookId, text = "", blob = [], path = "" }, Cmd.none )

                Just id ->
                    ( model
                    , deleteTranslation model.cred
                        id
                        (GotTranslationChange (always (ReadTranslations trBookId))
                            (\tran -> mapCurrentTranslations (List.filter ((/=) tran)))
                        )
                    )

        ClickedResetPath ->
            ( { model | path = "", editModeState = Clicked }, Cmd.none )

        ClickedNewTranslation trBookId pageId ->
            saveTranslationAndDo
                { model
                    | mode = EditTranslation trBookId (Translation Nothing pageId model.text model.path)
                    , editModeState = Clicked
                }
                NoAction

        ClickedPrevPage ->
            saveTranslationAndDo model GoToPreviousPage

        ClickedNextPage ->
            saveTranslationAndDo model GoToNextPage

        ClickedSaveTranslation ->
            saveTranslationAndDo model NoAction

        PressedKey key ->
            case key of
                Left ->
                    saveTranslationAndDo model GoToPreviousPage

                Right ->
                    case model.mode of
                        CreateTranslationBook ->
                            ( model, Cmd.none )

                        EditTranslationBook _ ->
                            ( { model | saving = True }, saveTranslationBookFromModel model )

                        _ ->
                            saveTranslationAndDo model GoToNextPage

                Other ->
                    ( model, Cmd.none )

        ClickedSaveAndReturnFromTranslation ->
            saveTranslationAndDo model BackToBookDetail

        GotTranslationChange toMode pagesUpdate result ->
            case result of
                Success (Just translation) ->
                    let
                        mode =
                            toMode translation

                        ( text, path ) =
                            case mode of
                                EditTranslation _ trans ->
                                    ( trans.text, trans.path )

                                _ ->
                                    ( "", "" )
                    in
                    ( { model
                        | translationBook = mapToPages (pagesUpdate translation) model.translationBook
                        , text = text
                        , path = path
                        , mode = mode
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )


validTranslationBook : Model -> Maybe ValidTranslationBook
validTranslationBook { language, bookId, translationBookId, title, author, translator, notes } =
    let
        nonEmpty string =
            case string of
                "" ->
                    Nothing

                _ ->
                    Just string
    in
    Just (ValidTranslationBook translationBookId)
        |> Maybe.andMap (Just bookId)
        |> Maybe.andMap (nonEmpty title)
        |> Maybe.andMap (nonEmpty author)
        |> Maybe.andMap (LanguageSelect.getLanguage language)
        |> Maybe.andMap (nonEmpty translator)
        |> Maybe.andMap (Just notes)


saveTranslationBookFromModel : Model -> Cmd Msg
saveTranslationBookFromModel model =
    case validTranslationBook model of
        Just translationBook ->
            saveTranslationBook model.cred translationBook

        _ ->
            Cmd.none


saveTranslationAndDo : Model -> Action -> ( Model, Cmd Msg )
saveTranslationAndDo model action =
    let
        isFirstPage =
            RemoteData.map (Maybe.map (.pages >> ZipList.current >> .pageNumber >> (==) 0)) model.translationBook
                == Success (Just True)

        move =
            case action of
                GoToPreviousPage ->
                    ZipList.backward

                GoToNextPage ->
                    ZipList.forward

                _ ->
                    identity

        backToBookDetail =
            case action of
                BackToBookDetail ->
                    [ Route.replaceUrl model.context.key (Route.BookDetail model.bookId False) ]

                _ ->
                    []
    in
    case ( model.mode, action ) of
        ( ReadTranslations _, NoAction ) ->
            ( model, Cmd.none )

        ( ReadTranslations _, GoToNextPage ) ->
            ( { model | translationBook = mapToPages ZipList.forward model.translationBook }, Cmd.none )

        ( ReadTranslations trBook, GoToPreviousPage ) ->
            if isFirstPage then
                ( { model | mode = EditTranslationBook trBook }, Cmd.none )

            else
                ( { model | translationBook = mapToPages ZipList.backward model.translationBook }, Cmd.none )

        ( ReadTranslations _, BackToBookDetail ) ->
            ( model, Route.replaceUrl model.context.key (Route.BookDetail model.bookId False) )

        ( EditTranslation trBookId translation, _ ) ->
            let
                message =
                    case ( translation.id, action ) of
                        ( Nothing, _ ) ->
                            GotTranslationChange (EditTranslation trBookId)
                                (\tran -> mapCurrentTranslations (\t -> t ++ [ tran ]) >> move)

                        ( Just _, EditOtherTranslation otherTranslation ) ->
                            GotTranslationChange (always (EditTranslation trBookId otherTranslation))
                                (\tran -> mapCurrentTranslations (List.map (replace tran)))

                        ( Just _, _ ) ->
                            GotTranslationChange (always (ReadTranslations trBookId))
                                (\tran -> mapCurrentTranslations (List.map (replace tran)) >> move)
            in
            ( model
            , Cmd.batch
                (mutateTranslation model.cred trBookId { translation | text = model.text, path = model.path } message
                    :: backToBookDetail
                )
            )

        _ ->
            ( model, Cmd.none )


keepEvery : Int -> List a -> List a
keepEvery n list =
    let
        length =
            List.length list
    in
    list
        |> List.indexedMap Tuple.pair
        |> List.filter (\( i, _ ) -> modBy n i == 0 || i + 1 == length)
        |> List.map Tuple.second


replace : { a | id : Maybe String } -> { a | id : Maybe String } -> { a | id : Maybe String }
replace a b =
    if a.id == b.id then
        a

    else
        b



-- SUBSCRIPTIONS


type Key
    = Left
    | Right
    | Other


keyDecoder : Decode.Decoder Key
keyDecoder =
    Decode.map toKey (Decode.field "key" Decode.string)


toKey : String -> Key
toKey string =
    case string of
        "ArrowLeft" ->
            Left

        "ArrowRight" ->
            Right

        _ ->
            Other


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.drawingState of
        Drawing _ ->
            Sub.batch
                [ Browser.Events.onMouseMove
                    (Decode.map2 Drew decodeButtons (decodePosition model.context.windowWidth))
                , Browser.Events.onMouseUp (Decode.succeed StoppedDrawing)
                ]

        NotDrawing ->
            let
                language =
                    LanguageSelect.subscriptions model.language

                arrows =
                    if model.notesInputState == Inactive && model.editModeState == Inactive then
                        [ Browser.Events.onKeyDown (Decode.map PressedKey keyDecoder) ]

                    else
                        []

                clicks =
                    case model.mode of
                        CreateTranslationBook ->
                            []

                        _ ->
                            [ Browser.Events.onClick (Decode.succeed ClickedSomewhereOnPage) ]
            in
            Sub.batch (language :: arrows ++ clicks)


decodeButtons : Decoder Bool
decodeButtons =
    Decode.field "buttons" (Decode.map (\buttons -> buttons == 1) Decode.int)


decodePosition : Int -> Decoder Position
decodePosition width =
    let
        offset =
            { x = (width - 1000) // 2, y = 200 }
    in
    Decode.map2 Position
        (Decode.field "pageX" Decode.int |> Decode.map (\n -> n - offset.x))
        -- (Decode.at [ "currentTarget", "defaultView", "innerWidth" ] Decode.int |> Decode.map (\n -> n - 100))
        (Decode.field "pageY" Decode.int |> Decode.map (\n -> n - offset.y))



-- VIEW


view : Model -> { title : String, body : Element Msg }
view model =
    { title = "Book Translation"
    , body =
        case ( model.mode, model.translationBook, model.book ) of
            ( CreateTranslationBook, _, Success (Just book) ) ->
                viewForm model book.title book.author

            ( CreateTranslationBook, _, _ ) ->
                El.text ("There was an issue retrieving the original book with id: " ++ model.bookId)

            ( EditTranslationBook _, Success (Just translationBook), _ ) ->
                viewForm model translationBook.originalTitle translationBook.originalAuthor

            ( EditTranslationBook id, _, _ ) ->
                El.text ("There was an issue retrieving the translation book with id: " ++ id)

            ( _, Success (Just { pages }), _ ) ->
                viewTranslate model pages

            ( ReadTranslations id, _, _ ) ->
                El.text ("There was an issue retrieving the translation book with id: " ++ id)

            ( EditTranslation id _, _, _ ) ->
                El.text ("There was an issue retrieving the translation book with id: " ++ id)
    }


iconPlaceholder : Element msg
iconPlaceholder =
    El.el [ width 25, height 25, Background.color Style.nightBlue ] El.none
        |> El.el [ El.padding 5 ]


saveAndReturn : msg -> Element msg
saveAndReturn save =
    Input.button [ El.paddingXY 70 0 ]
        { onPress = Just save
        , label =
            El.row [ El.paddingXY 10 5, height 40 ] [ iconPlaceholder, El.text "Save all and Return" ]
                |> El.el [ Font.color Style.grey, Border.color Style.grey, Border.width 2, Font.size 20 ]
        }


viewForm : Model -> String -> String -> Element Msg
viewForm ({ title, author, language, translator, notes, mode } as model) originalTitle originalAuthor =
    let
        explanation =
            El.row [ Background.color Style.grey, El.width El.fill, height 45, El.spacing 5, Font.size 20 ]
                [ iconPlaceholder
                , El.text "Please fill the following information before starting your translation"
                ]
                |> El.el [ El.paddingEach { top = 20, bottom = 30, left = 0, right = 0 }, El.width El.fill ]

        saveButton =
            Input.button [ El.alignRight, height 25, width 100 ]
                (case ( validTranslationBook model, model.saving ) of
                    ( Just _, False ) ->
                        { onPress = Just ClickedSaveBookInfo
                        , label =
                            El.text "Save"
                                |> El.el [ El.centerX, El.centerY ]
                                |> El.el [ Background.color Style.nightBlue, El.height El.fill, El.width El.fill ]
                        }

                    _ ->
                        { onPress = Just ShowMissingFields
                        , label =
                            El.text "Save"
                                |> El.el [ El.centerX, El.centerY ]
                                |> El.el [ Background.color Style.grey, El.height El.fill, El.width El.fill ]
                        }
                )
    in
    El.column
        [ El.spacing 30, El.paddingXY 0 30, width 1140 ]
        [ saveAndReturn ClickedSaveAndReturnFromBookInfo
        , El.column [ El.spacing 20 ]
            [ El.row []
                [ -- Number on the left
                  El.text "0"
                    |> El.el [ El.centerX, El.centerY, Font.color Style.white, Font.size 30 ]
                    |> El.el [ width 55, height 45, Background.color Style.nightBlue, El.alignRight ]
                    |> El.el [ El.paddingXY 0 25, width 70, El.alignTop ]

                -- Form fields
                , El.column [ El.spacing 20 ]
                    [ El.column [ El.spacing 20, Border.width 2, Border.color Style.nightBlue, El.padding 20, width 1000 ]
                        [ explanation
                        , El.row [ width 792, El.height El.fill, Background.color Style.grey, El.padding 5, El.spacing 10 ]
                            [ iconPlaceholder
                            , El.el [ El.centerY, Font.size 20 ]
                                (String.concat [ "\"", originalTitle, "\", by \"", originalAuthor, "\"" ] |> El.text)
                            ]
                        , LanguageSelect.view language
                            |> El.el [ El.paddingEach { left = 40, right = 0, top = 0, bottom = 0 } ]
                        , viewTextInput title "Translated Title" InputTitle model.showMissingFields
                        , viewTextInput author "Translated Author(s)" InputAuthor model.showMissingFields
                        , viewTextInput translator "Name of Translator(s)" InputTranslator model.showMissingFields
                        , saveButton
                        ]
                    ]

                -- Arrow on the right
                , (case mode of
                    EditTranslationBook _ ->
                        El.el [ El.alignRight, El.alignBottom, Element.Events.onClick ClickedSaveBookInfo ]
                            iconPlaceholder

                    _ ->
                        El.none
                  )
                    |> El.el [ width 70, height 393, El.alignTop ]
                ]

            -- Notes
            , viewNotes notes
                |> El.el [ El.paddingXY 70 0, El.alignRight ]
            ]
        ]


viewTextInput : String -> String -> (String -> Msg) -> Bool -> Element Msg
viewTextInput text label message showMissingFields =
    Input.text
        [ if showMissingFields && String.isEmpty text then
            Border.color Style.oistRed

          else
            Border.color Style.nightBlue
        , Border.rounded 0
        , Border.width 2
        , width 532
        , height 42
        , El.spacing 20
        , Font.size 18

        -- This is for the input-in-radio bug workaround
        , El.htmlAttribute (Attributes.id ("attr-" ++ label))
        ]
        { onChange = message
        , text = text
        , placeholder = Nothing
        , label =
            Input.labelLeft
                [ El.height El.fill, Background.color Style.nightBlue ]
                (El.el [ width 200, El.padding 10, El.centerY ] (El.text label))
        }
        |> El.el [ El.paddingEach { left = 40, right = 0, top = 0, bottom = 0 } ]


viewTranslate : Model -> ZipList Page -> Element Msg
viewTranslate model pages =
    let
        leftArrow =
            El.el [ Element.Events.onClick ClickedPrevPage, El.alignLeft ] iconPlaceholder
                |> El.el [ width 70, El.centerY ]

        rightArrow =
            El.el [ Element.Events.onClick ClickedNextPage, El.alignRight ]
                (if not (ZipList.currentIndex pages == ZipList.length pages - 1) then
                    iconPlaceholder

                 else
                    El.none
                )
                |> El.el [ width 70, El.centerY ]

        explanation =
            El.row [ width 575, height 90, Border.color Style.nightBlue, Border.width 2, Font.color Style.nightBlue ]
                [ iconPlaceholder
                , El.paragraph [ El.padding 10 ]
                    [ El.text "Mark a section of text on the page by drawing with your mouse or finger" ]
                , iconPlaceholder
                , El.paragraph [ El.padding 10 ]
                    [ El.text "Then add the translation into the text field below with the matching color" ]
                ]
    in
    El.column
        [ El.spacing 30, El.paddingXY 0 30, width 1140 ]
        [ saveAndReturn ClickedSaveAndReturnFromTranslation
        , El.row []
            [ -- Number  on the left
              ZipList.current pages
                |> .pageNumber
                |> (+) 1
                |> String.fromInt
                |> El.text
                |> El.el [ El.centerX, El.centerY, Font.color Style.white, Font.size 30 ]
                |> El.el [ width 57, height 45, Background.color Style.nightBlue, El.moveRight 2 ]
                |> El.el [ El.paddingXY 0 25, El.alignRight ]
                |> El.el [ width 70, El.alignTop ]

            -- Picture
            , viewImage model.mode (ZipList.current pages) model.blob model.path
                |> El.el [ El.onLeft leftArrow, El.onRight rightArrow ]
            ]

        -- Translations and notes
        , El.row [ width 1000, El.paddingXY 71 0, El.spacing 25 ]
            [ El.column [ El.spacing 20, El.alignTop ]
                [ viewButtons model.mode (ZipList.current pages).id
                , case (ZipList.current pages).translations of
                    [] ->
                        explanation

                    translations ->
                        translations
                            |> List.map2 (viewTranslation model.mode model.text) colors
                            |> El.column [ El.spacing 20, El.alignTop ]
                ]
            , viewNotes model.notes
                |> El.el [ El.alignRight, El.alignTop ]
            ]
        ]


viewImage : Mode -> Page -> List Position -> String -> Element Msg
viewImage mode { translations, image } blob tempPath =
    let
        paths =
            case mode of
                ReadTranslations _ ->
                    List.map2 (viewPath mode) colors translations

                EditTranslation _ translation ->
                    let
                        pathColor =
                            List.elemIndex translation translations
                                |> Maybe.andThen (\i -> List.getAt i colors)
                                |> Maybe.withDefault yellow
                    in
                    [ viewPath mode pathColor (Translation Nothing "" "" tempPath), viewPosPath pathColor blob ]

                _ ->
                    []

        event =
            case mode of
                EditTranslation _ _ ->
                    [ Svg.Events.on "mousedown" (Decode.succeed StartedDrawing) ]

                _ ->
                    []
    in
    Svg.svg
        (A.width "1000" :: A.height "751" :: A.viewBox "0 0 1000 752" :: event)
        (Svg.rect [ A.width "1000", A.height "751", A.fill "rgb(61, 152, 255)" ] []
            :: Svg.rect [ A.x "2", A.y "2", A.width "996", A.height "747", A.fill "rgb(255, 255, 255)" ] []
            :: Svg.image [ A.x "2", A.y "2", A.width "996", A.height "747", A.xlinkHref image ] []
            :: paths
        )
        |> El.html


yellow : Color
yellow =
    Color 251 236 93 0.25


colors : List Color
colors =
    [ Color 230 25 75 0.25, Color 60 180 75 0.25, Color 255 225 25 0.25, Color 0 130 200 0.25, Color 245 130 48 0.25, Color 145 30 180 0.25, Color 70 240 240 0.25, Color 240 50 230 0.25, Color 210 245 60 0.25, Color 250 190 212 0.25, Color 0 128 128 0.25, Color 220 190 255 0.25, Color 170 110 40 0.25, Color 255 250 200 0.25, Color 128 0 0 0.25, Color 170 255 195 0.25, Color 128 128 0 0.25, Color 255 215 180 0.25, Color 0 0 128 0.25, Color 128 128 128 0.25, Color 0 0 0 0.25 ]


viewPosPath : Color -> List Position -> Svg Msg
viewPosPath color blob =
    Svg.path
        [ blob
            |> List.reverse
            |> keepEvery 5
            |> catmullRom
            |> A.d
        , A.fill "none"
        , A.stroke (toHex color)
        , A.strokeWidth "35"
        , A.strokeLinecap "round"
        ]
        []


viewPath : Mode -> Color -> Translation -> Svg Msg
viewPath mode color translation =
    Svg.path
        ([ A.d translation.path
         , A.fill "none"
         , A.stroke (toHex color)
         , A.strokeWidth "35"
         , A.strokeLinecap "round"
         ]
            ++ (case mode of
                    ReadTranslations _ ->
                        [ Svg.Events.onClick (ClickedTranslation translation) ]

                    _ ->
                        []
               )
        )
        []



-- https://stackoverflow.com/questions/30748316/catmull-rom-interpolation-on-svg-paths


catmullRom : List Position -> String
catmullRom points =
    let
        toString { x, y } =
            String.fromInt x ++ " " ++ String.fromInt y

        last2 p0 p1 ps =
            case List.reverse ps of
                [] ->
                    ( p0, p1 )

                [ p2 ] ->
                    ( p1, p2 )

                pLast :: pBeforeLast :: _ ->
                    ( pBeforeLast, pLast )

        pad ( p0, p1 ) ( pBeforeLast, pLast ) ps =
            Position (2 * p0.x - p1.x) (2 * p0.y - p1.y)
                :: (ps ++ [ Position (2 * pLast.x - pBeforeLast.x) (2 * pLast.y - pBeforeLast.y) ])

        toCublicSpline ps =
            List.map4 curve ps (List.drop 1 ps) (List.drop 2 ps) (List.drop 3 ps)
                |> String.concat

        curve p0 p1 p2 p3 =
            let
                t0 =
                    0

                t1 =
                    t0 + normPos (subPos p1 p0)

                t2 =
                    t1 + normPos (subPos p2 p1)

                t3 =
                    t2 + normPos (subPos p3 p2)

                m1 =
                    addPos (multPos (((t2 - t1) ^ 2) / ((t2 - t0) * (t1 - t0))) (subPos p1 p0))
                        (multPos (((t2 - t1) * (t1 - t0)) / ((t2 - t0) * (t2 - t1))) (subPos p2 p1))

                m2 =
                    addPos (multPos (((t2 - t1) * (t3 - t2)) / ((t3 - t1) * (t3 - t1))) (subPos p2 p1))
                        (multPos (((t2 - t1) ^ 2) / ((t3 - t1) * (t3 - t2))) (subPos p3 p2))

                q1 =
                    addPos p1 (multPos (1 / 3) m1)

                q2 =
                    subPos p2 (multPos (1 / 3) m2)

                path =
                    String.concat [ " C ", toString q1, ", ", toString q2, ", ", toString p2 ]
            in
            if String.contains "NaN" path then
                ""

            else
                path
    in
    case points of
        [] ->
            ""

        [ _ ] ->
            ""

        p0 :: p1 :: _ ->
            pad ( p0, p1 ) (last2 p0 p1 points) points
                |> toCublicSpline
                |> (++) ("M " ++ toString p1)


viewButtons : Mode -> String -> Element Msg
viewButtons mode pageId =
    let
        buttonLabel text =
            El.text text
                |> El.el [ Background.color Style.grey, El.paddingXY 20 10 ]

        newTranslation trBookId =
            Input.button
                [ width 220, height 40, Font.size 20, Background.color Style.nightBlue ]
                { onPress = Just (ClickedNewTranslation trBookId pageId)
                , label =
                    El.row [ El.height El.fill, El.paddingXY 10 0 ]
                        [ iconPlaceholder, El.text "Add Translation" |> El.el [ El.centerY ] ]
                }

        saveButton =
            Input.button []
                { onPress = Just ClickedSaveTranslation
                , label = El.el [ Background.color Style.nightBlue, El.paddingXY 20 10 ] (El.text "Save")
                }

        resetButton =
            Input.button []
                { onPress = Just ClickedResetPath, label = buttonLabel "Reset Drawing" }

        deleteButton trBookId translation =
            Input.button []
                { onPress = Just (ClickedDelete trBookId translation), label = buttonLabel "Delete Translation" }
    in
    El.row [ El.spacing 20, width 575, height 40 ]
        (case mode of
            ReadTranslations trBookId ->
                [ newTranslation trBookId ]

            EditTranslation trBookId translation ->
                [ saveButton, resetButton, deleteButton trBookId translation ]

            _ ->
                []
        )


viewTranslation : Mode -> String -> Color -> Translation -> Element Msg
viewTranslation mode text color translation =
    let
        borderColor =
            case mode of
                EditTranslation _ trans ->
                    if trans == translation then
                        El.fromRgb255 { color | alpha = 1 }

                    else
                        Style.grey

                _ ->
                    El.fromRgb255 { color | alpha = 1 }
    in
    El.row
        [ Border.color borderColor
        , Border.width 2
        , width 575
        , height 45
        , Element.Events.onClick (ClickedTranslation translation)
        ]
        [ El.el
            [ width 50, El.height El.fill, Background.color borderColor ]
            El.none
        , case mode of
            EditTranslation _ trans ->
                if trans == translation then
                    Input.multiline [ El.padding 10, Border.width 0, El.spacing 3 ]
                        { onChange = InputText
                        , text = text
                        , placeholder = Just (Input.placeholder [] (El.text "Add translation here..."))
                        , label = Input.labelHidden "Edit translation"
                        , spellcheck = True
                        }

                else
                    El.el [ El.padding 10 ] (El.text translation.text)

            _ ->
                translation.text
                    |> String.split "\n"
                    |> List.map
                        (\line ->
                            case line of
                                -- This is needed because empty lines are not respected otherwise
                                "" ->
                                    El.el [ El.paddingXY 10 0 ] (El.text " ")

                                _ ->
                                    El.paragraph [ El.paddingXY 10 0, El.spacing 3 ] [ El.text line ]
                        )
                    |> El.column [ El.paddingXY 0 10, El.spacing 2, El.width El.fill ]
        ]


viewNotes : String -> Element Msg
viewNotes notes =
    Input.multiline
        [ width 400
        , El.alignRight
        , El.height (El.minimum 150 El.fill)
        , El.alignTop
        , Element.Events.onClick ClickedNotes
        , Border.rounded 0
        ]
        { onChange = InputNotes
        , text = notes
        , placeholder =
            El.text "Use this field freely for notes, copy/pasting...\n To save and share notes, go to page 0 and click \"Save\"."
                |> Input.placeholder []
                |> Just
        , label = Input.labelHidden "Enter notes"
        , spellcheck = True
        }



-- GRAPHQL


getlanguages : Cred -> Cmd Msg
getlanguages cred =
    Api.queryRequest cred (Query.languages Types.languageSelection) GotLanguages


bookSelection : SelectionSet Book GraphQLBook.Object.Book
bookSelection =
    SelectionSet.map4 Book
        (SelectionSet.map Types.idToString GBook.id)
        GBook.title
        GBook.author
        (GBook.language Types.languageSelection)


getBook : Cred -> String -> Cmd Msg
getBook cred bookId =
    Api.queryRequest cred (Query.book { id = Id bookId } bookSelection) GotBook


translationBookSelection : SelectionSet TranslationBook GraphQLBook.Object.TranslationBook
translationBookSelection =
    let
        toZip pages =
            case List.sortBy .pageNumber pages of
                [] ->
                    Err "No pages"

                p :: ps ->
                    Ok (ZipList.new p ps)
    in
    SelectionSet.succeed TranslationBook
        |> SelectionSet.with (SelectionSet.map Types.idToString TBook.id)
        |> SelectionSet.with (TBook.book GBook.title)
        |> SelectionSet.with (TBook.book GBook.author)
        |> SelectionSet.with TBook.title
        |> SelectionSet.with TBook.author
        |> SelectionSet.with (TBook.language Types.languageSelection)
        |> SelectionSet.with TBook.translator
        |> SelectionSet.with TBook.notes
        |> SelectionSet.with (SelectionSet.mapOrFail toZip (TBook.pageTranslations pageTranslationsSelection))


pageTranslationsSelection : SelectionSet Page GraphQLBook.Object.TranslationPage
pageTranslationsSelection =
    SelectionSet.map7 Page
        (GTranslationPage.page (SelectionSet.map Types.idToString GPage.id))
        (GTranslationPage.page GPage.image)
        (GTranslationPage.page GPage.width)
        (GTranslationPage.page GPage.height)
        (GTranslationPage.page GPage.imageType)
        (GTranslationPage.page GPage.pageNumber)
        (GTranslationPage.translations translationSelection)


translationSelection : SelectionSet Translation GraphQLBook.Object.Translation
translationSelection =
    SelectionSet.map4 Translation
        (SelectionSet.map (Types.idToString >> Just) GTranslation.id)
        (SelectionSet.map Types.idToString GTranslation.pageId)
        GTranslation.text
        GTranslation.path


getTranslationBook : Cred -> Id -> Cmd Msg
getTranslationBook cred id =
    Api.queryRequest cred (Query.translationBook { id = id } translationBookSelection) (GotTranslationBook EditTranslationBook)


saveTranslationBook : Cred -> ValidTranslationBook -> Cmd Msg
saveTranslationBook cred { bookId, id, title, author, language, translator, notes } =
    let
        modifyOptional options =
            { options
                | notes = Present notes
                , id = OptionalArgument.fromMaybe (Maybe.map Id id)
            }

        translationBook =
            Mutation.createTranslationBook modifyOptional
                { author = author
                , languageId = language.id
                , bookId = Id bookId
                , title = title
                , translator = translator
                }
                (SelectionSet.map Just translationBookSelection)
    in
    Api.mutationRequest cred translationBook (GotTranslationBook ReadTranslations)


translationMutation : String -> Translation -> SelectionSet (Maybe Translation) RootMutation
translationMutation bookId { id, pageId, text, path } =
    let
        inputTranslation =
            { translation =
                { id = OptionalArgument.fromMaybe (Maybe.map Id id)
                , translationBookId = Id bookId
                , pageId = Id pageId
                , text = text
                , path = path
                }
            }
    in
    Mutation.createTranslation inputTranslation translationSelection


mutateTranslation : Cred -> String -> Translation -> (GraphQLData (Maybe Translation) -> msg) -> Cmd msg
mutateTranslation cred trBookId translation toMsg =
    Api.mutationRequest cred (translationMutation trBookId translation) toMsg


deleteTranslation : Cred -> String -> (GraphQLData (Maybe Translation) -> msg) -> Cmd msg
deleteTranslation cred id toMsg =
    Api.mutationRequest cred (Mutation.deleteTranslation { id = Id id } translationSelection) toMsg
