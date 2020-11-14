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
