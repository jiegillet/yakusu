module Page.Translation exposing (Model, Msg, init, subscriptions, update, view)

import Browser exposing (Document, UrlRequest)
import Browser.Events as Events
import Common exposing (Context)
import Dict exposing (Dict)
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Input as Input exposing (OptionState(..))
import GraphQLBook.Object
import GraphQLBook.Object.Book as GBook
import GraphQLBook.Object.Page as GPage
import GraphQLBook.Object.Position as GPosition
import GraphQLBook.Object.Translation as GTranslation
import GraphQLBook.Query as Query
import GraphQLBook.Scalar exposing (Id(..))
import Graphql.Http exposing (Error)
import Graphql.Operation exposing (RootQuery)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Html exposing (Html)
import Json.Decode as Decode exposing (Decoder)
import RemoteData exposing (RemoteData(..))
import Svg exposing (Svg)
import Svg.Attributes as A
import Svg.Events
import Types exposing (Book, Page, Position, Translation)
import ZipList exposing (ZipList)



-- MODEL


type alias Model =
    { context : Context
    , drawingState : DrawingState
    , text : String
    , blobBuffer : List Position
    , blob : Dict Int (List Position)
    , selectedTranslation : Maybe Translation
    , pages : RemoteData (Error (Maybe (ZipList Page))) (Maybe (ZipList Page))
    , mode : Mode
    }


init : Context -> ( Model, Cmd Msg )
init context =
    ( { context = context
      , drawingState = NotDrawing
      , text = ""
      , blobBuffer = []
      , blob = Dict.empty
      , selectedTranslation = Nothing
      , pages = Loading
      , mode = Read
      }
    , requestBook
    )


type alias Page =
    { id : String
    , imageType : String
    , pageNumber : Int
    , translations : List Translation
    }


type alias Translation =
    { id : Maybe String
    , pageId : String
    , text : String
    , blob : Dict Int (List Position)
    }


type alias Position =
    { x : Int
    , y : Int
    }


type DrawingState
    = NotDrawing
    | Drawing Position


mapRemote :
    (a -> a)
    -> RemoteData (Error e) (Maybe a)
    -> RemoteData (Error e) (Maybe a)
mapRemote =
    Maybe.map
        >> RemoteData.map


mapCurrent : (a -> a) -> ZipList a -> ZipList a
mapCurrent f ziplist =
    ZipList.replace (f (ZipList.current ziplist)) ziplist


insertTranslation : String -> Dict Int (List Position) -> Page -> Page
insertTranslation text blob page =
    { page | translations = Translation Nothing page.id text blob :: page.translations }


type Mode
    = Read
    | Edit



-- UPDATE


type Msg
    = StartedDrawing
    | Drew Bool Position
    | StoppedDrawing
    | InputText String
    | ClickedResetBlob
    | ClickedNextBlob
    | ClickedPrevPage
    | ClickedNextPage
    | ClickedTranslation Translation
    | ToggledMode Mode
    | GotBook (RemoteData (Error (Maybe (ZipList Page))) (Maybe (ZipList Page)))


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
                , blobBuffer = pos :: model.blobBuffer
              }
            , Cmd.none
            )

        StoppedDrawing ->
            ( { model
                | drawingState = NotDrawing
                , blobBuffer = []
                , blob = dictPush model.blobBuffer model.blob
              }
            , Cmd.none
            )

        InputText text ->
            ( { model | text = text }, Cmd.none )

        ClickedResetBlob ->
            ( { model | blob = Dict.empty, blobBuffer = [] }, Cmd.none )

        ClickedNextBlob ->
            ( { model
                | text = ""
                , blob = Dict.empty
                , blobBuffer = []
                , pages = mapRemote (mapCurrent (insertTranslation model.text model.blob)) model.pages
              }
            , Cmd.none
            )

        ClickedPrevPage ->
            ( { model
                | text = ""
                , blob = Dict.empty
                , blobBuffer = []
                , pages =
                    mapRemote
                        (mapCurrent (insertTranslation model.text model.blob)
                            >> ZipList.backward
                        )
                        model.pages
              }
            , Cmd.none
            )

        ClickedNextPage ->
            ( { model
                | text = ""
                , blob = Dict.empty
                , blobBuffer = []
                , pages =
                    mapRemote
                        (mapCurrent (insertTranslation model.text model.blob)
                            >> ZipList.forward
                        )
                        model.pages
              }
            , Cmd.none
            )

        ClickedTranslation translation ->
            ( { model | selectedTranslation = Just translation }, Cmd.none )

        ToggledMode Read ->
            ( { model | mode = Read, selectedTranslation = Nothing }, Cmd.none )

        ToggledMode Edit ->
            ( { model | mode = Edit }, Cmd.none )

        GotBook result ->
            ( { model | pages = result }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.drawingState of
        Drawing _ ->
            Sub.batch
                [ Events.onMouseMove (Decode.map2 Drew decodeButtons decodePosition)
                , Events.onMouseUp (Decode.succeed StoppedDrawing)
                ]

        NotDrawing ->
            Sub.none


decodeButtons : Decoder Bool
decodeButtons =
    Decode.field "buttons" (Decode.map (\buttons -> buttons == 1) Decode.int)


decodePosition : Decoder Position
decodePosition =
    Decode.map2 Position
        (Decode.field "pageX" Decode.int)
        (Decode.field "pageY" Decode.int)



-- (D.at ["currentTarget","defaultView","innerWidth"] D.float)


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
                El.column [ El.spacing 5 ]
                    [ viewImage (ZipList.current pages) model.blobBuffer model.text model.blob model.mode
                    , viewMode model.mode
                    , case model.mode of
                        Edit ->
                            viewEditMode model.text

                        Read ->
                            viewReadMode (ZipList.current pages).translations
                    ]

            _ ->
                El.text "Some error has occured"
    }


