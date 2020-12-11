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
import Page.AddTranslation as AddTranslation
import Page.Blank as Blank
import Page.Books as Books
import Page.Home as Home
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
    | Home Context
    | Books Books.Model
    | AddBook AddBook.Model
    | AddTranslation AddTranslation.Model
    | Login Login.Model
    | Translation Translation.Model


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

        Home context ->
            context

        Books { context } ->
            context

        AddBook { context } ->
            context

        AddTranslation { context } ->
            context

        Login { context } ->
            context

        Translation { context } ->
            context


updateContext : (Context -> Context) -> Model -> Model
updateContext updtateContext model =
    case model of
        NotFound context ->
            NotFound (updtateContext context)

        Redirect url context ->
            Redirect url (updtateContext context)

        Home context ->
            Home (updtateContext context)

        Books subModel ->
            Books { subModel | context = updtateContext subModel.context }

        AddBook subModel ->
            AddBook { subModel | context = updtateContext subModel.context }

        AddTranslation subModel ->
            AddTranslation { subModel | context = updtateContext subModel.context }

        Login subModel ->
            Login { subModel | context = updtateContext subModel.context }

        Translation subModel ->
            Translation { subModel | context = updtateContext subModel.context }



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
    | GotAddTranslationMsg AddTranslation.Msg
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
                , Route.replaceUrl (getContext model).key Route.Home
                ]
            )

        ( GotBooksMsg subMsg, Books subModel ) ->
            Books.update subMsg subModel
                |> updateWith Books GotBooksMsg

        ( GotAddBookMsg subMsg, AddBook subModel ) ->
            AddBook.update subMsg subModel
                |> updateWith AddBook GotAddBookMsg

        ( GotAddTranslationMsg subMsg, AddTranslation subModel ) ->
            AddTranslation.update subMsg subModel
                |> updateWith AddTranslation GotAddTranslationMsg

        ( GotLoginMsg subMsg, Login subModel ) ->
            Login.update subMsg subModel
                |> updateWith Login GotLoginMsg

        ( GotTranslationMsg subMsg, Translation subModel ) ->
            Translation.update subMsg subModel
                |> updateWith Translation GotTranslationMsg

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

                Just Route.Home ->
                    ( Home context, Cmd.none )

                Just Route.Books ->
                    Books.init context
                        |> updateWith Books GotBooksMsg

                Just Route.AddBook ->
                    AddBook.init context
                        |> updateWith AddBook GotAddBookMsg

                Just (Route.AddTranslation bookId) ->
                    AddTranslation.init context bookId
                        |> updateWith AddTranslation GotAddTranslationMsg

                Just Route.Login ->
                    Login.init (Just Route.Home) context
                        |> updateWith Login GotLoginMsg

                Just (Route.Translation id) ->
                    Translation.init context id
                        |> updateWith Translation GotTranslationMsg



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
                El.column [ El.width (El.px (getContext model |> .windowWidth)) ]
                    [ --Common.viewHeader (getContext model) ClickedLogOut
                      El.map toMsg body
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

        Home _ ->
            viewPageWith never Home.view

        Books subModel ->
            viewPageWith never (Books.view subModel)

        AddBook subModel ->
            viewPageWith GotAddBookMsg (AddBook.view subModel)

        AddTranslation subModel ->
            viewPageWith GotAddTranslationMsg (AddTranslation.view subModel)

        Login subModel ->
            viewPageWith GotLoginMsg (Login.view subModel)

        Translation subModel ->
            viewPageWith GotTranslationMsg (Translation.view subModel)
