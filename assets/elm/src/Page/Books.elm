module Page.Books exposing (Book, BookTranslation, Model, Msg, bookSelection, bookTranslationSelection, init, update, view, viewCategories)

import Api exposing (Cred, GraphQLData)
import Common exposing (Context, height, width)
import Element as El exposing (Element, column)
import Element.Background as Background
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import GraphQLBook.Object
import GraphQLBook.Object.Book as GBook
import GraphQLBook.Object.TranslationBook as TBook
import GraphQLBook.Query as Query
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import LanguageSelect
import RemoteData exposing (RemoteData(..))
import Route
import Style
import Types exposing (Category, Language)



-- TYPES


type alias Book =
    { id : String
    , title : String
    , author : String
    , language : Language
    , category : Category
    , numPages : Int
    , translations : List BookTranslation
    }


type alias BookTranslation =
    { id : String
    , title : String
    , author : String
    , language : Language
    , translator : String
    }


type alias Model =
    { context : Context
    , cred : Cred
    , books : GraphQLData (List Book)
    , categories : GraphQLData (List Category)
    , checkedCategories : List Category
    , showCategories : Bool
    , tableOrdering : ( Column, Ordering )
    }


init : Context -> Cred -> ( Model, Cmd Msg )
init context cred =
    ( { context = context
      , cred = cred
      , books = Loading
      , categories = Loading
      , checkedCategories = []
      , showCategories = False
      , tableOrdering = ( Title, Ascending )
      }
    , Cmd.batch [ requestBooks cred, requestCategories cred ]
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
    | Theme



-- UPDATE


type Msg
    = GotBooks (GraphQLData (List Book))
    | GotCategories (GraphQLData (List Category))
    | CheckedTopic Category Bool
    | ClickedOrder Column
    | ClickedOnCategories


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

        ClickedOnCategories ->
            ( { model | showCategories = not model.showCategories }, Cmd.none )



-- VIEW


view : Model -> { title : String, body : Element Msg }
view model =
    { title = "List of Books"
    , body =
        case ( model.books, model.categories ) of
            ( Success books, Success categories ) ->
                El.column
                    [ El.spacing 25, width 1000 ]
                    [ El.paragraph [ Font.size 24, El.paddingXY 0 30 ]
                        [ El.text "Welcome to "
                        , El.text "Yakusu" |> El.el [ Font.family [ Font.typeface "clear_sans_mediumregular" ] ]
                        ]
                    , El.row [ El.spacing 10, Font.size 20 ]
                        [ El.row [ Background.color Style.grey, width 470, height 45 ]
                            [ Style.listIcon
                            , El.text "List of available books"
                            ]
                        , Route.link Route.AddBook
                            [ Background.color Style.lightCyan
                            , width 210
                            , El.height (El.px 45)
                            ]
                            (El.row [ El.centerX ]
                                [ Style.whitePlus
                                , El.text "Add Book"
                                    |> El.el
                                        [ El.centerX
                                        , El.centerY
                                        ]
                                ]
                            )
                        ]
                    , viewCategories model.checkedCategories categories model.showCategories
                    , viewBooks model.checkedCategories model.tableOrdering books
                    ]

            ( _, Loading ) ->
                El.none

            ( Loading, _ ) ->
                El.none

            _ ->
                El.text "Data could not be retrieved"
    }


viewCategories : List Category -> List Category -> Bool -> Element Msg
viewCategories checkedCategories categories showCategories =
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
                                    Background.color Style.lightCyan

                                  else
                                    Background.color Style.grey
                                ]
                , label = Input.labelHidden name
                }
    in
    El.column [ El.spacing 20 ]
        [ El.row [ Background.color Style.grey, width 250, height 45, Font.size 20, Events.onClick ClickedOnCategories ]
            [ if showCategories then
                Style.verticalTag

              else
                Style.horizontalTag
            , El.text "Filter by Theme"
            ]
        , if showCategories then
            categories
                |> List.map viewCategory
                |> El.wrappedRow [ El.paddingEach { top = 0, bottom = 0, left = 40, right = 0 }, El.spacing 12 ]

          else
            El.none
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
                    .language >> .language

                AvailableTranslation ->
                    .translations >> List.map (.language >> .language) >> List.sort >> String.concat

                NeededTranslation ->
                    neededLanguages >> List.map .id >> String.concat

                Theme ->
                    .category >> .name

        neededLanguages { language, translations } =
            let
                languages =
                    language :: List.map .language translations

                isNeeded l =
                    not (List.member l languages)
            in
            [ LanguageSelect.english, LanguageSelect.japanese ]
                |> List.filter isNeeded

        header title col =
            El.row [ height 50, Events.onClick (ClickedOrder col) ]
                [ case ( col == column, order ) of
                    ( False, _ ) ->
                        Style.upDownArrow

                    ( True, Ascending ) ->
                        Style.upArrow

                    ( True, Descending ) ->
                        Style.downArrow
                , El.paragraph [ El.width El.shrink ]
                    [ El.text title
                        |> El.el [ Font.size 20, height 65 ]
                    ]
                ]

        content i element =
            El.paragraph [ El.paddingXY 5 8, El.centerY ] [ element ]
                |> El.el
                    [ El.height (El.minimum 50 El.fill)
                    , if modBy 2 i == 0 then
                        Background.color Style.grey

                      else
                        Background.color Style.white
                    ]
    in
    El.indexedTable [ Font.size 16 ]
        { data = data
        , columns =
            [ { header = El.el [ height 50 ] El.none
              , width = El.shrink
              , view =
                    \_ { id } -> Route.link (Route.BookDetail id False) [ El.centerY ] Style.smallPencil
              }
            , { header = header "Title" Title
              , width = El.fill
              , view = \i { title } -> content i (El.text title)
              }
            , { header = header "Author" Author
              , width = El.fill
              , view = \i { author } -> content i (El.text author)
              }
            , { header = header "Original Language" Language
              , width = El.fill
              , view = \i { language } -> content i (El.text language.language)
              }
            , { header = header "Translations available" AvailableTranslation
              , width = El.fill
              , view =
                    \i { translations, id } ->
                        translations
                            |> List.map
                                (\translation ->
                                    Route.link (Route.EditTranslation id translation.id)
                                        [ Font.underline ]
                                        (El.text translation.language.language)
                                )
                            |> El.column []
                            |> content i
              }
            , { header = header "Translations Needed" NeededTranslation
              , width = El.fill
              , view =
                    \i ({ id } as book) ->
                        neededLanguages book
                            |> List.map
                                (\language ->
                                    El.text language.language
                                        |> Route.link (Route.AddTranslation id (Just language))
                                            [ Font.underline ]
                                )
                            |> El.column []
                            |> content i
              }
            , { header = header "Theme" Theme
              , width = El.fill
              , view =
                    \i { category } ->
                        content i (El.text category.name)
              }
            ]
        }



-- GRAPHQL


bookSelection : SelectionSet Book GraphQLBook.Object.Book
bookSelection =
    SelectionSet.map7 Book
        (SelectionSet.map Types.idToString GBook.id)
        GBook.title
        GBook.author
        (GBook.language Types.languageSelection)
        (GBook.category Types.categorySelection)
        GBook.numPages
        (GBook.bookTranslations bookTranslationSelection)


bookTranslationSelection : SelectionSet BookTranslation GraphQLBook.Object.TranslationBook
bookTranslationSelection =
    SelectionSet.map5 BookTranslation
        (SelectionSet.map Types.idToString TBook.id)
        TBook.title
        TBook.author
        (TBook.language Types.languageSelection)
        TBook.translator


requestBooks : Cred -> Cmd Msg
requestBooks cred =
    Api.queryRequest cred (Query.books bookSelection) GotBooks


requestCategories : Cred -> Cmd Msg
requestCategories cred =
    Api.queryRequest cred (Query.categories Types.categorySelection) GotCategories
