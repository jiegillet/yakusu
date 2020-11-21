-- module Page.Translation exposing (Model, Msg, init, subscriptions, update, view)


module Page.Translation exposing (..)

import Browser exposing (Document, UrlRequest)
import Browser.Events as Events
import Common exposing (Context)
import Dict exposing (Dict)
import Element as El exposing (Element, alpha)
import Element.Background as Background
import Element.Border as Border
import Element.Input as Input exposing (OptionState(..))
import GraphQLBook.Mutation as Mutation
import GraphQLBook.Object
import GraphQLBook.Object.Book as GBook
import GraphQLBook.Object.Page as GPage
import GraphQLBook.Object.Translation as GTranslation
import GraphQLBook.Query as Query
import GraphQLBook.Scalar exposing (Id(..))
import Graphql.Http exposing (Error)
import Graphql.Operation exposing (RootMutation, RootQuery)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Html exposing (Html)
import Json.Decode as Decode exposing (Decoder)
import RemoteData exposing (RemoteData(..))
import Svg exposing (Svg)
import Svg.Attributes as A
import Svg.Events
import Svg.Lazy
import Types exposing (Book, Page, Translation)
import ZipList exposing (ZipList)



-- MODEL


type alias Model =
    { context : Context
    , bookId : String
    , drawingState : DrawingState
    , text : String
    , blob : List Position
    , path : String
    , pages : RemoteData (Error (Maybe (ZipList Page))) (Maybe (ZipList Page))
    , mode : Mode
    }


init : Context -> ( Model, Cmd Msg )
init context =
    ( { context = context
      , bookId = "1"
      , drawingState = NotDrawing
      , text = ""
      , blob = []
      , path = ""
      , pages = Loading
      , mode = Read
      }
    , requestBook "1"
    )


