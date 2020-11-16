module Page.Books exposing (..)

import Common exposing (Context)
import Debug
import Dict exposing (Dict)
import Dict.Extra as Dict
import Element as El exposing (Element)
import Element.Input as Input
import GraphQLBook.Object
import GraphQLBook.Object.Book as GBook
import GraphQLBook.Query as Query
import GraphQLBook.Scalar exposing (Id)
import Graphql.Http exposing (Error)
import Graphql.Operation exposing (RootQuery)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import RemoteData exposing (RemoteData(..))



-- TYPES


type alias Book =
    { id : Id
    , title : String
    , author : String
    , language : String
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
    let
        viewBook { title } =
            El.text title
    in
    books
        |> List.map viewBook
        |> El.column []



-- GRAPHQL


query : SelectionSet (List Book) RootQuery
query =
    Query.books bookSelection


bookSelection : SelectionSet Book GraphQLBook.Object.Book
bookSelection =
    SelectionSet.map5 Book
        GBook.id
        GBook.title
        GBook.author
        GBook.language
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
    query
        |> Graphql.Http.queryRequest "http://localhost:4000/api"
        |> Graphql.Http.send (RemoteData.fromResult >> GotBooks)
