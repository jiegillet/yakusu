module Page.Books exposing (Model, Msg, init, update, view)

import Common exposing (Context)
import Element as El exposing (Element, column)
import Element.Background as Background
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import GraphQLBook.Object
import GraphQLBook.Object.Book as GBook exposing (category, id, language)
import GraphQLBook.Query as Query
import GraphQLBook.Scalar exposing (Id)
import Graphql.Http exposing (Error)
import Graphql.Operation exposing (RootQuery)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import RemoteData exposing (RemoteData(..))
import Route
import Style
import Types exposing (Category)



-- TYPES


type alias Book =
    { id : Id
    , title : String
    , author : String
    , language : String
    , category : Category
    , translations : List BookTranslation
    }


type alias BookTranslation =
    { id : Id
    , title : String
    , author : String
    , language : String
    , translator : String
    }


type alias Model =
    { context : Context
    , books : RemoteData (Error (List Book)) (List Book)
    , categories : RemoteData (Error (List Category)) (List Category)
    , checkedCategories : List Category
    , tableOrdering : ( Column, Ordering )
    }


init : Context -> ( Model, Cmd Msg )
init context =
    ( { context = context
      , books = Loading
      , categories = Loading
      , checkedCategories = []
      , tableOrdering = ( Title, Ascending )
      }
    , Cmd.batch [ requestBooks, requestCategories ]
    )


type Ordering
    = Ascending
    | Descending


flip : Ordering -> Ordering
flip ordering =
    case ordering of
        Ascending ->
            Descending

        Descending ->
            Ascending


type Column
    = Title
    | Author
    | Language
    | AvailableTranslation
    | NeededTranslation
    | Topic



-- UPDATE


type Msg
    = GotBooks (RemoteData (Error (List Book)) (List Book))
    | GotCategories (RemoteData (Error (List Category)) (List Category))
    | CheckedTopic Category Bool
    | ClickedOrder Column


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        GotBooks response ->
            ( { model | books = response }, Cmd.none )

        GotCategories response ->
            ( { model | categories = response }, Cmd.none )

        CheckedTopic category checked ->
            ( { model
                | checkedCategories =
                    if checked then
                        category :: model.checkedCategories

                    else
                        List.filter ((/=) category) model.checkedCategories
              }
            , Cmd.none
            )

        ClickedOrder column ->
            let
                ( currentColumn, ord ) =
                    model.tableOrdering
            in
            ( { model
                | tableOrdering =
                    if column == currentColumn then
                        ( column, flip ord )

                    else
                        ( column, Ascending )
              }
            , Cmd.none
            )



-- VIEW


width : Int -> El.Attribute msg
width =
    El.px >> El.width


height : Int -> El.Attribute msg
height =
    El.px >> El.height


iconPlaceholder : Element msg
iconPlaceholder =
    El.el [ width 25, height 25, Background.color Style.nightBlue ] El.none
        |> El.el [ El.padding 5 ]


view : Model -> { title : String, body : Element Msg }
view model =
    { title = "List of Books"
    , body =
        (case ( model.books, model.categories ) of
            ( Success books, Success categories ) ->
                El.column
                    [ El.spacing 25
                    , El.paddingXY 20 50
                    , width 1000
                    , El.height El.fill
                    , El.centerX
                    ]
                    [ El.paragraph [ Font.size 24, El.paddingXY 0 30 ]
                        [ El.text "Welcome to "
                        , El.text "Yakusu" |> El.el [ Font.bold ]
                        ]
                    , El.row [ El.spacing 10, Font.size 20 ]
                        [ El.row [ Background.color Style.grey, width 470, height 45 ]
                            [ iconPlaceholder
                            , El.text "List of available Books"
                            ]
                        , Route.link Route.AddBook
                            [ Background.color Style.nightBlue
                            , width 210
                            , El.height (El.px 45)
                            ]
                            (El.row []
                                [ iconPlaceholder
                                , El.text "Add Book"
                                    |> El.el
                                        [ El.centerX
                                        , El.centerY
                                        ]
                                ]
                            )
                        ]
                    , viewCategories model.checkedCategories categories
                    , viewBooks model.checkedCategories model.tableOrdering books
                    ]

            ( _, Loading ) ->
                El.none

            ( Loading, _ ) ->
                El.none

            _ ->
                El.text "Data could not be retrieved"
        )
            |> El.el
                [ width 1200
                , El.height El.fill
                ]
    }


viewCategories : List Category -> List Category -> Element Msg
viewCategories checkedCategories categories =
    let
        viewCategory ({ name } as category) =
            Input.checkbox [ width 150, height 25 ]
                { onChange = CheckedTopic category
                , checked = List.member category checkedCategories
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
            , El.text "Filter by Topic"
            ]
        , categories
            |> List.map viewCategory
            |> El.wrappedRow [ El.paddingXY 40 0, El.spacing 10 ]
        ]


