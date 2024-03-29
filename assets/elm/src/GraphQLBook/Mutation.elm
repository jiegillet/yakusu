-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module GraphQLBook.Mutation exposing (..)

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


type alias CreateBookOptionalArguments =
    { id : OptionalArgument GraphQLBook.ScalarCodecs.Id }


type alias CreateBookRequiredArguments =
    { author : String
    , categoryId : GraphQLBook.ScalarCodecs.Id
    , languageId : String
    , title : String
    }


{-| Create new book
-}
createBook :
    (CreateBookOptionalArguments -> CreateBookOptionalArguments)
    -> CreateBookRequiredArguments
    -> SelectionSet decodesTo GraphQLBook.Object.Book
    -> SelectionSet decodesTo RootMutation
createBook fillInOptionals requiredArgs object_ =
    let
        filledInOptionals =
            fillInOptionals { id = Absent }

        optionalArgs =
            [ Argument.optional "id" filledInOptionals.id (GraphQLBook.ScalarCodecs.codecs |> GraphQLBook.Scalar.unwrapEncoder .codecId) ]
                |> List.filterMap identity
    in
    Object.selectionForCompositeField "createBook" (optionalArgs ++ [ Argument.required "author" requiredArgs.author Encode.string, Argument.required "categoryId" requiredArgs.categoryId (GraphQLBook.ScalarCodecs.codecs |> GraphQLBook.Scalar.unwrapEncoder .codecId), Argument.required "languageId" requiredArgs.languageId Encode.string, Argument.required "title" requiredArgs.title Encode.string ]) object_ identity


type alias CreateTranslationRequiredArguments =
    { translation : GraphQLBook.InputObject.InputTranslation }


{-| Create a page translation
-}
createTranslation :
    CreateTranslationRequiredArguments
    -> SelectionSet decodesTo GraphQLBook.Object.Translation
    -> SelectionSet (Maybe decodesTo) RootMutation
createTranslation requiredArgs object_ =
    Object.selectionForCompositeField "createTranslation" [ Argument.required "translation" requiredArgs.translation GraphQLBook.InputObject.encodeInputTranslation ] object_ (identity >> Decode.nullable)


type alias CreateTranslationBookOptionalArguments =
    { id : OptionalArgument GraphQLBook.ScalarCodecs.Id
    , notes : OptionalArgument String
    }


type alias CreateTranslationBookRequiredArguments =
    { author : String
    , bookId : GraphQLBook.ScalarCodecs.Id
    , languageId : String
    , title : String
    , translator : String
    }


{-| Create new book translation
-}
createTranslationBook :
    (CreateTranslationBookOptionalArguments -> CreateTranslationBookOptionalArguments)
    -> CreateTranslationBookRequiredArguments
    -> SelectionSet decodesTo GraphQLBook.Object.TranslationBook
    -> SelectionSet decodesTo RootMutation
createTranslationBook fillInOptionals requiredArgs object_ =
    let
        filledInOptionals =
            fillInOptionals { id = Absent, notes = Absent }

        optionalArgs =
            [ Argument.optional "id" filledInOptionals.id (GraphQLBook.ScalarCodecs.codecs |> GraphQLBook.Scalar.unwrapEncoder .codecId), Argument.optional "notes" filledInOptionals.notes Encode.string ]
                |> List.filterMap identity
    in
    Object.selectionForCompositeField "createTranslationBook" (optionalArgs ++ [ Argument.required "author" requiredArgs.author Encode.string, Argument.required "bookId" requiredArgs.bookId (GraphQLBook.ScalarCodecs.codecs |> GraphQLBook.Scalar.unwrapEncoder .codecId), Argument.required "languageId" requiredArgs.languageId Encode.string, Argument.required "title" requiredArgs.title Encode.string, Argument.required "translator" requiredArgs.translator Encode.string ]) object_ identity


type alias DeleteTranslationRequiredArguments =
    { id : GraphQLBook.ScalarCodecs.Id }


{-| Deletes a translation
-}
deleteTranslation :
    DeleteTranslationRequiredArguments
    -> SelectionSet decodesTo GraphQLBook.Object.Translation
    -> SelectionSet (Maybe decodesTo) RootMutation
deleteTranslation requiredArgs object_ =
    Object.selectionForCompositeField "deleteTranslation" [ Argument.required "id" requiredArgs.id (GraphQLBook.ScalarCodecs.codecs |> GraphQLBook.Scalar.unwrapEncoder .codecId) ] object_ (identity >> Decode.nullable)
