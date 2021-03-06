module LanguageSelect exposing (Model, Msg, english, getLanguage, init, japanese, showMissingFields, subscriptions, toEnglishOrJapanese, update, updateLanguage, updateLanguageList, view)

import Browser.Dom as Dom
import Browser.Events
import Element as El exposing (Color, Element)
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
    , showMissingField : Bool
    }


init : String -> String -> (Msg -> msg) -> Model msg
init labelText focus toMsg =
    { languages = []
    , selectLanguage = Japanese
    , languageDropdown = Closed
    , focus = focus
    , toMsg = toMsg
    , labelText = labelText
    , showMissingField = False
    }


updateLanguageList : List Language -> Model msg -> Model msg
updateLanguageList languages model =
    { model | languages = languages }


updateLanguage : Language -> Model msg -> Model msg
updateLanguage ({ id } as language) model =
    { model
        | selectLanguage =
            if id == "ja" then
                Japanese

            else if id == "en" then
                English

            else
                Other
        , languageDropdown =
            if id == "ja" then
                Closed

            else if id == "en" then
                Closed

            else
                Set language
    }


showMissingFields : Model msg -> Model msg
showMissingFields model =
    { model | showMissingField = True }


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
            Just english

        ( Japanese, _ ) ->
            Just japanese

        _ ->
            Nothing


english : Language
english =
    Language "en" "English"


japanese : Language
japanese =
    Language "ja" "Japanese"


toEnglishOrJapanese : String -> Maybe Language
toEnglishOrJapanese id =
    if id == "ja" then
        Just japanese

    else if id == "en" then
        Just english

    else
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
view ({ languageDropdown, selectLanguage, languages, toMsg, labelText, showMissingField } as model) =
    let
        color =
            if showMissingField && getLanguage model == Nothing then
                Style.lightRed

            else
                Style.lightCyan

        label txt state =
            El.row [ El.spacing 8, El.height (El.px 42), El.moveDown 6 ]
                [ case state of
                    Selected ->
                        Style.radioFull

                    _ ->
                        Style.radioEmpty
                , El.text txt
                    |> El.el [ El.centerY, El.centerX ]
                ]
    in
    Input.radioRow [ El.spacing 20, Font.size 18 ]
        { onChange = InputLanguage >> toMsg
        , label =
            Input.labelLeft [ El.paddingEach { top = 0, bottom = 0, left = 0, right = 20 } ]
                (El.text labelText
                    |> El.el [ El.padding 10, El.centerY, Font.size 18 ]
                    |> El.el [ Background.color Style.lightCyan, El.height (El.px 42), El.width (El.px 200) ]
                )
        , selected = Just selectLanguage
        , options =
            [ Input.optionWith Japanese (label "Japanese")
            , Input.optionWith English (label "English")
            , Input.optionWith Other (viewLanguageDropdown toMsg color languageDropdown languages)
            ]
        }


maybeToList : Maybe a -> List a
maybeToList maybe =
    case maybe of
        Nothing ->
            []

        Just a ->
            [ a ]


viewLanguageDropdown : (Msg -> msg) -> Color -> LanguageDropdown -> List Language -> OptionState -> Element msg
viewLanguageDropdown toMsg color dropdown languages state =
    let
        languageList text selectedLanguage =
            maybeToList selectedLanguage
                ++ (languages
                        |> List.filter
                            (\{ language } -> String.contains (String.toLower text) (String.toLower language))
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
                                [ Background.color color, Font.color Style.white ]

                            else
                                [ Background.color Style.white ]
                           )
                    )
    in
    El.row [ El.spacing 8, El.height (El.px 42), El.moveDown 6 ]
        [ case state of
            Selected ->
                Style.radioFull

            _ ->
                Style.radioEmpty
        , Input.search
            ([ El.width (El.px 262)
             , El.height El.fill
             , Border.width 2
             , Border.color color
             , Border.rounded 0
             , El.paddingXY 5 10
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
                                            , Border.color color
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
        ]
