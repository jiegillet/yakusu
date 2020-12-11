module Route exposing (Route(..), fromUrl, link, replaceUrl)

import Browser.Navigation as Nav
import Element as El exposing (Attribute, Element)
import Url exposing (Url)
import Url.Builder exposing (QueryParameter)
import Url.Parser as Parser exposing ((</>), (<?>), Parser, int, oneOf, s, string)
import Url.Parser.Query as Query


type Route
    = Home
    | Login
    | Translation String
    | Books
    | AddBook
    | AddTranslation String


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Home Parser.top
        , Parser.map Login (s "login")
        , Parser.map Translation (s "translation" </> string)
        , Parser.map Books (s "books")
        , Parser.map AddBook (s "add")
        , Parser.map AddTranslation (s "translate" </> string)
        ]


routeToPieces : Route -> ( List String, List QueryParameter )
routeToPieces route =
    case route of
        Home ->
            ( [], [] )

        Login ->
            ( [ "login" ], [] )

        Translation id ->
            ( [ "translation", id ], [] )

        Books ->
            ( [ "books" ], [] )

        AddBook ->
            ( [ "add" ], [] )

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
