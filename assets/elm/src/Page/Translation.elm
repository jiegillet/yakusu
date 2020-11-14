module Page.Translation exposing (Model, Msg, init, subscriptions, update, view)

import Browser exposing (Document, UrlRequest)
import Browser.Events as Events
import Common exposing (Context)
import Dict exposing (Dict)
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Input as Input exposing (OptionState(..))
import Html exposing (Html)
import Json.Decode as Decode exposing (Decoder)
import Svg exposing (Svg)
import Svg.Attributes as A
import Svg.Events
import Types exposing (Book, Page, Position)
import ZipList exposing (ZipList)



-- MODEL


type alias Model =
    { context : Context
    , drawingState : DrawingState
    , positions : List Position
    , translation : Translation
    , pages : ZipList Page
    , mode : Mode
    }


type alias Translation =
    { text : String
    , blob : Dict Int (List Position)
    }


type alias Page =
    { id : Int
    , image : String
    , imageType : String
    , translations : Dict Int Translation
    }


type alias Position =
    { x : Int
    , y : Int
    }


init : Context -> ( Model, Cmd Msg )
init context =
    ( { context = context
      , drawingState = NotDrawing
      , positions = []
      , translation = emptyTranslation
      , pages = testPages
      , mode = Read
      }
    , Cmd.none
    )


type DrawingState
    = NotDrawing
    | Drawing Position


emptyTranslation : Translation
emptyTranslation =
    Translation "" Dict.empty


mapCurrent : (a -> a) -> ZipList a -> ZipList a
mapCurrent f ziplist =
    ZipList.replace (f (ZipList.current ziplist)) ziplist


insertTranslation : Translation -> Page -> Page
insertTranslation translation page =
    { page | translations = dictPush translation page.translations }


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
                , positions = pos :: model.positions
              }
            , Cmd.none
            )

        StoppedDrawing ->
            let
                translation =
                    model.translation
            in
            ( { model
                | drawingState = NotDrawing
                , positions = []
                , translation =
                    { translation | blob = dictPush model.positions translation.blob }
              }
            , Cmd.none
            )

        InputText text ->
            let
                translation =
                    model.translation
            in
            ( { model
                | translation =
                    { translation | text = text }
              }
            , Cmd.none
            )

        ClickedResetBlob ->
            let
                translation =
                    model.translation
            in
            ( { model
                | translation =
                    { translation | blob = Dict.empty }
                , positions = []
              }
            , Cmd.none
            )

        ClickedNextBlob ->
            ( { model
                | translation = emptyTranslation
                , positions = []
                , pages = mapCurrent (insertTranslation model.translation) model.pages
              }
            , Cmd.none
            )

        ClickedPrevPage ->
            ( { model
                | translation = emptyTranslation
                , positions = []
                , pages =
                    model.pages
                        |> mapCurrent (insertTranslation model.translation)
                        |> ZipList.backward
              }
            , Cmd.none
            )

        ClickedNextPage ->
            ( { model
                | translation = emptyTranslation
                , positions = []
                , pages =
                    model.pages
                        |> mapCurrent (insertTranslation model.translation)
                        |> ZipList.forward
              }
            , Cmd.none
            )

        ClickedTranslation translation ->
            ( { model | translation = translation }, Cmd.none )

        ToggledMode Read ->
            ( { model | mode = Read }, Cmd.none )

        ToggledMode Edit ->
            ( { model | mode = Edit }, Cmd.none )



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
        El.column [ El.spacing 5 ]
            [ viewImage (ZipList.current model.pages) model.positions model.translation model.mode
            , viewMode model.mode
            , case model.mode of
                Edit ->
                    viewEditMode model.translation

                Read ->
                    viewReadMode model.translation
            ]
    }


viewImage : Page -> List Position -> Translation -> Mode -> Element Msg
viewImage { image, translations } positions translation mode =
    let
        paths =
            viewPath mode yellow (Translation "" (Dict.singleton 1 positions))
                ++ viewPath mode yellow translation
                ++ List.concatMap (viewPath mode grey) (Dict.values translations)
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
        (Svg.image [ A.width "800", A.height "600", A.xlinkHref image ] []
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

        toSvg positions =
            positions
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


viewEditText : Translation -> Element Msg
viewEditText translation =
    Input.multiline []
        { onChange = InputText
        , text = translation.text
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


viewEditMode : Translation -> Element Msg
viewEditMode translation =
    El.column []
        [ viewEditText translation
        , viewEditButtons
        ]


viewReadMode : Translation -> Element Msg
viewReadMode translation =
    El.column []
        [ translation.text
            |> El.text
            |> El.el
                [ El.padding 5
                , Border.color (El.rgb255 200 200 200)
                , Border.width 1
                ]
        , viewReadButtons
        ]



-- TEST DATA


testPages : ZipList Page
testPages =
    ZipList.new
        (Page 1 "http://localhost:4000/images/IMG_7667_blur.jpg" "" Dict.empty)
        [ Page 2 "http://localhost:4000/images/IMG_7668_blur.jpg" "" Dict.empty
        ]