type alias Page =
    { id : String
    , imageType : String
    , pageNumber : Int
    , translations : List Translation
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
    | SelectedTranslation String
    | Drawing Position


type alias Color =
    { red : Int
    , green : Int
    , blue : Int
    , alpha : Float
    }


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


mapRemoteZip : (a -> a) -> RemoteData e (Maybe (ZipList a)) -> RemoteData e (Maybe (ZipList a))
mapRemoteZip f =
    mapCurrent f
        |> Maybe.map
        |> RemoteData.map


mapCurrent : (a -> a) -> ZipList a -> ZipList a
mapCurrent f ziplist =
    ZipList.replace (f (ZipList.current ziplist)) ziplist


type Mode
    = Read
    | Edit



-- UPDATE


type Msg
    = StartedDrawing
    | Drew Bool Position
    | StoppedDrawing
    | InputText String
    | ClickedResetPath
    | ClickedNextBlob String
    | ClickedPrevPage String
    | ClickedNextPage String
    | ClickedTranslation String
    | ToggledMode Mode
    | GotBook (RemoteData (Error (Maybe (ZipList Page))) (Maybe (ZipList Page)))
    | AddedTranslation (ZipList Page -> ZipList Page) (RemoteData (Error (Maybe Types.Translation)) (Maybe Types.Translation))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartedDrawing ->
            ( { model | drawingState = Drawing { x = 0, y = 0 } }
            , Cmd.none
            )

        Drew down pos ->
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
              }
            , Cmd.none
            )

        ClickedTranslation id ->
            ( { model | drawingState = SelectedTranslation id }, Cmd.none )

        InputText text ->
            ( { model | text = text }, Cmd.none )

        ClickedResetPath ->
            ( { model | path = "" }, Cmd.none )

        ClickedNextBlob pageId ->
            if model.text == "" || model.path == "" then
                ( { model | text = "", path = "" }, Cmd.none )

            else
                ( model, saveTranslation identity model.bookId (Translation "" pageId model.text model.path) )

        ClickedPrevPage pageId ->
            if model.text == "" || model.path == "" then
                ( { model
                    | text = ""
                    , path = ""
                    , pages = RemoteData.map (Maybe.map ZipList.backward) model.pages
                  }
                , Cmd.none
                )

            else
                ( model, saveTranslation ZipList.backward model.bookId (Translation "" pageId model.text model.path) )

        ClickedNextPage pageId ->
            if model.text == "" || model.path == "" then
                ( { model
                    | text = ""
                    , path = ""
                    , pages = RemoteData.map (Maybe.map ZipList.forward) model.pages
                  }
                , Cmd.none
                )

            else
                ( model, saveTranslation ZipList.forward model.bookId (Translation "" pageId model.text model.path) )

        ToggledMode Read ->
            ( { model | mode = Read, drawingState = NotDrawing }, Cmd.none )

        ToggledMode Edit ->
            ( { model | mode = Edit }, Cmd.none )

        GotBook result ->
            ( { model | pages = result }, Cmd.none )

        AddedTranslation move result ->
            case result of
                Success (Just translation) ->
                    ( { model
                        | pages =
                            RemoteData.map
                                (Maybe.map
                                    (mapCurrent
                                        (\page -> { page | translations = translation :: page.translations })
                                        >> move
                                    )
                                )
                                model.pages
                        , text = ""
                        , path = ""
                      }
                    , Cmd.none
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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.drawingState of
        Drawing _ ->
            Sub.batch
                [ Events.onMouseMove (Decode.map2 Drew decodeButtons decodePosition)
                , Events.onMouseUp (Decode.succeed StoppedDrawing)
                ]

        _ ->
            Sub.none


decodeButtons : Decoder Bool
decodeButtons =
    Decode.field "buttons" (Decode.map (\buttons -> buttons == 1) Decode.int)


decodePosition : Decoder Position
decodePosition =
    Decode.map2 Position
        (Decode.field "pageX" Decode.int)
        (Decode.field "pageY" Decode.int)



-- (D.at ["currentTarget","defaultView","innerWidth"] Decode.int)


dictPush : a -> Dict Int a -> Dict Int a
dictPush a dict =
    Dict.keys dict
        |> List.reverse
        |> List.head
        |> Maybe.withDefault 1
        |> (\key -> Dict.insert (key + 1) a dict)



-- VIEW


view : Model -> { title : String, body : Element Msg }
view model =
    { title = "CDC Book Translation"
    , body =
        case model.pages of
            Success (Just pages) ->
                let
                    pageId =
                        .id (ZipList.current pages)
                in
                El.column [ El.spacing 5 ]
                    [ viewImage model.mode model.drawingState (ZipList.current pages) model.text model.blob model.path
                    , viewMode model.mode
                    , case model.mode of
                        Edit ->
                            viewEditMode (ZipList.current pages).translations pageId model.text

                        Read ->
                            viewReadMode (ZipList.current pages).translations
                    ]

            _ ->
                El.text "Some error has occured"
    }


viewImage : Mode -> DrawingState -> Page -> String -> List Position -> String -> Element Msg
viewImage mode drawing ({ translations } as page) text blob tempPath =
    let
        paths =
            viewPath drawing page.id yellow tempPath
                :: viewPosPath yellow blob
                :: List.map2
                    (\{ id, path } color ->
                        viewPath drawing
                            page.id
                            (if drawing == SelectedTranslation id then
                                yellow

                             else
                                toHex color
                            )
                            path
                    )
                    (List.reverse translations)
                    colors

        image pageId =
            Svg.image
                [ A.width "800"
                , A.height "800"
                , A.xlinkHref ("http://localhost:4000/api/rest/pages/" ++ pageId)
                ]
                []
    in
    Svg.svg
        [ A.width "800"
        , A.height "600"
        , A.viewBox "0 0 800 600"
        , Svg.Events.on "mousedown"
            (if mode == Edit then
                Decode.succeed StartedDrawing

             else
                Decode.fail "read mode"
            )
        ]
        (Svg.Lazy.lazy image page.id :: paths)
        |> El.html


yellow : String
yellow =
    "#FBEC5D40"


grey : String
grey =
    "#0E0E0E40"


colors : List Color
colors =
    [ Color 230 25 75 0.25, Color 60 180 75 0.25, Color 255 225 25 0.25, Color 0 130 200 0.25, Color 245 130 48 0.25, Color 145 30 180 0.25, Color 70 240 240 0.25, Color 240 50 230 0.25, Color 210 245 60 0.25, Color 250 190 212 0.25, Color 0 128 128 0.25, Color 220 190 255 0.25, Color 170 110 40 0.25, Color 255 250 200 0.25, Color 128 0 0 0.25, Color 170 255 195 0.25, Color 128 128 0 0.25, Color 255 215 180 0.25, Color 0 0 128 0.25, Color 128 128 128 0.25, Color 255 255 255 0.25, Color 0 0 0 0.25 ]


viewPosPath : String -> List Position -> Svg Msg
viewPosPath color blob =
    Svg.path
        [ blob
            |> List.reverse
            |> keepEvery 5
            |> catmullRom
            |> A.d
        , A.fill "none"
        , A.stroke color
        , A.strokeWidth "35"
        , A.strokeLinecap "round"
        ]
        []


viewPath : DrawingState -> String -> String -> String -> Svg Msg
viewPath drawing translationId color path =
    let
        event =
            case drawing of
                Drawing _ ->
                    []

                _ ->
                    [ Svg.Events.onClick (ClickedTranslation translationId) ]
    in
    Svg.path
        ([ A.d path
         , A.fill "none"
         , A.stroke color
         , A.strokeWidth "35"
         , A.strokeLinecap "round"
         ]
            ++ event
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
            in
            String.concat [ " C ", toString q1, ", ", toString q2, ", ", toString p2 ]
    in
    case points of
        [] ->
            ""

        [ _ ] ->
            ""

        p0 :: p1 :: ps ->
            pad ( p0, p1 ) (last2 p0 p1 points) points
                |> toCublicSpline
                |> (++) ("M " ++ toString p1)


viewMode : Mode -> Element Msg
viewMode mode =
    let
        selection text state =
            case state of
                Idle ->
                    El.el [ El.padding 5 ] (El.text text)

                Focused ->
                    El.el [ El.padding 5 ] (El.text text)

                Selected ->
                    El.el
                        [ Background.color (El.rgb255 255 255 255)
                        , Border.rounded 3
                        , El.padding 5
                        ]
                        (El.text text)
    in
    Input.radioRow
        [ El.padding 5
        , El.spacing 20
        , Background.color (El.rgb255 200 200 200)
        , Border.rounded 5
        ]
        { onChange = ToggledMode
        , selected = Just mode
        , label = Input.labelHidden "View mode"
        , options =
            [ Input.optionWith Read (selection "Read")
            , Input.optionWith Edit (selection "Edit")
            ]
        }
        |> El.el [ El.centerX ]


viewEditText : String -> Element Msg
viewEditText text =
    Input.multiline []
        { onChange = InputText
        , text = text
        , placeholder = Nothing
        , label = Input.labelAbove [] (El.text "Draw over a chunk of text and translate it below. If there is no text or no drawing, nothing will be saved")
        , spellcheck = True
        }


buttonLabel : String -> Element msg
buttonLabel text =
    El.text text
        |> El.el [ Background.color (El.rgb255 200 200 200), El.padding 5 ]


prevPageButton : String -> Element Msg
prevPageButton pageId =
    Input.button []
        { onPress = Just (ClickedPrevPage pageId), label = buttonLabel "Previous page" }


nextPageButton : String -> Element Msg
nextPageButton pageId =
    Input.button []
        { onPress = Just (ClickedNextPage pageId), label = buttonLabel "Next page" }


viewEditButtons : String -> Element Msg
viewEditButtons pageId =
    let
        resetButton =
            Input.button []
                { onPress = Just ClickedResetPath, label = buttonLabel "Reset drawing" }

        nextBlobButton =
            Input.button []
                { onPress = Just (ClickedNextBlob pageId), label = buttonLabel "Save Translation" }
    in
    El.column [ El.spacing 5 ]
        [ El.row [ El.spacing 5 ] [ resetButton, nextBlobButton ]
        , El.row [ El.spacing 5 ] [ prevPageButton pageId, nextPageButton pageId ]
        ]


viewReadButtons : Element Msg
viewReadButtons =
    El.row [ El.spacing 5 ] [ prevPageButton "", nextPageButton "" ]


viewTranslation : Translation -> Color -> Element msg
viewTranslation { text } color =
    El.text text
        |> El.el
            [ El.padding 5
            , Border.color (El.fromRgb255 { color | alpha = 1 })
            , Border.width 1
            ]


viewEditMode : List Translation -> String -> String -> Element Msg
viewEditMode translations pageId text =
    El.column []
        (viewEditText text
            :: viewEditButtons pageId
            :: List.map2 viewTranslation (List.reverse translations) colors
        )


viewReadMode : List Translation -> Element Msg
viewReadMode translations =
    List.map2 viewTranslation (List.reverse translations) colors
        |> (\t -> viewReadButtons :: t)
        |> El.column []



-- GRAPHQL


bookQuery : String -> SelectionSet (Maybe (ZipList Page)) RootQuery
bookQuery bookId =
    Query.book (Query.BookRequiredArguments (Id bookId)) pagesSelection


pagesSelection : SelectionSet (ZipList Page) GraphQLBook.Object.Book
pagesSelection =
    let
        toZip pages =
            case List.sortBy .pageNumber pages of
                [] ->
                    Err "No pages"

                p :: ps ->
                    Ok (ZipList.new p ps)

        toPage zipPages translations =
            let
                getTranslations ({ pageNumber, imageType } as page) =
                    translations
                        |> List.filter (\{ pageId } -> pageId == page.id)
                        |> Page page.id imageType pageNumber
            in
            ZipList.map getTranslations zipPages
    in
    SelectionSet.map2 toPage
        (SelectionSet.mapOrFail toZip (GBook.pages Types.pageSelection))
        (GBook.translations Types.translationSelection)


translationMutation : String -> Translation -> SelectionSet (Maybe Translation) RootMutation
translationMutation bookId { pageId, text, path } =
    let
        inputTranslation =
            { translation =
                { id = Absent
                , bookId = Id bookId
                , pageId = Id pageId
                , text = text
                , path = path
                }
            }
    in
    Mutation.createTranslation inputTranslation Types.translationSelection


requestBook : String -> Cmd Msg
requestBook bookId =
    bookQuery bookId
        |> Graphql.Http.queryRequest "http://localhost:4000/api"
        |> Graphql.Http.send (RemoteData.fromResult >> GotBook)


saveTranslation : (ZipList Page -> ZipList Page) -> String -> Translation -> Cmd Msg
saveTranslation move bookId translation =
    translationMutation bookId translation
        |> Graphql.Http.mutationRequest "http://localhost:4000/api"
        |> Graphql.Http.send (RemoteData.fromResult >> AddedTranslation move)
