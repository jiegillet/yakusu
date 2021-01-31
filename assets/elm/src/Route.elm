module Route exposing (Route(..), fromUrl, link, replaceUrl)

import Browser.Navigation as Nav
import Element as El exposing (Attribute, Element)
import Url exposing (Url)
import Url.Builder exposing (QueryParameter)
import Url.Parser as Parser exposing ((</>), (<?>), Parser)
import Url.Parser.Query as Query


type Route
    = Login
    | Translation String
    | Books
    | AddBook
    | EditBook String
    | BookDetail String Bool
    | AddTranslation String


parser : Parser (Route -> a) a
parser =
    let
        toBool maybeStatus =
            case maybeStatus of
                Just "new" ->
                    True

                _ ->
                    False
    in
    Parser.oneOf
        [ Parser.map Books Parser.top
        , Parser.map Login (Parser.s "login")
        , Parser.map Translation (Parser.s "translation" </> Parser.string)
        , Parser.map EditBook (Parser.s "book" </> Parser.s "edit" </> Parser.string)
        , Parser.map AddBook (Parser.s "book" </> Parser.s "add")
        , Parser.map BookDetail (Parser.s "book" </> Parser.s "detail" </> Parser.string <?> (Query.string "status" |> Query.map toBool))
        , Parser.map AddTranslation (Parser.s "translate" </> Parser.string)
        ]


routeToPieces : Route -> ( List String, List QueryParameter )
routeToPieces route =
    case route of
        Books ->
            ( [], [] )

        Login ->
            ( [ "login" ], [] )

        AddBook ->
            ( [ "book", "add" ], [] )

        EditBook bookId ->
            ( [ "book", "edit", bookId ], [] )

        BookDetail id True ->
            ( [ "book", "detail", id ], [ Url.Builder.string "status" "new" ] )

        BookDetail id False ->
            ( [ "book", "detail", id ], [] )

        Translation id ->
            ( [ "translation", id ], [] )

        AddTranslation id ->
            ( [ "translate", id ], [] )


fromUrl : Url -> Maybe Route
fromUrl url =
    Parser.parse parser url


link : Route -> List (Attribute msg) -> Element msg -> Element msg
link route attr label =
    El.link attr (routeToLink label route)


routeToLink : Element msg -> Route -> { url : String, label : Element msg }
routeToLink label route =
    let
        ( pieces, queries ) =
            routeToPieces route
    in
    { url = Url.Builder.absolute pieces queries
    , label = label
    }


replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl key route =
    routeToLink El.none route
        |> .url
        |> Nav.pushUrl key
