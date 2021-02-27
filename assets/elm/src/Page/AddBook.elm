module Page.AddBook exposing (Model, Msg, init, subscriptions, update, view)

import Animation
import Api exposing (Cred, GraphQLData)
import Api.Endpoint as Endpoint
import Base64
import Bytes exposing (Bytes, Endianness(..))
import Bytes.Decode
import Bytes.Encode
import Common exposing (Context, height, width)
import DnDList
import Element as El exposing (Attribute, Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input exposing (OptionState(..))
import File exposing (File)
import File.Select as Select
import GraphQLBook.Mutation as Mutation
import GraphQLBook.Object.Book as GBook
import GraphQLBook.Query as Query
import GraphQLBook.Scalar exposing (Id(..))
import Graphql.Http exposing (Error)
import Graphql.Operation exposing (RootQuery)
import Graphql.OptionalArgument as OptionalArgument
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Html.Attributes as Attributes
import Html.Events
import Http
import Json.Decode as Decode exposing (Decoder)
import LanguageSelect
import Page.Books exposing (Book)
import RemoteData exposing (RemoteData(..), WebData)
import Route
import Style
import Svg
import Svg.Attributes as S
import Types exposing (Category, Language)



-- TYPES


type alias Model =
    { context : Context
    , cred : Cred
    , bookId : Maybe String
    , editParams : { book : GraphQLData (Maybe Book), cmd : List (Cmd Msg), button : String, isNew : Bool }
    , book : GraphQLData (Maybe Book)
    , categories : GraphQLData (List Category)
    , languages : GraphQLData (List Language)
    , title : String
    , author : String
    , category : Maybe Category
    , language : LanguageSelect.Model Msg
    , hoverUploadBox : Bool
    , previews : List Image
    , oldImages : List Image
    , dnd : DnDList.Model
    , crossAnimation : Animation.State
    }


init : Context -> Cred -> Maybe String -> ( Model, Cmd Msg )
init context cred bookId =
    let
        editParams =
            case bookId of
                Nothing ->
                    { book = NotAsked
                    , cmd = []
                    , button = "Add Book"
                    , isNew = True
                    }

                Just id ->
                    { book = Loading
                    , cmd = [ getBook cred id, getPages cred id ]
                    , button = "Edit Book"
                    , isNew = False
                    }
    in
    ( { context = context
      , cred = cred
      , bookId = bookId
      , editParams = editParams
      , book = editParams.book
      , hoverUploadBox = False
      , previews = []
      , oldImages = []
      , categories = Loading
      , languages = Loading
      , language = LanguageSelect.init "Original Language" "attr-Title" LanguageMsg
      , dnd = system.model
      , title = ""
      , author = ""
      , category = Nothing
      , crossAnimation =
            Animation.style
                [ Animation.rotate (Animation.deg 0)
                , Animation.transformOrigin (Animation.percent 50) (Animation.percent 50) (Animation.percent 0)
                ]
      }
    , Cmd.batch (getCategories cred :: getlanguages cred :: editParams.cmd)
    )


type alias Image =
    { id : Maybe Int
    , file : Bytes
    , preview : String
    }


emptyImage : Image
emptyImage =
    Image Nothing (Bytes.Encode.sequence [] |> Bytes.Encode.encode) ""


config : DnDList.Config Image
config =
    { beforeUpdate = \_ _ list -> list
    , movement = DnDList.Free
    , listen = DnDList.OnDrag
    , operation = DnDList.Rotate
    }


system : DnDList.System Image Msg
system =
    DnDList.create config DnDMsg



-- HELPER


setAt : Int -> a -> List a -> List a
setAt index a list =
    if index >= 0 && index < List.length list then
        List.take index list ++ a :: List.drop (index + 1) list

    else
        list



-- UPDATE


type Msg
    = GotLanguages (GraphQLData (List Language))
    | GotCategories (GraphQLData (List Category))
    | GotExistingBook (GraphQLData (Maybe Book))
    | InputTitle String
    | InputAuthor String
    | ClickedCategory Category Bool
    | LanguageMsg LanguageSelect.Msg
      -- File Upload
    | GotExistingPages (WebData (List Image))
    | DragEnterUploadBox
    | DragLeaveUploadBox
    | ClickedUploadFiles
    | GotUploadedFiles File (List File)
    | GotCompressedImage (WebData ( Int, Image ))
    | DnDMsg DnDList.Msg
    | Animate Animation.Msg
    | DeleteImage Int
      -- Saving
    | ClickedSave
    | BookCreated (RemoteData (Error String) String)
    | PagesSaved String (WebData ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotLanguages result ->
            ( case result of
                Success languages ->
                    { model
                        | languages = result
                        , language = LanguageSelect.updateLanguageList languages model.language
                    }

                _ ->
                    { model | languages = result }
            , Cmd.none
            )

        LanguageMsg languageMsg ->
            let
                ( language, newMsg ) =
                    LanguageSelect.update languageMsg model.language
            in
            ( { model | language = language }, newMsg )

        GotCategories result ->
            ( { model | categories = result }, Cmd.none )

        GotExistingBook result ->
            case result of
                Success (Just { title, author, language, category }) ->
                    ( { model
                        | title = title
                        , author = author
                        , category = Just category
                        , language = LanguageSelect.updateLanguage language model.language
                      }
                    , Cmd.none
                    )

                _ ->
                    ( { model | book = result }, Cmd.none )

        InputTitle title ->
            ( { model | title = title }, Cmd.none )

        InputAuthor author ->
            ( { model | author = author }, Cmd.none )

        ClickedCategory category _ ->
            ( { model | category = Just category }, Cmd.none )

        -- File Upload
        GotExistingPages result ->
            case result of
                Success images ->
                    ( { model | previews = images, oldImages = images }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        DragEnterUploadBox ->
            ( { model | hoverUploadBox = True }, Cmd.none )

        DragLeaveUploadBox ->
            ( { model | hoverUploadBox = False }, Cmd.none )

        ClickedUploadFiles ->
            ( model, Select.files [ "image/*" ] GotUploadedFiles )

        GotUploadedFiles file files ->
            let
                filteredFiles =
                    List.filter (File.mime >> String.startsWith "image/") (file :: files)

                offset =
                    List.length model.previews
            in
            ( { model
                | hoverUploadBox = False
                , previews =
                    model.previews
                        ++ List.map (always emptyImage) filteredFiles
              }
            , filteredFiles
                |> List.indexedMap (\index -> uploadImage model.cred (index + offset))
                |> Cmd.batch
            )

        GotCompressedImage result ->
            case result of
                Success ( index, preview ) ->
                    ( { model | previews = setAt index preview model.previews }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        DnDMsg dndMsg ->
            let
                ( dnd, previews ) =
                    system.update dndMsg model.dnd model.previews

                cross =
                    case system.info dnd of
                        Just _ ->
                            Animation.interrupt
                                [ Animation.to [ Animation.rotate (Animation.deg 45) ] ]
                                model.crossAnimation

                        Nothing ->
                            Animation.interrupt
                                [ Animation.to [ Animation.rotate (Animation.deg 0) ] ]
                                model.crossAnimation
            in
            ( { model | dnd = dnd, previews = previews, crossAnimation = cross }
            , system.commands dnd
            )

        Animate animMsg ->
            ( { model | crossAnimation = Animation.update animMsg model.crossAnimation }, Cmd.none )

        DeleteImage index ->
            let
                previews =
                    List.take index model.previews ++ List.drop (index + 1) model.previews
            in
            ( { model | previews = previews }, Cmd.none )

        -- Saving
        ClickedSave ->
            -- TODO Full check: non-empty title author pages
            case ( model.category, LanguageSelect.getLanguage model.language ) of
                ( Just category, Just language ) ->
                    ( model
                    , createBook model.cred model.bookId model.title model.author language category
                    )

                _ ->
                    ( model, Cmd.none )

        BookCreated result ->
            case result of
                Success bookId ->
                    ( model, postPages model.cred bookId model.previews model.oldImages )

                _ ->
                    ( model, Cmd.none )

        PagesSaved bookId result ->
            case result of
                Success () ->
                    ( model, Route.replaceUrl model.context.key (Route.BookDetail bookId model.editParams.isNew) )

                _ ->
                    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ system.subscriptions model.dnd
        , LanguageSelect.subscriptions model.language
        , Animation.subscription Animate [ model.crossAnimation ]
        ]



-- VIEW


iconPlaceholder : Element msg
iconPlaceholder =
    El.el [ width 25, height 25, Background.color Style.nightBlue ] El.none
        |> El.el [ El.padding 5 ]


view : Model -> { title : String, body : Element Msg }
view model =
    let
        back =
            Route.link Route.Books
                [ Font.color Style.grey
                , Border.color Style.grey
                , Border.width 2
                ]
                (El.row [ El.paddingXY 10 5, height 40 ] [ iconPlaceholder, El.text "Back to Mainpage" ])
                |> El.el [ El.paddingEach { left = 40, right = 0, top = 0, bottom = 0 }, Font.size 20 ]

        explanation =
            El.row [ Background.color Style.grey, El.width El.fill, height 45, El.spacing 5, Font.size 20 ]
                [ iconPlaceholder
                , El.text "Please fill the following information and upload photos of the pages"
                ]
    in
    { title = "Original Book"
    , body =
        case ( model.categories, model.languages ) of
            ( Success categories, Success _ ) ->
                El.column
                    [ width 1000, El.spacing 30, El.paddingXY 0 30 ]
                    [ back
                    , explanation
                    , viewForm model categories
                    ]

            _ ->
                El.none
    }


viewForm : Model -> List Category -> Element Msg
viewForm { title, author, language, category, dnd, previews, crossAnimation, editParams } categories =
    El.column [ El.spacing 20, El.width El.fill, Font.size 18 ]
        [ LanguageSelect.view language
            |> El.el [ El.paddingEach { left = 40, right = 0, top = 0, bottom = 0 } ]
        , viewTextInput title "Title" InputTitle
        , viewTextInput author "Author(s)" InputAuthor
        , viewCategories category categories
        , viewPageDownload dnd crossAnimation previews
        , Input.button
            [ Font.color Style.nightBlue
            , Border.color Style.nightBlue
            , Border.width 2
            , El.alignRight
            ]
            { onPress = Just ClickedSave
            , label =
                El.row [ El.paddingXY 10 5, height 40, width 140 ] [ El.text editParams.button, iconPlaceholder ]
            }
        ]


viewTextInput : String -> String -> (String -> Msg) -> Element Msg
viewTextInput text label message =
    Input.text
        [ Border.color Style.nightBlue
        , Border.rounded 0
        , Border.width 2
        , El.spacing 10
        , width 340
        , height 42
        , El.padding 10

        -- This is for the input-in-radio bug workaround
        , El.htmlAttribute (Attributes.id ("attr-" ++ label))
        ]
        { onChange = message
        , text = text
        , placeholder = Nothing
        , label =
            Input.labelLeft [ El.height El.fill, Background.color Style.nightBlue ]
                (El.el [ width 100, El.padding 10, El.centerY ] (El.text label))
        }
        |> El.el [ El.paddingEach { left = 40, right = 0, top = 0, bottom = 0 } ]


viewCategories : Maybe Category -> List Category -> Element Msg
viewCategories category categories =
    let
        viewCategory ({ name } as cat) =
            Input.checkbox [ width 150, height 25 ]
                { onChange = ClickedCategory cat
                , checked = Just cat == category
                , icon =
                    \checked ->
                        El.text name
                            |> El.el [ El.centerX, El.centerY, Font.size 16 ]
                            |> El.el
                                [ width 150
                                , height 25
                                , if checked then
                                    Background.color Style.nightBlue

                                  else
                                    Background.color Style.grey
                                ]
                , label = Input.labelHidden name
                }
    in
    El.column [ El.spacing 20 ]
        [ El.row [ Background.color Style.grey, width 250, height 45, Font.size 20 ]
            [ iconPlaceholder, El.text "Select Theme" ]
        , categories
            |> List.map viewCategory
            |> El.wrappedRow [ El.paddingEach { top = 0, bottom = 0, left = 40, right = 10 }, El.spacing 10 ]
        ]
        |> El.el [ El.paddingEach { top = 5, bottom = 0, left = 0, right = 0 } ]


viewPageDownload : DnDList.Model -> Animation.State -> List Image -> Element Msg
viewPageDownload dnd crossAnimation images =
    El.column [ El.spacing 20, El.inFront (ghostView dnd images) ]
        [ El.row
            [ Background.color Style.grey
            , width 250
            , height 45
            , Font.size 20
            , Events.onClick ClickedUploadFiles
            ]
            [ iconPlaceholder, El.text "Add Pages" ]
            |> El.el [ El.paddingEach { top = 5, bottom = 0, left = 0, right = 0 } ]
        , El.row [ El.spacing 10 ]
            [ List.indexedMap (viewPreview dnd) images
                ++ [ viewAddOrDelete dnd crossAnimation ]
                |> El.wrappedRow
                    [ width 620
                    , El.spacingXY 10 30
                    , El.height (El.minimum 200 El.shrink)
                    ]
                |> El.el
                    [ Border.color Style.nightBlue
                    , El.padding 10
                    , Border.width 2
                    , hijackOn "dragenter" (Decode.succeed DragEnterUploadBox)
                    , hijackOn "dragover" (Decode.succeed DragEnterUploadBox)
                    , hijackOn "dragleave" (Decode.succeed DragLeaveUploadBox)
                    , hijackOn "drop" dropDecoder
                    ]
            , El.textColumn [ El.alignTop, Font.size 18, El.width El.fill, Font.color Style.nightBlue, El.spacing 10 ]
                [ El.paragraph [] [ El.text "Click on the + or drag images into the field to upload." ]
                , El.paragraph [] [ El.text "Drag the images to reorder. Drop on the x to remove." ]
                ]
            ]
            |> El.el [ El.paddingEach { top = 0, bottom = 5, left = 40, right = 0 } ]
        ]


dropDecoder : Decoder Msg
dropDecoder =
    Decode.at [ "dataTransfer", "files" ] (Decode.oneOrMore GotUploadedFiles File.decoder)


hijackOn : String -> Decoder msg -> Attribute msg
hijackOn event decoder =
    Html.Events.preventDefaultOn event (Decode.map hijack decoder)
        |> El.htmlAttribute


hijack : msg -> ( msg, Bool )
hijack msg =
    ( msg, True )


viewPreview : DnDList.Model -> Int -> Image -> Element Msg
viewPreview dnd index { preview } =
    let
        itemId : String
        itemId =
            "id-image-" ++ String.fromInt index

        baseAttributes =
            [ width 80
            , height 80
            , Border.width 2
            , Border.color Style.nightBlue
            , El.htmlAttribute (Attributes.id itemId)
            ]
    in
    case system.info dnd of
        Just { dragIndex } ->
            if dragIndex /= index then
                El.el
                    (Background.image preview
                        :: List.map El.htmlAttribute (system.dropEvents index itemId)
                        ++ baseAttributes
                    )
                    El.none

            else
                El.el
                    (Background.color Style.nightBlue :: baseAttributes)
                    El.none

        Nothing ->
            El.el
                (Background.image preview
                    :: baseAttributes
                    ++ List.map El.htmlAttribute (system.dragEvents index itemId)
                )
                El.none


ghostView : DnDList.Model -> List Image -> Element Msg
ghostView dnd previews =
    let
        maybeDragItem : Maybe Image
        maybeDragItem =
            system.info dnd
                |> Maybe.andThen (\{ dragIndex } -> previews |> List.drop dragIndex |> List.head)
    in
    case maybeDragItem of
        Just { preview } ->
            El.el
                (width 80
                    :: height 80
                    :: Background.image preview
                    :: List.map El.htmlAttribute (system.ghostStyles dnd)
                )
                El.none

        Nothing ->
            El.none


viewAddOrDelete : DnDList.Model -> Animation.State -> Element Msg
viewAddOrDelete dnd crossAnimation =
    Svg.svg
        (S.width "80"
            :: S.height "80"
            :: S.viewBox "0 0 80 80"
            :: S.fill "rgb(61, 152, 255)"
            :: Animation.render crossAnimation
        )
        [ Svg.g []
            [ Svg.rect [ S.x "32.5", S.y "10", S.width "15", S.height "60" ] []
            , Svg.rect [ S.x "10", S.y "32.5", S.width "60", S.height "15" ] []
            ]
        ]
        |> El.html
        |> El.el
            [ case system.info dnd of
                Nothing ->
                    Events.onClick ClickedUploadFiles

                Just { dragIndex } ->
                    Events.onMouseUp (DeleteImage dragIndex)
            ]



-- REST API


uploadImage : Cred -> Int -> File -> Cmd Msg
uploadImage cred page file =
    let
        body =
            Http.multipartBody
                [ Http.stringPart "page" (String.fromInt page)
                , Http.filePart "image" file
                ]

        expect =
            Http.expectBytes (RemoteData.fromResult >> GotCompressedImage) fileImageDecoder
    in
    Api.post Endpoint.pages cred body expect


fileImageDecoder : Bytes.Decode.Decoder ( Int, Image )
fileImageDecoder =
    let
        toUrl =
            Base64.fromBytes >> Maybe.withDefault "" >> (++) "data:image/jpeg;base64,"
    in
    Bytes.Decode.map2 Tuple.pair
        (Bytes.Decode.unsignedInt16 BE)
        (Bytes.Decode.unsignedInt32 BE
            |> Bytes.Decode.andThen
                (\length ->
                    Bytes.Decode.bytes length
                        |> Bytes.Decode.andThen
                            (\file -> Bytes.Decode.succeed (Image Nothing file (toUrl file)))
                )
        )


getPages : Cred -> String -> Cmd Msg
getPages cred bookId =
    let
        pageDecoder =
            Decode.map2 (\id preview -> { emptyImage | id = Just id, preview = preview })
                (Decode.field "id" Decode.int)
                (Decode.field "image" Decode.string)
                |> Decode.list
                |> Decode.field "data"
    in
    Api.get (Endpoint.allPages bookId) cred GotExistingPages pageDecoder


postPages : Cred -> String -> List Image -> List Image -> Cmd Msg
postPages cred bookId images oldImages =
    let
        newPages =
            List.indexedMap Tuple.pair images
                |> List.filter (\( _, { id } ) -> id == Nothing)

        deletePages =
            oldImages
                |> List.filterMap
                    (\image ->
                        if List.member image images then
                            Nothing

                        else
                            image.id
                    )

        reorderPages =
            List.indexedMap Tuple.pair images
                |> List.filterMap (\( index, image ) -> Maybe.map (\id -> ( String.fromInt index, String.fromInt id )) image.id)

        body =
            (List.map (Tuple.second >> .file >> Http.bytesPart "new_pages[]" "image/jpeg") newPages
                ++ List.map (Tuple.first >> String.fromInt >> Http.stringPart "new_pages_number[]") newPages
                ++ List.map (String.fromInt >> Http.stringPart "delete_pages[]") deletePages
                ++ List.map (Tuple.second >> Http.stringPart "reorder_pages[]") reorderPages
                ++ List.map (Tuple.first >> Http.stringPart "reorder_pages_number[]") reorderPages
            )
                |> Http.multipartBody

        expect =
            Http.expectWhatever (RemoteData.fromResult >> PagesSaved bookId)
    in
    Api.post (Endpoint.allPages bookId) cred body expect



-- GRAPHQL


getCategories : Cred -> Cmd Msg
getCategories cred =
    Api.queryRequest cred (Query.categories Types.categorySelection) GotCategories


getlanguages : Cred -> Cmd Msg
getlanguages cred =
    Api.queryRequest cred (Query.languages Types.languageSelection) GotLanguages


bookQuery : String -> SelectionSet (Maybe Book) RootQuery
bookQuery bookId =
    Query.book (Query.BookRequiredArguments (Id bookId)) Page.Books.bookSelection


getBook : Cred -> String -> Cmd Msg
getBook cred bookId =
    Api.queryRequest cred (bookQuery bookId) GotExistingBook


createBook : Cred -> Maybe String -> String -> String -> Language -> Category -> Cmd Msg
createBook cred bookId title author language category =
    let
        selection =
            Mutation.createBook (always { id = OptionalArgument.fromMaybe (Maybe.map Id bookId) })
                { author = author
                , categoryId = Id category.id
                , languageId = language.id
                , title = title
                }
                (SelectionSet.map Types.idToString GBook.id)
    in
    Api.mutationRequest cred selection BookCreated
