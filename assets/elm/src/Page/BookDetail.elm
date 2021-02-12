module Page.BookDetail exposing (Model, Msg, init, update, view)

import Api exposing (Cred)
import Common exposing (Context, height, width)
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import GraphQLBook.Query as Query
import GraphQLBook.Scalar exposing (Id(..))
import Graphql.Http exposing (Error)
import Graphql.Operation exposing (RootQuery)
import Graphql.SelectionSet exposing (SelectionSet)
import Page.Books exposing (Book, BookTranslation)
import RemoteData exposing (RemoteData(..))
import Route
import Style



-- TYPES


type alias Model =
    { context : Context
    , cred : Cred
    , bookId : String
    , book : RemoteData (Error (Maybe Book)) (Maybe Book)
    , welcomeText : String
    }


init : Context -> Cred -> String -> Bool -> ( Model, Cmd Msg )
init context cred bookId isNew =
    ( { context = context
      , cred = cred
      , bookId = bookId
      , book = Loading
      , welcomeText =
            if isNew then
                "Thank you for adding a new book to Yasuku!"

            else
                "Here are the details about..."
      }
    , requestBook cred bookId
    )



-- UPDATE


type Msg
    = GotBook (RemoteData (Error (Maybe Book)) (Maybe Book))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotBook result ->
            ( { model | book = result }, Cmd.none )



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

        backRight =
            Route.link Route.Books
                [ Font.color Style.grey
                , Border.color Style.grey
                , Border.width 2
                , width 220
                ]
                (El.row [ El.paddingXY 10 5, height 40 ] [ El.text "Back to Mainpage", iconPlaceholder ])
                |> El.el [ El.paddingXY 0 25, Font.size 20, El.alignRight ]

        addMore =
            Route.link Route.AddBook
                [ Font.color Style.black
                , Background.color Style.nightBlue
                , width 220
                ]
                (El.row [ El.paddingXY 10 5, height 40 ] [ iconPlaceholder, El.text "Add a New Book" ])
                |> El.el [ El.paddingEach { left = 40, right = 0, top = 25, bottom = 0 }, Font.size 20, El.alignRight ]
    in
    { title = "Thank You"
    , body =
        case model.book of
            Success (Just book) ->
                El.column
                    [ width 1000, El.centerX ]
                    [ back
                    , El.el [ Font.size 24, El.paddingXY 40 30 ] (El.text model.welcomeText)
                    , viewBook book
                    , viewTranslations book.translations book.id
                    , addMore
                    , backRight
                    ]
                    |> El.el [ El.paddingXY 100 30 ]

            Success Nothing ->
                El.column
                    [ width 1000, El.spacing 25, El.centerX ]
                    [ back
                    , El.el [ Font.size 24, El.paddingXY 40 5 ]
                        (El.text ("There is no original book with the ID " ++ model.bookId))
                    , addMore
                    , backRight
                    ]
                    |> El.el [ El.paddingXY 100 30 ]

            _ ->
                El.text "There was a problem retrieving data."
    }


viewBook : Book -> Element msg
viewBook { id, title, author, language, category, numPages } =
    El.column [ El.paddingEach { top = 30, left = 0, right = 0, bottom = 40 }, El.spacing 20 ]
        [ El.row [ Font.size 20, El.spacing 20, height 45 ]
            [ El.row [ width 470, El.height El.fill, Background.color Style.grey, El.padding 5, El.spacing 10 ]
                [ iconPlaceholder, El.el [ El.centerY ] (El.text title) ]
            , Route.link (Route.EditBook id)
                [ Font.color Style.black
                , Border.color Style.nightBlue
                , Border.width 2
                , El.height El.fill
                ]
                (El.row [ El.height El.fill, El.paddingXY 5 0 ]
                    [ iconPlaceholder, El.text "Edit Book" |> El.el [ El.centerY, El.paddingXY 5 0, width 180 ] ]
                )
            ]
        , viewField 40 "Original language" language.language
        , viewField 40 "Author" author
        , viewField 40 "Theme" category.name
        , viewField 40 "Pages" (String.fromInt numPages)
        ]


viewTranslations : List BookTranslation -> String -> Element msg
viewTranslations books bookId =
    let
        addTranslation =
            Route.link (Route.AddTranslation bookId)
                [ Font.color Style.black
                , Border.color Style.nightBlue
                , Border.width 2
                , El.alignRight
                , width 220
                , Font.size 20
                , El.height El.fill
                ]
                (El.row [ El.height El.fill, El.paddingXY 5 0 ]
                    [ iconPlaceholder, El.text "Add Translation" |> El.el [ El.centerY, El.paddingXY 5 0, width 180 ] ]
                )
    in
    El.column [ El.spacing 20 ]
        (El.row [ Font.size 20, El.spacing 20, height 45 ]
            [ El.row [ width 470, El.height El.fill, Background.color Style.grey, El.padding 5, El.spacing 10 ]
                [ iconPlaceholder, El.el [ El.centerY ] (El.text "Translations") ]
            , addTranslation
            ]
            :: List.map
                (\{ id, language, title } ->
                    El.row []
                        [ Route.link (Route.Translation id) [] iconPlaceholder
                        , viewField 5 language.language title
                        ]
                )
                books
        )


viewField : Int -> String -> String -> Element msg
viewField offset description value =
    El.row
        [ El.paddingEach { top = 0, left = offset, right = 0, bottom = 0 }
        , width 160
        , El.spacing 20
        , Font.size 18
        ]
        [ El.el [ Background.color Style.grey, El.centerY, width 160, El.padding 5 ] (El.text description)
        , El.el [ El.centerY ] (El.text value)
        ]



-- GRAPHQL


bookQuery : String -> SelectionSet (Maybe Book) RootQuery
bookQuery bookId =
    Query.book (Query.BookRequiredArguments (Id bookId)) Page.Books.bookSelection


requestBook : Cred -> String -> Cmd Msg
requestBook cred bookId =
    Api.queryRequest cred (bookQuery bookId) GotBook
