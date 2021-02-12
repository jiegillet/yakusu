module Page.Translation exposing (Model, Msg, init, subscriptions, update, view)

import Api exposing (Cred)
import Browser.Events
import Common exposing (Context, height, width)
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events
import Element.Font as Font
import Element.Input as Input exposing (OptionState(..))
import GraphQLBook.Mutation as Mutation
import GraphQLBook.Object
import GraphQLBook.Object.Book as GBook
import GraphQLBook.Object.TranslationBook as TBook
import GraphQLBook.Query as Query
import GraphQLBook.Scalar exposing (Id(..))
import Graphql.Http exposing (Error)
import Graphql.Operation exposing (RootMutation, RootQuery)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Json.Decode as Decode exposing (Decoder)
import List.Extra as List
import RemoteData exposing (RemoteData(..))
import Route
import Style
import Svg exposing (Svg)
import Svg.Attributes as A
import Svg.Events
import Types exposing (Page, Translation)
import ZipList exposing (ZipList)



-- MODEL


type alias Model =
    { context : Context
    , cred : Cred
    , bookId : String
    , drawingState : DrawingState
    , text : String
    , blob : List Position
    , path : String
    , pages : RemoteData (Error (Maybe (ZipList Page))) (Maybe (ZipList Page))
    , mode : Mode
    , editModeState : FocusState
    , notes : String
    , notesInputState : FocusState
    }


init : Context -> Cred -> String -> ( Model, Cmd Msg )
init context cred bookId =
    ( { context = context
      , cred = cred
      , bookId = bookId
      , drawingState = NotDrawing
      , text = ""
      , blob = []
      , path = ""
      , pages = Loading
      , mode = Read
      , editModeState = Inactive
      , notes = ""
      , notesInputState = Inactive
      }
    , requestBook cred bookId
    )


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


type Mode
    = Read
    | Edit Translation


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


mapRemoteMaybe : (a -> a) -> RemoteData e (Maybe a) -> RemoteData e (Maybe a)
mapRemoteMaybe =
    Maybe.map
        >> RemoteData.map


mapCurrent : (a -> a) -> ZipList a -> ZipList a
mapCurrent f ziplist =
    ZipList.replace (f (ZipList.current ziplist)) ziplist



-- UPDATE


