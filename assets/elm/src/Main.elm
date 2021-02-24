module Main exposing (main)

import Api exposing (Cred)
import Browser
import Browser.Dom as Dom
import Browser.Events as Events
import Browser.Navigation as Nav exposing (Key)
import Common exposing (Context)
import Element as El
import Element.Font as Font
import Html exposing (Html)
import Json.Encode exposing (Value)
import Page.AddBook as AddBook
import Page.Blank as Blank
import Page.BookDetail as BookDetail
import Page.Books as Books
import Page.Login as Login
import Page.NotFound as NotFound
import Page.Translation as Translation
import Route exposing (Route(..))
import Task
import Url exposing (Url)


main : Program Value Model Msg
main =
    Api.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = ClickedLink
        , onUrlChange = ChangedUrl
        }


type Model
    = NotFound Context
    | Redirect Url Context
    | Books Books.Model
    | AddBook AddBook.Model
    | BookDetail BookDetail.Model
    | Translation Translation.Model
    | Login Login.Model


init : Maybe Cred -> Url -> Key -> ( Model, Cmd Msg )
init maybeCred url key =
    ( Redirect url (Context maybeCred key 0)
    , Cmd.batch
        [ Task.perform GotFirstWindowWidth
            (Task.map (.viewport >> .width >> round) Dom.getViewport)
        ]
    )


getContext : Model -> Context
getContext model =
    case model of
        NotFound context ->
            context

        Redirect _ context ->
            context

        Books { context } ->
            context

        AddBook { context } ->
            context

        BookDetail { context } ->
            context

        Translation { context } ->
            context

        Login { context } ->
            context


updateContext : (Context -> Context) -> Model -> Model
updateContext updtateContext model =
    case model of
        NotFound context ->
            NotFound (updtateContext context)

        Redirect url context ->
            Redirect url (updtateContext context)

        Books subModel ->
            Books { subModel | context = updtateContext subModel.context }

        AddBook subModel ->
            AddBook { subModel | context = updtateContext subModel.context }

        BookDetail subModel ->
            BookDetail { subModel | context = updtateContext subModel.context }

        Translation subModel ->
            Translation { subModel | context = updtateContext subModel.context }

        Login subModel ->
            Login { subModel | context = updtateContext subModel.context }



-- UPDATE


type Msg
    = GotFirstWindowWidth Int
    | GotWindowWidth Int
    | GotNewCred (Maybe Cred)
    | ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | ClickedLogOut
    | GotLoginMsg Login.Msg
    | GotBooksMsg Books.Msg
    | GotAddBookMsg AddBook.Msg
    | GotBookDetailMsg BookDetail.Msg
    | GotTranslationMsg Translation.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( GotFirstWindowWidth width, Redirect url context ) ->
            changeRouteTo (Route.fromUrl url)
                (Redirect url { context | windowWidth = width })

        ( GotWindowWidth width, _ ) ->
            ( updateContext (\context -> { context | windowWidth = width }) model
            , Cmd.none
            )

        ( GotNewCred cred, _ ) ->
            ( updateContext
                (\context ->
                    { context | cred = cred }
                )
                model
            , Cmd.none
            )

        ( ChangedUrl url, _ ) ->
            changeRouteTo (Route.fromUrl url) model

        ( ClickedLink urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Nav.pushUrl
                        (getContext model).key
                        (Url.toString url)
                    )

                Browser.External href ->
                    ( model, Nav.load href )

        ( ClickedLogOut, _ ) ->
            ( updateContext (\context -> { context | cred = Nothing }) model
            , Cmd.batch
                [ Api.logout
                , Route.replaceUrl (getContext model).key Route.Books
                ]
            )

        ( GotBooksMsg subMsg, Books subModel ) ->
            Books.update subMsg subModel
                |> updateWith Books GotBooksMsg

        ( GotAddBookMsg subMsg, AddBook subModel ) ->
            AddBook.update subMsg subModel
                |> updateWith AddBook GotAddBookMsg

        ( GotBookDetailMsg subMsg, BookDetail subModel ) ->
            BookDetail.update subMsg subModel
                |> updateWith BookDetail GotBookDetailMsg

        ( GotTranslationMsg subMsg, Translation subModel ) ->
            Translation.update subMsg subModel
                |> updateWith Translation GotTranslationMsg

        ( GotLoginMsg subMsg, Login subModel ) ->
            Login.update subMsg subModel
                |> updateWith Login GotLoginMsg

        ( _, _ ) ->
            ( model, Cmd.none )


