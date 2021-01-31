module Page.AddTranslation exposing (Model, Msg, init, update, view)

import Api exposing (Cred)
import Common exposing (Context)
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import GraphQLBook.Mutation as Mutation
import GraphQLBook.Object exposing (Book)
import GraphQLBook.Object.Book as GBook
import GraphQLBook.Object.TranslationBook as TBook
import GraphQLBook.Query as Query
import GraphQLBook.Scalar exposing (Id(..))
import Graphql.Http exposing (Error)
import Graphql.Operation exposing (RootMutation)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import RemoteData exposing (RemoteData(..))
import Route
import Style
import Types exposing (Language)



-- TYPES


type alias Model =
    { context : Context
    , cred : Cred
    , book : RemoteData (Error (Maybe Book)) (Maybe Book)
    , form : Form
    , languages : RemoteData (Error (List Language)) (List Language)
    }


init : Context -> Cred -> String -> ( Model, Cmd Msg )
init context cred bookId =
    ( { context = context
      , cred = cred
      , book = Loading
      , form = emptyForm
      , languages = Loading
      }
    , Cmd.batch [ getBook cred bookId, getlanguages cred ]
    )


type alias Form =
    { title : String
    , author : String
    , language : Maybe Language
    , translator : String
    , notes : String

    -- , dropdown : Dropdown
    }


emptyForm : Form
emptyForm =
    { title = ""
    , author = ""
    , language = Nothing
    , translator = ""
    , notes = ""

    -- , dropdown = Closed
    }



-- type Dropdown
--     = Closed
--     | Open (Maybe Language)


type alias Book =
    { id : String
    , title : String
    , author : String
    , language : Language
    }



-- UPDATE


type Msg
    = InputTitle String
    | InputAuthor String
    | InputLanguage Language
    | InputTranslator String
    | InputNotes String
    | ClickedStartTranslation Id Form
    | GotBook (RemoteData (Error (Maybe Book)) (Maybe Book))
    | GotTranslationBookId (RemoteData (Error Id) Id)
    | GotLanguages (RemoteData (Error (List Language)) (List Language))



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
            ( { model | form = { modelForm | language = Just language } }, Cmd.none )

        InputTranslator translator ->
            ( { model | form = { modelForm | translator = translator } }, Cmd.none )

        InputNotes notes ->
            ( { model | form = { modelForm | notes = notes } }, Cmd.none )

        ClickedStartTranslation bookId form ->
            ( model, saveBook model.cred bookId form )

        GotBook result ->
            ( { model | book = result }, Cmd.none )

        GotTranslationBookId result ->
            case result of
                Success (Id bookId) ->
                    ( model, Route.replaceUrl model.context.key (Route.Translation bookId) )

                _ ->
                    ( model, Cmd.none )

        GotLanguages result ->
            ( { model | languages = result }, Cmd.none )



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
        case ( model.book, model.languages ) of
            ( Success (Just book), Success languages ) ->
                viewForm model.form languages book
                    |> El.el [ El.padding 30 ]

            _ ->
                El.text "There was an issue retrieving the data"
    }


gray : El.Color
gray =
    El.rgb255 200 200 200


viewForm : Form -> List Language -> Book -> Element Msg
viewForm ({ title, author, language, translator, notes } as form) languages book =
    let
        place text =
            text
                |> El.text
                |> Input.placeholder []
                |> Just
    in
    El.column [ El.spacing 10 ]
        [ viewLanguageChoice language languages
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


viewLanguageChoice : Maybe Language -> List Language -> Element Msg
viewLanguageChoice language languages =
    Input.radioRow [ El.spacing 30 ]
        { onChange = InputLanguage
        , label =
            Input.labelLeft [ El.paddingEach { top = 0, bottom = 0, left = 0, right = 30 } ]
                (El.text "Language of Translation"
                    |> El.el
                        [ Background.color Style.nightBlue
                        , El.padding 10
                        ]
                )
        , selected = language
        , options =
            languages
                |> List.map (\lan -> Input.option lan (El.text lan.language))
        }



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


saveBookMutation : Id -> Form -> SelectionSet Id RootMutation
saveBookMutation bookId { title, author, language, translator, notes } =
    let
        modifyOptional options =
            { options | notes = Present notes }
    in
    Mutation.createTranslationBook modifyOptional
        { author = author
        , languageId = Maybe.withDefault "" (Maybe.map .id language)
        , bookId = bookId
        , title = title
        , translator = translator
        }
        TBook.id


saveBook : Cred -> Id -> Form -> Cmd Msg
saveBook cred bookId form =
    Api.mutationRequest cred (saveBookMutation bookId form) GotTranslationBookId
