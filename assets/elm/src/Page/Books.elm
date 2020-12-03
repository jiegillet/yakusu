module Page.Books exposing (..)

import Common exposing (Context)
import Debug
import Dict exposing (Dict)
import Element as El exposing (Element)
import Element.Font as Font
import GraphQLBook.Object
import GraphQLBook.Object.Book as GBook exposing (category)
import GraphQLBook.Query as Query
import GraphQLBook.Scalar exposing (Id)
import Graphql.Http exposing (Error)
import Graphql.Operation exposing (RootQuery)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import RemoteData exposing (RemoteData(..))
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
    }


init : Context -> ( Model, Cmd Msg )
init context =
    ( { context = context
      , books = Loading
      }
    , requestBooks
    )



-- UPDATE


type Msg
    = GotBooks (RemoteData (Error (List Book)) (List Book))


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        GotBooks response ->
            ( { model | books = response }, Cmd.none )



-- VIEW


view : Model -> { title : String, body : Element msg }
view model =
    { title = "List of Books"
    , body =
        case model.books of
            Success books ->
                viewBooks books

            Loading ->
                El.text "Loading, please wait"

            _ ->
                El.text "Data could not be retrieved"
    }


viewBooks : List Book -> Element msg
viewBooks books =
    El.table []
        { data = books
        , columns =
            [ { header = El.text "Title"
              , width = El.shrink
              , view =
                    \{ title, author } ->
                        El.column []
                            [ El.text title
                            , El.text author
                            ]
              }
            , { header = El.text "Category"
              , width = El.shrink
              , view =
                    \{ category } ->
                        El.text category.name
              }
            , { header = El.text "Tags"
              , width = El.shrink
              , view =
                    \_ ->
                        El.column []
                            [ El.text "TODO: Add Tags"
                            , El.text "TODO: Add Tags"
                            ]
              }
            , { header = El.text "Translations available"
              , width = El.shrink
              , view =
                    \{ translations } ->
                        translations
                            |> List.map (\{ language } -> El.text language)
                            |> El.column []
              }
            , { header = El.text "Add a Translation"
              , width = El.shrink
              , view =
                    \{ language, translations } -> El.text "TODO"

              --  let
              --     List.filter ()  ["Japanese", "English"]
              }
            ]
                |> List.map (\x -> { x | header = El.el [ Font.bold, El.paddingXY 5 2 ] x.header })
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
