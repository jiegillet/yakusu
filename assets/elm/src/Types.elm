module Types exposing (..)

import Dict exposing (Dict)
import File exposing (File)
import GraphQLBook.Scalar exposing (Id(..))


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
    , number : Int
    }


type alias Translation =
    { id : String
    , pageId : String
    , text : String
    , blob : Dict Int (List Position)
    }


type alias Position =
    { id : Maybe String
    , group : Int
    , x : Int
    , y : Int
    }



-- GraphQL