type Msg
    = StartedDrawing
    | Drew Bool Position
    | StoppedDrawing
    | InputText String
    | ClickedNotes
    | InputNotes String
    | ClickedResetPath
    | ClickedNewTranslation String
    | ClickedPrevPage
    | ClickedNextPage
    | PressedKey Key
    | ClickedSave
    | ClickedTranslation Translation
    | ClickedSomewhereOnPage
    | ClickedDelete Translation
    | GotBook (RemoteData (Error (Maybe (ZipList Page))) (Maybe (ZipList Page)))
    | AddedTranslation (ZipList Page -> ZipList Page) (RemoteData (Error (Maybe Translation)) (Maybe Translation))
    | EditedTranslation (ZipList Page -> ZipList Page) (RemoteData (Error (Maybe Translation)) (Maybe Translation))
    | DeletedTranslation (RemoteData (Error (Maybe Translation)) (Maybe Translation))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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

        InputNotes text ->
            ( { model | notes = text }, Cmd.none )

        ClickedTranslation ({ text, path } as translation) ->
            let
                clickedModel =
                    { model | editModeState = Clicked }
            in
            case model.mode of
                Edit trans ->
                    if trans == translation then
                        ( clickedModel, Cmd.none )

                    else
                        ( { clickedModel | mode = Edit translation, text = text, path = path }
                        , mutateTranslation model.cred
                            model.bookId
                            { trans | text = model.text, path = model.path }
                            (case trans.id of
                                Nothing ->
                                    AddedTranslation identity

                                Just _ ->
                                    EditedTranslation identity
                            )
                        )

                Read ->
                    ( { clickedModel | mode = Edit translation, text = text, path = path }
                    , Cmd.none
                    )

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
                    saveTranslationAndMove newModel identity

                _ ->
                    ( newModel, Cmd.none )

        ClickedDelete translation ->
            case translation.id of
                Nothing ->
                    ( { model | mode = Read, text = "", blob = [], path = "" }, Cmd.none )

                Just id ->
                    ( model, deleteTranslation model.cred id )

        ClickedResetPath ->
            ( { model | path = "", editModeState = Clicked }, Cmd.none )

        ClickedNewTranslation pageId ->
            saveTranslationAndMove
                { model
                    | mode = Edit (Translation Nothing pageId model.text model.path)
                    , editModeState = Clicked
                }
                identity

        ClickedPrevPage ->
            saveTranslationAndMove model ZipList.backward

        ClickedNextPage ->
            saveTranslationAndMove model ZipList.forward

        ClickedSave ->
            saveTranslationAndMove model identity

        PressedKey key ->
            case key of
                Left ->
                    saveTranslationAndMove model ZipList.backward

                Right ->
                    saveTranslationAndMove model ZipList.forward

                Other ->
                    ( model, Cmd.none )

        GotBook result ->
            ( { model | pages = result }, Cmd.none )

        AddedTranslation move result ->
            case result of
                Success (Just translation) ->
                    ( { model
                        | pages =
                            mapRemoteMaybe
                                (mapCurrent
                                    (\page -> { page | translations = page.translations ++ [ translation ] })
                                    >> move
                                )
                                model.pages
                        , text = ""
                        , path = ""
                        , mode = Edit translation
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        EditedTranslation move result ->
            case result of
                Success (Just translation) ->
                    ( { model
                        | pages =
                            mapRemoteMaybe
                                (mapCurrent
                                    (\page -> { page | translations = List.map (replace translation) page.translations })
                                    >> move
                                )
                                model.pages
                        , text = ""
                        , path = ""
                        , mode = Read
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        DeletedTranslation result ->
            case result of
                Success (Just translation) ->
                    ( { model
                        | pages =
                            mapRemoteMaybe
                                (mapCurrent
                                    (\page -> { page | translations = List.filter ((/=) translation) page.translations })
                                )
                                model.pages
                        , text = ""
                        , path = ""
                        , mode = Read
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )


saveTranslationAndMove : Model -> (ZipList Page -> ZipList Page) -> ( Model, Cmd Msg )
saveTranslationAndMove model move =
    case model.mode of
        Read ->
            ( { model | pages = mapRemoteMaybe move model.pages }, Cmd.none )

        Edit translation ->
            ( model
            , mutateTranslation model.cred
                model.bookId
                { translation | text = model.text, path = model.path }
                (case translation.id of
                    Nothing ->
                        AddedTranslation move

                    Just _ ->
                        EditedTranslation move
                )
            )


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
    case ( model.drawingState, model.mode, model.notesInputState ) of
        ( Drawing _, _, _ ) ->
            Sub.batch
                [ Browser.Events.onMouseMove (Decode.map2 Drew decodeButtons decodePosition)
                , Browser.Events.onMouseUp (Decode.succeed StoppedDrawing)
                ]

        ( NotDrawing, Read, Inactive ) ->
            Browser.Events.onKeyDown (Decode.map PressedKey keyDecoder)

        _ ->
            Browser.Events.onClick (Decode.succeed ClickedSomewhereOnPage)


decodeButtons : Decoder Bool
decodeButtons =
    Decode.field "buttons" (Decode.map (\buttons -> buttons == 1) Decode.int)


decodePosition : Decoder Position
decodePosition =
    let
        offset =
            { x = 240, y = 215 }
    in
    Decode.map2 Position
        (Decode.field "pageX" Decode.int |> Decode.map (\n -> n - offset.x))
        -- (Decode.at [ "currentTarget", "defaultView", "innerWidth" ] Decode.int |> Decode.map (\n -> n - 100))
        (Decode.field "pageY" Decode.int |> Decode.map (\n -> n - offset.y))



-- VIEW


iconPlaceholder : Element msg
iconPlaceholder =
    El.el [ width 25, height 25, Background.color Style.morningBlue ] El.none
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
    in
    { title = "Translation"
    , body =
        case model.pages of
            Success (Just pages) ->
                El.column
                    [ El.spacing 25
                    , El.paddingXY 20 50
                    , width 1000
                    , El.centerX
                    ]
                    [ back
                    , El.row []
                        [ El.column []
                            [ ZipList.current pages
                                |> .pageNumber
                                |> (+) 1
                                |> String.fromInt
                                |> El.text
                                |> El.el [ El.centerX, El.centerY, Font.color Style.white, Font.size 18 ]
                                |> El.el [ El.alignRight, width 40, height 40, Background.color Style.nightBlue ]
                                |> El.el [ El.paddingEach { top = 0, bottom = 200, right = 0, left = 0 } ]
                            , El.el [ Element.Events.onClick ClickedPrevPage ] iconPlaceholder
                            , El.el [ height 240 ] El.none
                            ]
                        , viewImage model.mode (ZipList.current pages) model.blob model.path
                        , El.el [ Element.Events.onClick ClickedNextPage, El.padding 10 ]
                            (if not (ZipList.currentIndex pages == ZipList.length pages - 1) then
                                iconPlaceholder

                             else
                                El.none
                            )
                        ]
                    , El.row [ El.spacing 25, width 960 ]
                        [ El.column [ El.spacing 25, El.alignTop ]
                            [ viewButtons model.mode (ZipList.current pages).id
                            , ZipList.current pages
                                |> .translations
                                |> List.map2 (viewTranslation model.mode model.text) colors
                                |> El.column
                                    [ El.spacing 20
                                    , El.paddingEach { left = 40, right = 0, bottom = 0, top = 0 }
                                    , El.alignTop
                                    ]
                            ]
                        , viewNotes model.notes
                        ]
                    ]

            _ ->
                El.none
    }


viewImage : Mode -> Page -> List Position -> String -> Element Msg
viewImage mode { translations, image } blob tempPath =
    let
        paths =
            case mode of
                Read ->
                    List.map2 (viewPath mode) colors translations

                Edit translation ->
                    let
                        pathColor =
                            List.elemIndex translation translations
                                |> Maybe.andThen (\i -> List.getAt i colors)
                                |> Maybe.withDefault yellow
                    in
                    [ viewPath mode pathColor (Translation Nothing "" "" tempPath), viewPosPath pathColor blob ]
    in
    Svg.svg
        [ A.width "920"
        , A.height "600"
        , A.viewBox "0 0 920 600"
        , Svg.Events.on "mousedown"
            (if mode == Read then
                Decode.fail "read mode"

             else
                Decode.succeed StartedDrawing
            )
        ]
        -- Svg.rect [ A.width "920", A.height "600", A.stroke "rgb(61, 152, 255)", A.strokeWidth "2", A.fill "none" ] []
        (Svg.image [ A.width "920", A.height "600", A.xlinkHref image ] [] :: paths)
        |> El.html
        |> El.el [ Border.color Style.nightBlue, Border.width 2 ]


yellow : Color
yellow =
    Color 251 236 93 0.25


colors : List Color
colors =
    [ Color 230 25 75 0.25, Color 60 180 75 0.25, Color 255 225 25 0.25, Color 0 130 200 0.25, Color 245 130 48 0.25, Color 145 30 180 0.25, Color 70 240 240 0.25, Color 240 50 230 0.25, Color 210 245 60 0.25, Color 250 190 212 0.25, Color 0 128 128 0.25, Color 220 190 255 0.25, Color 170 110 40 0.25, Color 255 250 200 0.25, Color 128 0 0 0.25, Color 170 255 195 0.25, Color 128 128 0 0.25, Color 255 215 180 0.25, Color 0 0 128 0.25, Color 128 128 128 0.25, Color 255 255 255 0.25, Color 0 0 0 0.25 ]


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
            ++ (if mode == Read then
                    [ Svg.Events.onClick (ClickedTranslation translation) ]

                else
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

        newTranslation =
            Input.button
                [ Font.color Style.black
                , Background.color Style.nightBlue
                , width 220
                , El.paddingXY 20 10
                , Font.size 20
                ]
                { onPress = Just (ClickedNewTranslation pageId)
                , label =
                    El.row [ El.height El.fill, El.paddingXY 10 0 ]
                        [ iconPlaceholder, El.text "Add Translation" |> El.el [ El.centerY ] ]
                }

        saveButton =
            Input.button []
                { onPress = Just ClickedSave
                , label = El.el [ Background.color Style.nightBlue, El.paddingXY 20 10 ] (El.text "Save")
                }

        resetButton =
            Input.button []
                { onPress = Just ClickedResetPath, label = buttonLabel "Reset Drawing" }

        deleteButton translation =
            Input.button []
                { onPress = Just (ClickedDelete translation), label = buttonLabel "Delete Translation" }
    in
    El.row [ El.spacing 10, El.paddingEach { left = 40, right = 0, bottom = 0, top = 0 }, height 45 ]
        (case mode of
            Read ->
                [ newTranslation ]

            Edit translation ->
                [ saveButton, resetButton, deleteButton translation ]
        )


viewTranslation : Mode -> String -> Color -> Translation -> Element Msg
viewTranslation mode text color translation =
    let
        borderColor =
            case mode of
                Edit trans ->
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
        , width 600
        , Element.Events.onClick (ClickedTranslation translation)
        ]
        [ El.el
            [ width 50, El.height El.fill, Background.color borderColor ]
            El.none
        , if mode == Edit translation then
            Input.multiline [ El.padding 10, Border.width 0, El.spacing 1 ]
                { onChange = InputText
                , text = text
                , placeholder = Just (Input.placeholder [] (El.text "Add translation here..."))
                , label = Input.labelHidden "Edit translation"
                , spellcheck = True
                }

          else
            El.el [ El.padding 10 ] (El.text translation.text)
        ]


viewNotes : String -> Element Msg
viewNotes notes =
    Input.multiline
        [ width 290
        , El.alignRight
        , El.height (El.minimum 300 El.fill)
        , El.alignTop
        , Element.Events.onClick ClickedNotes
        ]
        { onChange = InputNotes
        , text = notes
        , placeholder =
            El.text "Use this field freely (notes, copy/pasting...)"
                |> Input.placeholder []
                |> Just
        , label = Input.labelHidden "Enter notes"
        , spellcheck = True
        }



-- GRAPHQL


bookQuery : String -> SelectionSet (Maybe (ZipList Page)) RootQuery
bookQuery bookId =
    Query.translationBook (Query.TranslationBookRequiredArguments (Id bookId)) pagesSelection


pagesSelection : SelectionSet (ZipList Page) GraphQLBook.Object.TranslationBook
pagesSelection =
    let
        -- TODO: do it all in one query
        toZip pages =
            case List.sortBy .pageNumber pages of
                [] ->
                    Err "No pages"

                p :: ps ->
                    Ok (ZipList.new p ps)

        toPage zipPages translations =
            let
                getTranslations ({ pageNumber, imageType, image, width, height } as page) =
                    translations
                        |> List.filter (\{ pageId } -> pageId == page.id)
                        |> Page page.id image width height imageType pageNumber
            in
            ZipList.map getTranslations zipPages
    in
    SelectionSet.map2 toPage
        (SelectionSet.mapOrFail toZip (TBook.book (GBook.pages Types.pageSelection)))
        (TBook.translations translationSelection)


translationSelection : SelectionSet Translation GraphQLBook.Object.Translation
translationSelection =
    SelectionSet.map
        (\{ id, pageId, text, path } -> Translation (Just id) pageId text path)
        Types.translationSelection


translationMutation : String -> Translation -> SelectionSet (Maybe Translation) RootMutation
translationMutation bookId { id, pageId, text, path } =
    let
        inputTranslation =
            { translation =
                { id = Graphql.OptionalArgument.fromMaybe (Maybe.map Id id)
                , translationBookId = Id bookId
                , pageId = Id pageId
                , text = text
                , path = path
                }
            }
    in
    Mutation.createTranslation inputTranslation translationSelection


requestBook : Cred -> String -> Cmd Msg
requestBook cred bookId =
    Api.queryRequest cred (bookQuery bookId) GotBook


mutateTranslation : Cred -> String -> Translation -> (RemoteData (Error (Maybe Translation)) (Maybe Translation) -> msg) -> Cmd msg
mutateTranslation cred bookId translation toMsg =
    Api.mutationRequest cred (translationMutation bookId translation) toMsg


deleteTranslation : Cred -> String -> Cmd Msg
deleteTranslation cred id =
    Api.mutationRequest cred (Mutation.deleteTranslation { id = Id id } translationSelection) DeletedTranslation
