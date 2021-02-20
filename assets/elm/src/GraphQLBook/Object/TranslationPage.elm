-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module GraphQLBook.Object.TranslationPage exposing (..)

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
import Json.Decode as Decode


page :
    SelectionSet decodesTo GraphQLBook.Object.Page
    -> SelectionSet decodesTo GraphQLBook.Object.TranslationPage
page object_ =
    Object.selectionForCompositeField "page" [] object_ identity


translations :
    SelectionSet decodesTo GraphQLBook.Object.Translation
    -> SelectionSet (List decodesTo) GraphQLBook.Object.TranslationPage
translations object_ =
    Object.selectionForCompositeField "translations" [] object_ (identity >> Decode.list)
