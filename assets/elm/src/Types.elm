module Types exposing (..)

import Dict exposing (Dict)
import Dict.Extra as Dict
import File exposing (File)
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


idToString : Id -> String
idToString (Id id) =
    id


stringToId : String -> Id
stringToId =
    Id


type alias Book =
    { id : String
    , title : String
    , author : String
    , language : String
    , translations : List BookTranslation
    , pages : Dict String Page
    }


type alias BookTranslation =
    { id : String
    , title : String
    , author : String
    , language : String
    , translator : String
    , notes : String
    , translations : Dict String Translation
    }


type alias Page =
    { id : String
    , imageType : String
    , pageNumber : Int
    }


type alias Translation =
    { id : String
    , pageId : String
    , text : String
    , blob : Dict Int (List Position)
    }


type alias Position =
    { id : String
    , group : Int
    , x : Int
    , y : Int
    }



-- GraphQL


bookSelection : SelectionSet Book GraphQLBook.Object.Book
bookSelection =
    SelectionSet.map6 Book
        (SelectionSet.map idToString GBook.id)
        GBook.title
        GBook.author
        GBook.language
        (GBook.bookTranslations bookTranslationSelection)
        (SelectionSet.map toDict (GBook.pages pageSelection))


bookTranslationSelection : SelectionSet BookTranslation GraphQLBook.Object.Book
bookTranslationSelection =
    SelectionSet.map7 BookTranslation
        (SelectionSet.map idToString GBook.id)
        GBook.title
        GBook.author
        GBook.language
        (SelectionSet.withDefault "" GBook.translator)
        (SelectionSet.withDefault "" GBook.notes)
        (SelectionSet.map toDict (GBook.translations translationSelection))


pageSelection : SelectionSet Page GraphQLBook.Object.Page
pageSelection =
    SelectionSet.map3 Page
        (SelectionSet.map idToString GPage.id)
        GPage.imageType
        GPage.pageNumber


translationSelection : SelectionSet Translation GraphQLBook.Object.Translation
translationSelection =
    SelectionSet.map4 Translation
        (SelectionSet.map idToString GTranslation.id)
        (SelectionSet.map idToString GTranslation.pageId)
        GTranslation.text
        (SelectionSet.map (Dict.groupBy .group) (GTranslation.positions positionSelection))


positionSelection : SelectionSet Position GraphQLBook.Object.Position
positionSelection =
    SelectionSet.map4 Position
        (SelectionSet.map idToString GPosition.id)
        GPosition.group
        GPosition.x
        GPosition.y


toDict : List { a | id : comparable } -> Dict comparable { a | id : comparable }
toDict =
    List.map (\({ id } as a) -> ( id, a ))
        >> Dict.fromList
