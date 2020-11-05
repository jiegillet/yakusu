module Types exposing (..)

import Dict exposing (Dict)
import File exposing (File)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)


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
    }


type alias Page =
    { id : Int
    , image : String
    , image_type : String
    , translations : Dict Int Translation
    }


type alias Translation =
    { id : Int, text : String, blob : Dict Int (List Position) }


type alias Position =
    { x : Int, y : Int }



-- decoder