updateWith :
    (subModel -> Model)
    -> (subMsg -> Msg)
    -> ( subModel, Cmd subMsg )
    -> ( Model, Cmd Msg )
updateWith toModel toMsg ( subModel, subCmd ) =
    ( toModel subModel, Cmd.map toMsg subCmd )


changeRouteTo : Maybe Route -> Model -> ( Model, Cmd Msg )
changeRouteTo maybeRoute model =
    let
        context =
            getContext model
    in
    case context.cred of
        Nothing ->
            context
                |> Login.init maybeRoute
                |> updateWith Login GotLoginMsg

        Just cred ->
            case maybeRoute of
                Nothing ->
                    ( NotFound context, Cmd.none )

                Just Route.Books ->
                    Books.init context cred
                        |> updateWith Books GotBooksMsg

                Just Route.AddBook ->
                    AddBook.init context cred Nothing
                        |> updateWith AddBook GotAddBookMsg

                Just (Route.EditBook bookId) ->
                    AddBook.init context cred (Just bookId)
                        |> updateWith AddBook GotAddBookMsg

                Just (Route.BookDetail bookId isNew) ->
                    BookDetail.init context cred bookId isNew
                        |> updateWith BookDetail GotBookDetailMsg

                Just (Route.AddTranslation bookId) ->
                    Translation.init context cred bookId Nothing
                        |> updateWith Translation GotTranslationMsg

                Just (Route.EditTranslation bookId trBookId) ->
                    Translation.init context cred bookId (Just trBookId)
                        |> updateWith Translation GotTranslationMsg

                Just Route.Login ->
                    Login.init (Just Route.Books) context
                        |> updateWith Login GotLoginMsg



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        context =
            getContext model

        common =
            [ Events.onResize (\w h -> GotWindowWidth w)
            , Api.storeChanged GotNewCred
            ]

        special =
            case model of
                Translation subModel ->
                    [ Sub.map GotTranslationMsg (Translation.subscriptions subModel) ]

                Login subModel ->
                    [ Sub.map GotLoginMsg (Login.subscriptions subModel) ]

                AddBook subModel ->
                    [ Sub.map GotAddBookMsg (AddBook.subscriptions subModel) ]

                _ ->
                    []
    in
    Sub.batch (common ++ special)



-- VIEW


view : Model -> { title : String, body : List (Html Msg) }
view model =
    let
        viewPageWith toMsg { title, body } =
            { title = title
            , body =
                El.column
                    [ El.width (El.px (getContext model).windowWidth)
                    , Font.family [ Font.typeface "clear_sans_lightregular" ]
                    ]
                    [ Common.viewHeader (getContext model) ClickedLogOut
                    , El.map toMsg body
                    ]
                    |> El.layout [ Font.size 14 ]
                    |> (\b -> [ b ])
            }
    in
    case model of
        NotFound _ ->
            viewPageWith never NotFound.view

        Redirect _ _ ->
            viewPageWith never Blank.view

        Books subModel ->
            viewPageWith GotBooksMsg (Books.view subModel)

        AddBook subModel ->
            viewPageWith GotAddBookMsg (AddBook.view subModel)

        BookDetail subModel ->
            viewPageWith GotBookDetailMsg (BookDetail.view subModel)

        Translation subModel ->
            viewPageWith GotTranslationMsg (Translation.view subModel)

        Login subModel ->
            viewPageWith GotLoginMsg (Login.view subModel)