viewImage : Page -> List Position -> String -> Dict Int (List Position) -> Mode -> Element Msg
viewImage { id, translations } blobBuffer text blob mode =
    let
        paths =
            viewPath mode yellow (Translation Nothing "" "" (Dict.singleton 1 blobBuffer))
                ++ viewPath mode yellow (Translation Nothing "" text blob)
                ++ List.concatMap (viewPath mode grey) translations
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
        (Svg.image [ A.width "800", A.height "600", A.xlinkHref ("http://localhost:4000/api/rest/pages/" ++ id) ] []
            :: paths
        )
        |> El.html


yellow : String
yellow =
    "#FBEC5D40"


grey : String
grey =
    "#0E0E0E40"


viewPath : Mode -> String -> Translation -> List (Svg Msg)
viewPath mode color translation =
    let
        toString { x, y } =
            String.fromInt x ++ "," ++ String.fromInt y

        toSvg blobBuffer =
            blobBuffer
                |> List.map toString
                |> String.join " "
                |> (\pos ->
                        Svg.polyline
                            [ A.points pos
                            , A.fill "none"
                            , A.stroke color
                            , A.strokeWidth "35"
                            , A.strokeLinecap "round"
                            , Svg.Events.onClick (ClickedTranslation translation)
                            ]
                            []
                   )
    in
    translation.blob
        |> Dict.values
        |> List.map toSvg


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
        , label = Input.labelAbove [] (El.text "Draw a blob over some text and translate it below")
        , spellcheck = True
        }


label : String -> Element msg
label text =
    El.text text
        |> El.el [ Background.color (El.rgb255 200 200 200), El.padding 5 ]


prevPageButton : Element Msg
prevPageButton =
    Input.button []
        { onPress = Just ClickedPrevPage, label = label "Previous page" }


nextPageButton : Element Msg
nextPageButton =
    Input.button []
        { onPress = Just ClickedNextPage, label = label "Next page" }


viewEditButtons : Element Msg
viewEditButtons =
    let
        resetButton =
            Input.button []
                { onPress = Just ClickedResetBlob, label = label "Reset blob" }

        nextBlobButton =
            Input.button []
                { onPress = Just ClickedNextBlob, label = label "Save blob" }
    in
    El.column [ El.spacing 5 ]
        [ El.row [ El.spacing 5 ] [ resetButton, nextBlobButton ]
        , El.row [ El.spacing 5 ] [ prevPageButton, nextPageButton ]
        ]


viewReadButtons : Element Msg
viewReadButtons =
    El.row [ El.spacing 5 ] [ prevPageButton, nextPageButton ]


viewEditMode : String -> Element Msg
viewEditMode text =
    El.column []
        [ viewEditText text
        , viewEditButtons
        ]


viewReadMode : List Translation -> Element Msg
viewReadMode translations =
    let
        viewTranslation { text } =
            El.text text
                |> El.el
                    [ El.padding 5
                    , Border.color (El.rgb255 200 200 200)
                    , Border.width 1
                    ]
    in
    List.map viewTranslation translations
        |> (\t -> t ++ [ viewReadButtons ])
        |> El.column []



-- GRAPHQL


bookQuery : SelectionSet (Maybe (ZipList Page)) RootQuery
bookQuery =
    Query.book (Query.BookRequiredArguments (Id "1")) pagesSelection


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
                toPosition =
                    Dict.map (\_ -> List.map (\{ x, y } -> Position x y))

                getTranslations ({ pageNumber, imageType } as page) =
                    translations
                        |> List.filter (\{ pageId } -> pageId == page.id)
                        |> List.map (\{ id, pageId, text, blob } -> Translation (Just id) pageId text (toPosition blob))
                        |> Page page.id imageType pageNumber
            in
            ZipList.map getTranslations zipPages
    in
    SelectionSet.map2 toPage
        (SelectionSet.mapOrFail toZip (GBook.pages Types.pageSelection))
        (GBook.translations Types.translationSelection)


requestBook : Cmd Msg
requestBook =
    bookQuery
        |> Graphql.Http.queryRequest "http://localhost:4000/api"
        |> Graphql.Http.send (RemoteData.fromResult >> GotBook)
