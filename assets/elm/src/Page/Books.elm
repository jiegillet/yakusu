module Page.Books exposing (..)

import Common exposing (Context)
import Debug
import Dict exposing (Dict)
import Dict.Extra as Dict
import Element as El exposing (Element)
import Element.Input as Input
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
import RemoteData exposing (RemoteData(..))
import Types exposing (Book, BookTranslation, Page, Position, Translation)



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
    = GotResponse (RemoteData (Error (List Book)) (List Book))


update : Msg -> Model -> ( Model, Cmd msg )
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


query : SelectionSet (List Book) RootQuery
query =
    Query.books bookSelection


bookSelection : SelectionSet Book GraphQLBook.Object.Book
bookSelection =
    SelectionSet.map6 Book
        (SelectionSet.map Types.idToString GBook.id)
        GBook.title
        GBook.author
        GBook.language
        (GBook.bookTranslations bookTranslationSelection)
        (SelectionSet.map toDict (GBook.pages pageSelection))


bookTranslationSelection : SelectionSet BookTranslation GraphQLBook.Object.Book
bookTranslationSelection =
    SelectionSet.map7 BookTranslation
        (SelectionSet.map Types.idToString GBook.id)
        GBook.title
        GBook.author
        GBook.language
        (SelectionSet.map (Maybe.withDefault "") GBook.translator)
        (SelectionSet.map (Maybe.withDefault "") GBook.notes)
        (SelectionSet.map toDict (GBook.translations translationSelection))


pageSelection : SelectionSet Page GraphQLBook.Object.Page
pageSelection =
    SelectionSet.map3 Page
        (SelectionSet.map Types.idToString GPage.id)
        GPage.imageType
        GPage.pageNumber


translationSelection : SelectionSet Translation GraphQLBook.Object.Translation
translationSelection =
    SelectionSet.map4 Translation
        (SelectionSet.map Types.idToString GTranslation.id)
        (SelectionSet.map Types.idToString GTranslation.pageId)
        GTranslation.text
        (SelectionSet.map (Dict.groupBy .group) (GTranslation.positions positionSelection))


positionSelection : SelectionSet Position GraphQLBook.Object.Position
positionSelection =
    SelectionSet.map4 Position
        (SelectionSet.map (Maybe.map Types.idToString) GPosition.id)
        GPosition.group
        GPosition.x
        GPosition.y


toDict : List { a | id : comparable } -> Dict comparable { a | id : comparable }
toDict =
    List.map (\({ id } as a) -> ( id, a ))
        >> Dict.fromList


makeRequest : Cmd Msg
makeRequest =
    query
        |> Graphql.Http.queryRequest "http://localhost:4000/api"
        |> Graphql.Http.send (RemoteData.fromResult >> GotResponse)
