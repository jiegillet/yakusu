-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module GraphQLBook.Query exposing (..)

import GraphQLBook.InputObject
import GraphQLBook.Interface
import GraphQLBook.Object
import GraphQLBook.Scalar
import GraphQLBook.ScalarCodecs
import GraphQLBook.Union
import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Json.Decode as Decode exposing (Decoder)


type alias BookRequiredArguments =
    { id : GraphQLBook.ScalarCodecs.Id }


{-| Get a particular book
-}
book :
    BookRequiredArguments
    -> SelectionSet decodesTo GraphQLBook.Object.Book
    -> SelectionSet (Maybe decodesTo) RootQuery
book requiredArgs object_ =
    Object.selectionForCompositeField "book" [ Argument.required "id" requiredArgs.id (GraphQLBook.ScalarCodecs.codecs |> GraphQLBook.Scalar.unwrapEncoder .codecId) ] object_ (identity >> Decode.nullable)


{-| Get all books
-}
books :
    SelectionSet decodesTo GraphQLBook.Object.Book
    -> SelectionSet (List decodesTo) RootQuery
books object_ =
    Object.selectionForCompositeField "books" [] object_ (identity >> Decode.list)


{-| Get all categories
-}
categories :
    SelectionSet decodesTo GraphQLBook.Object.Category
    -> SelectionSet (List decodesTo) RootQuery
categories object_ =
    Object.selectionForCompositeField "categories" [] object_ (identity >> Decode.list)


{-| Get all languages
-}
languages :
    SelectionSet decodesTo GraphQLBook.Object.Language
    -> SelectionSet (List decodesTo) RootQuery
languages object_ =
    Object.selectionForCompositeField "languages" [] object_ (identity >> Decode.list)


type alias RenderBookRequiredArguments =
    { id : GraphQLBook.ScalarCodecs.Id
    , maxCharacters : Int
    }


{-| Export a rendered translation book
-}
renderBook :
    RenderBookRequiredArguments
    -> SelectionSet String RootQuery
renderBook requiredArgs =
    Object.selectionForField "String" "renderBook" [ Argument.required "id" requiredArgs.id (GraphQLBook.ScalarCodecs.codecs |> GraphQLBook.Scalar.unwrapEncoder .codecId), Argument.required "maxCharacters" requiredArgs.maxCharacters Encode.int ] Decode.string


type alias TranslationBookRequiredArguments =
    { id : GraphQLBook.ScalarCodecs.Id }


{-| Get a particular translation book
-}
translationBook :
    TranslationBookRequiredArguments
    -> SelectionSet decodesTo GraphQLBook.Object.TranslationBook
    -> SelectionSet (Maybe decodesTo) RootQuery
translationBook requiredArgs object_ =
    Object.selectionForCompositeField "translationBook" [ Argument.required "id" requiredArgs.id (GraphQLBook.ScalarCodecs.codecs |> GraphQLBook.Scalar.unwrapEncoder .codecId) ] object_ (identity >> Decode.nullable)
