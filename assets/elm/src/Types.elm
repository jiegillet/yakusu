module Types exposing (..)

import Dict exposing (Dict)
import File exposing (File)


type alias Book =
    { id : Int
    , title : String
    , author : String
    , language : String
    , translations : List BookTranslation
    , pages : Dict Int Page
    }


type alias BookTranslation =
    { id : Int
    , title : String
    , author : String
    , language : String
    , translator : String
    , notes : String
    , translations : Dict Int Translation
    }


type alias Page =
    { id : Int
    , image : String
    }


type alias Translation =
    { id : Maybe Int
    , pageId : Int
    , text : String
    , blob : Dict Int (List Position)
    }


type alias Position =
    { x : Int
    , y : Int
    }



-- GraphQL