viewBooks : List Category -> ( Column, Ordering ) -> List Book -> Element Msg
viewBooks checkedCategories ( column, order ) books =
    let
        data =
            (if List.isEmpty checkedCategories then
                books

             else
                List.filter (\{ category } -> List.member category checkedCategories) books
            )
                |> List.sortBy (tableOrder column)
                |> (if order == Ascending then
                        identity

                    else
                        List.reverse
                   )

        tableOrder col =
            case col of
                Title ->
                    .title

                Author ->
                    .author

                Language ->
                    .language

                AvailableTranslation ->
                    .translations >> List.map .language >> List.sort >> String.concat

                NeededTranslation ->
                    neededLanguages >> String.concat

                Topic ->
                    .category >> .name

        neededLanguages { language, translations } =
            let
                languages =
                    language :: List.map .language translations

                isNeeded l =
                    not (List.member l languages)
            in
            [ "English", "Japanese" ]
                |> List.filter isNeeded

        header title col =
            El.row [ El.centerY, El.paddingXY 5 15, El.spacing 5, Events.onClick (ClickedOrder col) ]
                [ El.paragraph [ El.width El.shrink ]
                    [ El.text title
                        |> El.el [ Font.size 20, height 65 ]
                    ]
                , (case ( col == column, order ) of
                    ( False, _ ) ->
                        El.text "⇵"

                    ( True, Ascending ) ->
                        El.text "↑"

                    ( True, Descending ) ->
                        El.text "↓"
                  )
                    |> El.el [ width 2 ]
                ]

        content i element =
            El.paragraph [ El.paddingXY 5 8, El.centerY ] [ element ]
                |> El.el
                    [ El.height El.fill
                    , El.width El.fill
                    , if modBy 2 i == 0 then
                        Background.color Style.grey

                      else
                        Background.color Style.white
                    ]
    in
    El.indexedTable [ Font.size 16 ]
        { data = data
        , columns =
            [ { header = El.none
              , width = El.shrink
              , view =
                    \_ { id } ->
                        iconPlaceholder
                            |> El.el [ El.centerY ]
              }
            , { header = header "Title" Title
              , width = El.fillPortion 2
              , view =
                    \i { title } ->
                        content i (El.text title)
              }
            , { header = header "Author" Author
              , width = El.fillPortion 2
              , view =
                    \i { author } -> content i (El.text author)
              }
            , { header = header "Original Language" Language
              , width = El.fill
              , view =
                    \i { language } ->
                        content i (El.text language)
              }
            , { header = header "Translations available" AvailableTranslation
              , width = El.fill
              , view =
                    \i { translations } ->
                        translations
                            |> List.map
                                (\{ id, language } ->
                                    Route.link (Route.Translation (Types.idToString id))
                                        [ Font.underline ]
                                        (El.text language)
                                )
                            |> El.column []
                            |> content i
              }
            , { header = header "Translation Needed" NeededTranslation
              , width = El.fill
              , view =
                    \i ({ id } as book) ->
                        neededLanguages book
                            |> List.map
                                (El.text
                                    >> Route.link (Route.AddTranslation (Types.idToString id))
                                        [ Font.underline ]
                                )
                            |> El.column []
                            |> content i
              }
            , { header = header "Topic" Topic
              , width = El.fill
              , view =
                    \i { category } ->
                        content i (El.text category.name)
              }
            ]
        }



-- GRAPHQL


booksQuery : SelectionSet (List Book) RootQuery
booksQuery =
    Query.books bookSelection


bookSelection : SelectionSet Book GraphQLBook.Object.Book
bookSelection =
    SelectionSet.map6 Book
        GBook.id
        GBook.title
        GBook.author
        GBook.language
        (GBook.category Types.categorySelection)
        (GBook.bookTranslations bookTranslationSelection)


bookTranslationSelection : SelectionSet BookTranslation GraphQLBook.Object.Book
bookTranslationSelection =
    SelectionSet.map5 BookTranslation
        GBook.id
        GBook.title
        GBook.author
        GBook.language
        (SelectionSet.withDefault "" GBook.translator)


requestBooks : Cmd Msg
requestBooks =
    booksQuery
        |> Graphql.Http.queryRequest "/api"
        |> Graphql.Http.send (RemoteData.fromResult >> GotBooks)


requestCategories : Cmd Msg
requestCategories =
    Query.categories Types.categorySelection
        |> Graphql.Http.queryRequest "/api"
        |> Graphql.Http.send (RemoteData.fromResult >> GotCategories)
