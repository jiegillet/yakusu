module LanguageSelect exposing (Model, Msg, getLanguage, init, subscriptions, update, updateLanguage, updateLanguageList, view)

import Browser.Dom as Dom
import Browser.Events
import Common exposing (height, width)
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input exposing (OptionState(..))
import Json.Decode as Decode
import Style
import Task
import Types exposing (Language)



-- TYPES


type alias Model msg =
    { languages : List Language
    , selectLanguage : SelectLanguage
    , languageDropdown : LanguageDropdown
    , focus : String
    , toMsg : Msg -> msg
    , labelText : String
    }


init : String -> String -> (Msg -> msg) -> Model msg
init labelText focus toMsg =
    { languages = []
    , selectLanguage = Japanese
    , languageDropdown = Closed
    , focus = focus
    , toMsg = toMsg
    , labelText = labelText
    }


updateLanguageList : List Language -> Model msg -> Model msg
updateLanguageList languages model =
    { model | languages = languages }


updateLanguage : Language -> Model msg -> Model msg
updateLanguage ({ id } as language) model =
    { model
        | selectLanguage =
            if id == "jp" then
                Japanese

            else if id == "en" then
                English

            else
                Other
        , languageDropdown =
            if id == "jp" then
                Closed

            else if id == "en" then
                Closed

            else
                Set language
    }


type SelectLanguage
    = Japanese
    | English
    | Other


type LanguageDropdown
    = Closed
    | Set Language
    | Open DropDownInfo


type alias DropDownInfo =
    { text : String
    , selectedLanguage : Maybe Language
    , hoveredLanguage : Maybe Language
    }


emptyDropdownInfo : DropDownInfo
emptyDropdownInfo =
    DropDownInfo "" Nothing Nothing


getLanguage : Model msg -> Maybe Language
getLanguage { selectLanguage, languageDropdown } =
    case
        ( selectLanguage, languageDropdown )
    of
        ( Other, Set lan ) ->
            Just lan

        ( English, _ ) ->
            Just (Language "en" "English")

        ( Japanese, _ ) ->
            Just (Language "jp" "Japanese")

        _ ->
            Nothing



-- UPDATE


type Msg
    = InputLanguage SelectLanguage
    | SelectLanguage SelectLanguage
    | EnteredSearchText String
    | ClickedwhileOpenDropDown
    | DropdownInfoChanged DropDownInfo


update : Msg -> Model msg -> ( Model msg, Cmd msg )
update msg model =
    case msg of
        InputLanguage language ->
            case language of
                Other ->
                    ( model
                    , Task.perform (always (SelectLanguage Other |> model.toMsg)) (Task.succeed ())
                    )

                _ ->
                    ( model
                      -- This is for the input-in-radio bug workaround https://github.com/mdgriffith/elm-ui/issues/250
                    , Task.attempt (always (SelectLanguage language |> model.toMsg)) (Dom.focus model.focus)
                    )

        SelectLanguage language ->
            ( { model | selectLanguage = language }, Cmd.none )

        EnteredSearchText search ->
            case model.languageDropdown of
                Closed ->
                    ( { model | languageDropdown = Open { emptyDropdownInfo | text = search } }, Cmd.none )

                Set lan ->
                    ( { model
                        | languageDropdown =
                            Open { emptyDropdownInfo | text = String.right 1 search, selectedLanguage = Just lan }
                      }
                    , Cmd.none
                    )

                Open info ->
                    ( { model | languageDropdown = Open { info | text = search } }, Cmd.none )

        ClickedwhileOpenDropDown ->
            let
                languageDropdown =
                    case model.languageDropdown of
                        Open { selectedLanguage } ->
                            case selectedLanguage of
                                Nothing ->
                                    Closed

                                Just lan ->
                                    Set lan

                        other ->
                            other
            in
            ( { model | languageDropdown = languageDropdown }, Cmd.none )

        DropdownInfoChanged dropdownInfo ->
            case model.languageDropdown of
                Open _ ->
                    ( { model | languageDropdown = Open dropdownInfo }, Cmd.none )

                other ->
                    ( { model | languageDropdown = other }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model msg -> Sub msg
subscriptions model =
    case model.languageDropdown of
        Open _ ->
            Sub.map model.toMsg
                (Browser.Events.onClick (Decode.succeed ClickedwhileOpenDropDown))

        _ ->
            Sub.none



-- VIEW


view : Model msg -> Element msg
view { languageDropdown, selectLanguage, languages, toMsg, labelText } =
    let
        label txt =
            El.text txt
                |> El.el [ El.centerY, El.centerX ]
                |> El.el [ height 42, width 60 ]
    in
    Input.radioRow [ El.spacing 30, Font.size 18 ]
        { onChange = InputLanguage >> toMsg
        , label =
            Input.labelLeft [ El.paddingEach { top = 0, bottom = 0, left = 0, right = 20 } ]
                (El.text labelText
                    |> El.el [ El.padding 10, El.centerY, Font.size 18 ]
                    |> El.el [ Background.color Style.nightBlue, height 42, width 200 ]
                )
        , selected = Just selectLanguage
        , options =
            [ Input.option Japanese (label "Japanese")
            , Input.option English (label "English")
            , Input.option Other (viewLanguageDropdown toMsg languageDropdown languages)
            ]
        }


maybeToList : Maybe a -> List a
maybeToList maybe =
    case maybe of
        Nothing ->
            []

        Just a ->
            [ a ]


viewLanguageDropdown : (Msg -> msg) -> LanguageDropdown -> List Language -> Element msg
viewLanguageDropdown toMsg dropdown languages =
    let
        languageList text selectedLanguage =
            maybeToList selectedLanguage
                ++ (languages
                        |> List.filter (\{ language } -> String.contains (String.toLower text) (String.toLower language))
                        |> List.sortBy .language
                        |> List.take 7
                   )

        viewDropdownLanguage info language =
            El.text language.language
                |> El.el
                    ([ El.width El.fill
                     , El.padding 2
                     , Events.onMouseEnter (DropdownInfoChanged { info | hoveredLanguage = Just language } |> toMsg)
                     , Events.onClick (DropdownInfoChanged { info | selectedLanguage = Just language } |> toMsg)
                     ]
                        ++ (if Just language == info.hoveredLanguage then
                                [ Background.color Style.nightBlue, Font.color Style.white ]

                            else
                                [ Background.color Style.white ]
                           )
                    )
    in
    Input.search
        ([ width 280
         , Border.width 2
         , Border.color Style.nightBlue
         , Border.rounded 0
         ]
            ++ (case dropdown of
                    Open ({ text, selectedLanguage } as info) ->
                        case languageList text selectedLanguage of
                            [] ->
                                []

                            list ->
                                [ list
                                    |> List.map (viewDropdownLanguage info)
                                    |> El.column
                                        [ El.width El.fill
                                        , Border.width 2
                                        , Border.color Style.nightBlue
                                        ]
                                    |> El.below
                                ]

                    _ ->
                        []
               )
        )
        { text =
            case dropdown of
                Closed ->
                    ""

                Set { language } ->
                    language

                Open { text } ->
                    text
        , onChange = EnteredSearchText >> toMsg
        , placeholder = Just (Input.placeholder [] (El.text "Other..."))
        , label = Input.labelHidden "Search language"
        }
