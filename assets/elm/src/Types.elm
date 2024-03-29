module Types exposing (..)

import Dict exposing (Dict)
import Dict.Extra as Dict
import GraphQLBook.Object
import GraphQLBook.Object.Book as GBook
import GraphQLBook.Object.Category as GCategory
import GraphQLBook.Object.Language as GLanguage
import GraphQLBook.Object.Page as GPage
import GraphQLBook.Object.Translation as GTranslation
import GraphQLBook.Object.TranslationBook as TBook
import GraphQLBook.Scalar exposing (Id(..))
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
    , language : Language
    , category : Category
    , translations : List TranslationBook
    , pages : Dict String Page
    }


type alias Category =
    { id : String, name : String }


type alias Language =
    { id : String, language : String }


type alias TranslationBook =
    { id : String
    , title : String
    , author : String
    , language : Language
    , translator : String
    , notes : String
    , translations : Dict String Translation
    }


type alias Page =
    { id : String
    , image : String
    , width : Int
    , height : Int
    , imageType : String
    , pageNumber : Int
    }


type alias Translation =
    { id : String
    , pageId : String
    , text : String
    , path : String
    }



-- GraphQL


bookSelection : SelectionSet Book GraphQLBook.Object.Book
bookSelection =
    SelectionSet.map7 Book
        (SelectionSet.map idToString GBook.id)
        GBook.title
        GBook.author
        (GBook.language languageSelection)
        (GBook.category categorySelection)
        (GBook.bookTranslations translationBookSelection)
        (SelectionSet.map toDict (GBook.pages pageSelection))


translationBookSelection : SelectionSet TranslationBook GraphQLBook.Object.TranslationBook
translationBookSelection =
    SelectionSet.map7 TranslationBook
        (SelectionSet.map idToString TBook.id)
        TBook.title
        TBook.author
        (TBook.language languageSelection)
        TBook.translator
        TBook.notes
        (SelectionSet.map toDict (TBook.translations translationSelection))


pageSelection : SelectionSet Page GraphQLBook.Object.Page
pageSelection =
    SelectionSet.map6 Page
        (SelectionSet.map idToString GPage.id)
        GPage.image
        GPage.width
        GPage.height
        GPage.imageType
        GPage.pageNumber


categorySelection : SelectionSet Category GraphQLBook.Object.Category
categorySelection =
    SelectionSet.map2 Category
        (SelectionSet.map idToString GCategory.id)
        GCategory.name


languageSelection : SelectionSet Language GraphQLBook.Object.Language
languageSelection =
    SelectionSet.map2 Language
        GLanguage.id
        GLanguage.language


translationSelection : SelectionSet Translation GraphQLBook.Object.Translation
translationSelection =
    SelectionSet.map4 Translation
        (SelectionSet.map idToString GTranslation.id)
        (SelectionSet.map idToString GTranslation.pageId)
        GTranslation.text
        GTranslation.path


toDict : List { a | id : comparable } -> Dict comparable { a | id : comparable }
toDict =
    List.map (\({ id } as a) -> ( id, a ))
        >> Dict.fromList
