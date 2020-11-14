module Page.Books exposing (..)

import Common exposing (Context)
import Debug
import Element as El exposing (Element)
import Element.Input as Input
import GraphQLBook.Object
import GraphQLBook.Object.Book as GBook
import GraphQLBook.Query as Query
import GraphQLBook.Scalar exposing (Id(..))
import Graphql.Http exposing (Error)
import Graphql.Operation exposing (RootQuery)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import RemoteData exposing (RemoteData(..))
import Types exposing (Book)



-- TYPES


type alias Model =
    { context : Context
    , books : List Book
    }


init : Context -> ( Model, Cmd Msg )
init context =
    ( { context = context
      , books = []
      }
    , makeRequest
    )



-- UPDATE


type Msg
    = GotResponse (RemoteData (Error (List BookTest)) (List BookTest))


update msg model =
    case msg of
        GotResponse response ->
            ( Debug.log (Debug.toString response) model, Cmd.none )



-- VIEW


view : Model -> { title : String, body : Element msg }
view model =
    { title = "List of Books"
    , body =
        viewBooks model.books
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


query : SelectionSet (List BookTest) RootQuery
query =
    Query.books bookSelection


type alias BookTest =
    { title : String }


bookSelection : SelectionSet BookTest GraphQLBook.Object.Book
bookSelection =
    SelectionSet.map BookTest
        GBook.title



-- SelectionSet.map6 Book
--     GBook.id
--     GBook.title
--     GBook.author
--     GBook.language
--     GBook.translations
--     GBook.pages


makeRequest : Cmd Msg
makeRequest =
    query
        |> Graphql.Http.queryRequest "http://localhost:4000/api"
        |> Graphql.Http.send (RemoteData.fromResult >> GotResponse)
