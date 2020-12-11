module Page.AddTranslation exposing (Model, Msg, init, update, view)

import Common exposing (Context)
import Element as El exposing (Attribute, Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import GraphQLBook.Mutation as Mutation
import GraphQLBook.Object exposing (Book)
import GraphQLBook.Object.Book as GBook
import GraphQLBook.Query as Query
import GraphQLBook.Scalar exposing (Id(..))
import Graphql.Http exposing (Error)
import Graphql.Operation exposing (RootMutation, RootQuery)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import RemoteData exposing (RemoteData(..))
import Route
import Style
import Types



-- TYPES


type alias Model =
    { context : Context
    , book : RemoteData (Error (Maybe Book)) (Maybe Book)
    , form : Form

    -- , languages : RemoteData (Error (List Language)) (List Language)
    }


init : Context -> String -> ( Model, Cmd Msg )
init context bookId =
    ( { context = context
      , book = Loading
      , form = emptyForm

      --   , languages = Loading
      }
      -- , getlanguages
    , getBook bookId
    )


type alias Form =
    { title : String
    , author : String
    , language : String
    , translator : String
    , notes : String

    -- , language : Maybe Language
    -- , dropdown : Dropdown
    }


emptyForm : Form
emptyForm =
    { title = ""
    , author = ""
    , language = ""
    , translator = ""
    , notes = ""

    -- , language = Nothing
    -- , dropdown = Closed
    }



-- type Dropdown
--     = Closed
--     | Open (Maybe Language)


type alias Book =
    { id : String
    , title : String
    , author : String
    , language : String
    }



-- UPDATE


type Msg
    = InputTitle String
    | InputAuthor String
    | InputLanguage String
    | InputTranslator String
    | InputNotes String
    | ClickedStartTranslation Id Form
    | GotBook (RemoteData (Error (Maybe Book)) (Maybe Book))
    | GotTranslationBookId (RemoteData (Error Id) Id)



-- | Gotlanguages (RemoteData (Error (List Language)) (List Language))
-- | ClickedSelectLanguage
-- | HoverededLanguage Language
-- | ClickedLanguage Language


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        modelForm =
            model.form
    in
    case msg of
        InputTitle title ->
            ( { model | form = { modelForm | title = title } }, Cmd.none )

        InputAuthor author ->
            ( { model | form = { modelForm | author = author } }, Cmd.none )

        InputLanguage language ->
            ( { model | form = { modelForm | language = language } }, Cmd.none )

        InputTranslator translator ->
            ( { model | form = { modelForm | translator = translator } }, Cmd.none )

        InputNotes notes ->
            ( { model | form = { modelForm | notes = notes } }, Cmd.none )

        ClickedStartTranslation bookId form ->
            ( model, saveBook bookId form )

        GotBook result ->
            ( { model | book = result }, Cmd.none )

        GotTranslationBookId result ->
            case result of
                Success (Id bookId) ->
                    ( model, Route.replaceUrl model.context.key (Route.Translation bookId) )

                _ ->
                    ( model, Cmd.none )



-- Gotlanguages result ->
--     ( { model | languages = result }, Cmd.none )
-- ClickedSelectLanguage ->
--     ( { model
--         | book =
--             { modelForm
--                 | dropdown =
--                     case modelForm.dropdown of
--                         Closed ->
--                             Open Nothing
--                         _ ->
--                             Closed
--             }
--       }
--     , Cmd.none
--     )
-- HoverededLanguage language ->
--     ( { model | book = { modelForm | dropdown = Open (Just language) } }, Cmd.none )
-- ClickedLanguage language ->
--     ( { model | book = { modelForm | dropdown = Closed, language = Just language } }, Cmd.none )
-- VIEW


view : Model -> { title : String, body : Element Msg }
view model =
    { title = "List of Books"
    , body =
        case model.book of
            Success (Just book) ->
                viewForm model.form book
                    |> El.el [ El.padding 30 ]

            _ ->
                El.text "There was an issue retrieving the original book"
    }


gray : El.Color
gray =
    El.rgb255 200 200 200


viewForm : Form -> Book -> Element Msg
viewForm ({ title, author, language, translator, notes } as form) book =
    let
        place text =
            text
                |> El.text
                |> Input.placeholder []
                |> Just
    in
    El.column [ El.spacing 10 ]
        [ Input.text []
            { onChange = InputLanguage
            , text = language
            , placeholder = place "English"
            , label = Input.labelAbove [] (El.text "Language of Translation")
            }
        , Input.text []
            { onChange = InputTranslator
            , text = translator
            , placeholder = place "Jeremie Gillet"
            , label = Input.labelAbove [] (El.text "Translator(s)")
            }
        , Input.text []
            { onChange = InputTitle
            , text = title
            , placeholder = place "Title translation"
            , label = Input.labelAbove [] (El.text ("Original title \"" ++ book.title ++ "\""))
            }
        , Input.text []
            { onChange = InputAuthor
            , text = author
            , placeholder = place "Author translation"
            , label = Input.labelAbove [] (El.text ("Author(s): \"" ++ book.author ++ "\""))
            }
        , Input.multiline []
            { onChange = InputNotes
            , text = notes
            , placeholder = place "Jeremie Gillet"
            , spellcheck = True
            , label = Input.labelAbove [] (El.text "Translation notes")
            }

        -- , viewLanguageDropdown dropdown language languages
        , Input.button []
            { onPress =
                ClickedStartTranslation (Id book.id) form
                    |> Just
            , label =
                El.text "Add Book Translation"
                    |> El.el [ Background.color gray, El.padding 5 ]
            }
        ]



-- viewLanguageDropdown : Dropdown -> Maybe Language -> List Language -> Element Msg
-- viewLanguageDropdown dropdown maybeLanguage languages =
--     El.row [ El.width El.fill ]
--         [ El.text "Language "
--         , maybeLanguage
--             |> Maybe.map .name
--             |> Maybe.withDefault "Please select a language"
--             |> El.text
--             |> El.el
--                 ([ Border.color Style.black
--                  , Border.width 1
--                  , El.width El.fill
--                  , El.padding 5
--                  ]
--                     ++ (case dropdown of
--                             Closed ->
--                                 [ Events.onClick ClickedSelectLanguage ]
--                             Open hoveredLanguage ->
--                                 [ languages
--                                     |> List.sortBy .name
--                                     |> List.map
--                                         (\({ name } as language) ->
--                                             El.text name
--                                                 |> El.el
--                                                     ([ El.width El.fill
--                                                      , El.padding 2
--                                                      , Events.onMouseEnter (HoverededLanguage language)
--                                                      , Events.onClick (ClickedLanguage language)
--                                                      ]
--                                                         ++ (if Just language == hoveredLanguage then
--                                                                 [ Background.color Style.black, Font.color Style.white ]
--                                                             else
--                                                                 [ Background.color Style.white ]
--                                                            )
--                                                     )
--                                         )
--                                     |> El.column [ El.width El.fill, Border.width 1 ]
--                                     |> El.below
--                                 ]
--                        )
--                 )
--         ]
-- GRAPHQL
-- languagesQuery : SelectionSet (List Language) RootQuery
-- languagesQuery =
--     Query.languages Types.languageSelection
-- getlanguages : Cmd Msg
-- getlanguages =
--     languagesQuery
--         |> Graphql.Http.queryRequest "/api"
--         |> Graphql.Http.send (RemoteData.fromResult >> Gotlanguages)
-- GRAPHQL


booksQuery : String -> SelectionSet (Maybe Book) RootQuery
booksQuery bookId =
    Query.book { id = Id bookId } bookSelection


bookSelection : SelectionSet Book GraphQLBook.Object.Book
bookSelection =
    SelectionSet.map4 Book
        (SelectionSet.map Types.idToString GBook.id)
        GBook.title
        GBook.author
        GBook.language


getBook : String -> Cmd Msg
getBook bookId =
    booksQuery bookId
        |> Graphql.Http.queryRequest "/api"
        |> Graphql.Http.send (RemoteData.fromResult >> GotBook)


saveBookMutation : Id -> Form -> SelectionSet Id RootMutation
saveBookMutation bookId { title, author, language, translator, notes } =
    let
        modifyOptional options =
            { options | notes = Present notes }
    in
    Mutation.createBook modifyOptional
        { author = author
        , language = language
        , originalId = bookId
        , title = title
        , translator = translator
        }
        GBook.id


saveBook : Id -> Form -> Cmd Msg
saveBook bookId form =
    saveBookMutation bookId form
        |> Graphql.Http.mutationRequest "/api"
        |> Graphql.Http.send (RemoteData.fromResult >> GotTranslationBookId)
