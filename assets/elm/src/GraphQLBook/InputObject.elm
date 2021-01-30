-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module GraphQLBook.InputObject exposing (..)

import GraphQLBook.Interface
import GraphQLBook.Object
import GraphQLBook.Scalar
import GraphQLBook.ScalarCodecs
import GraphQLBook.Union
import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Json.Decode as Decode


buildInputTranslation :
    InputTranslationRequiredFields
    -> (InputTranslationOptionalFields -> InputTranslationOptionalFields)
    -> InputTranslation
buildInputTranslation required fillOptionals =
    let
        optionals =
            fillOptionals
                { id = Absent }
    in
    { id = optionals.id, pageId = required.pageId, path = required.path, text = required.text, translationBookId = required.translationBookId }


type alias InputTranslationRequiredFields =
    { pageId : GraphQLBook.ScalarCodecs.Id
    , path : String
    , text : String
    , translationBookId : GraphQLBook.ScalarCodecs.Id
    }


type alias InputTranslationOptionalFields =
    { id : OptionalArgument GraphQLBook.ScalarCodecs.Id }


{-| Type for the InputTranslation input object.
-}
type alias InputTranslation =
    { id : OptionalArgument GraphQLBook.ScalarCodecs.Id
    , pageId : GraphQLBook.ScalarCodecs.Id
    , path : String
    , text : String
    , translationBookId : GraphQLBook.ScalarCodecs.Id
    }


{-| Encode a InputTranslation into a value that can be used as an argument.
-}
encodeInputTranslation : InputTranslation -> Value
encodeInputTranslation input =
    Encode.maybeObject
        [ ( "id", (GraphQLBook.ScalarCodecs.codecs |> GraphQLBook.Scalar.unwrapEncoder .codecId) |> Encode.optional input.id ), ( "pageId", (GraphQLBook.ScalarCodecs.codecs |> GraphQLBook.Scalar.unwrapEncoder .codecId) input.pageId |> Just ), ( "path", Encode.string input.path |> Just ), ( "text", Encode.string input.text |> Just ), ( "translationBookId", (GraphQLBook.ScalarCodecs.codecs |> GraphQLBook.Scalar.unwrapEncoder .codecId) input.translationBookId |> Just ) ]
