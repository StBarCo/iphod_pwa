port module Main exposing (main)

import Browser exposing (Document)
import Element
import Element.Background as Background
import Element.Input as Input
-- Event is singular on purpose
import Element.Events as Event
import Element.Font as Font
import Element.Region as Region
import Html exposing (..)
import Html.Attributes
import Html.Parser
import Html.Parser.Util
import Http
import Platform.Sub as Sub exposing (batch)
import Platform.Cmd as Cmd exposing (Cmd)
import Mark
import Mark.Error exposing (Error)
import Parser exposing (..)
import Regex exposing(replace)
import List.Extra exposing (getAt, find, findIndex, setAt, groupWhile)
-- import Parser.Advanced exposing ((|.), (|=), Parser)
import String.Extra exposing (toTitleCase, countOccurrences)
import MyParsers exposing (..)
import Palette exposing (scaleFont, pageWidth, indent, outdent, show, hide)
import Models exposing (..)
import Json.Decode as Decode
import Date


getSeason : Model -> String
getSeason m =
    m.season |> Tuple.first

{-| Here we define our document.

This may seem a bit overwhelming, but 95% of it is copied directly from `Mark.Default.document`. You can then customize as you see fit!

-}

--  document : Mark.Document
--          { body : List (Model -> Element.Element Msg)
--          , metadata : { description : String, maintainer : String, title : String }
--          }
document =
    Mark.documentWith
        (\meta body ->
            { metadata = meta
            , body = renderHeader meta.title meta.description :: body
            }
        )
        -- -- we have some required metadata that starts our document
        { metadata = service
        , body =
            Mark.manyOf
                [ rubric
                , quote
                , reference
                , prayer
                , plain
                , versicals 
                , psalmTitle
                , pageNumber
                , MyParsers.section
                , collectTitle
                , openingSentence
                , toggle
                , optionalPrayer
                , optionalPsalms
                , antiphon 
                , lesson
                , finish 
                , seasonal
                , calendar
                -- Toplevel Text
            --    , Mark.map (Html.p []) Mark.text
                ]
        }

calendar : Mark.Block (Model -> Element.Element Msg)
calendar =
    Mark.block "Calendar"
    (\month model ->
        let
            dayId = model.showThisCalendarDay
            align = if dayId < 0
                then [ Element.centerX ]
                else [ Element.alignLeft, Element.paddingXY 10 5 ]
            rows = if dayId < 0
                then
                    model.calendar 
                    |> groupWhile (\a b -> a.weekOfMon == b.weekOfMon)
                    |> List.map (\tup -> Tuple.first tup :: Tuple.second tup)
                    |> List.map (\week ->
                        let
                            thisWeek = 
                                week
                                |> List.map (\day ->
                                    Element.column 
                                    ( Event.onClick (ThisDay day) :: (backgroundGradient day.color ++ Palette.calendarDay model.width))
                                    [ Element.paragraph [ Element.padding 2 ] 
                                      [ Element.el [] (Element.text (day.dayOfMonth |> String.fromInt))
                                      , Element.el [ Element.padding 2 ] (Element.text day.pTitle)
                                      ]
                                    ]
                                )
                        in
                        Element.row [] thisWeek
                    )
                else
                    let
                        day = model.calendar 
                            |> getAt dayId
                            |> Maybe.withDefault initCalendarDay
                        
                    in
                    [ Element.column [Font.alignLeft]
                        [ serviceReadings Eucharist day model
                        , serviceReadings MorningPrayer day model
                        , serviceReadings EveningPrayer day model
                        , Input.button (Element.moveDown 20.0 :: Palette.button model.width)
                        { onPress = Just ShowCalendar
                        , label = Element.text "Return to Calendar"
                        }
                        ]
                    ]


        in
        Element.column align rows
        
    )
    Mark.string


referenceText : Int -> CalendarDay -> Service -> ReadingType -> List (Element.Element Msg)
referenceText width day thisService thisReading =
    let
        lezn = case (thisService, thisReading) of
            (Eucharist, Lesson1) -> day.eu.lesson1.content
            (Eucharist, Lesson2) -> day.eu.lesson2.content
            (Eucharist, Psalms) -> day.eu.psalms.content
            (Eucharist, Gospel) ->  day.eu.gospel.content
            (MorningPrayer, Lesson1) -> day.mp.lesson1.content
            (MorningPrayer, Lesson2) -> day.mp.lesson2.content
            (MorningPrayer, Psalms) -> day.mp.psalms.content
            (EveningPrayer, Lesson1) -> day.ep.lesson1.content
            (EveningPrayer, Lesson2) -> day.ep.lesson2.content
            (EveningPrayer, Psalms) -> day.ep.psalms.content
            (_, _) -> [] 
        in
        lezn 
        |> List.map(\r ->
            let
                ref = if r.style == "req"
                    then r.read
                    else "[" ++ r.read ++ "]"    
            in
            Element.paragraph
                ( Event.onClick (ThisReading thisService thisReading day) 
                :: Palette.readingRef r.style width 
                ) 
                [ Element.text ref]
        )

    
serviceReadings : Service -> CalendarDay -> Model -> Element.Element Msg
serviceReadings thisService day model =
    let
        width = model.width
        leznz = 
            case thisService of
                Eucharist ->
                    [ referenceText width day Eucharist Lesson1 
                    , showLesson model.eu.lesson1.content width
                    , referenceText width day Eucharist Psalms
                    , showPsalms model.eu.psalms.content width
                    , referenceText width day Eucharist Lesson2
                    , showLesson model.eu.lesson2.content width
                    , referenceText width day Eucharist Gospel
                    , showLesson model.eu.gospel.content width
                    ] |> List.concat
                MorningPrayer -> 
                    [ referenceText width day MorningPrayer Psalms
                    , showPsalms model.mp.psalms.content width
                    , referenceText width day MorningPrayer Lesson1
                    , showLesson model.mp.lesson1.content width
                    , referenceText width day MorningPrayer Lesson2
                    , showLesson model.mp.lesson2.content width
                    ] |> List.concat
                EveningPrayer -> 
                    [ referenceText width day EveningPrayer Psalms
                    , showPsalms model.ep.psalms.content width
                    , referenceText width day EveningPrayer Lesson1
                    , showLesson model.ep.lesson1.content width
                    , referenceText width day EveningPrayer Lesson2
                    , showLesson model.ep.lesson2.content width
                    ] |> List.concat


    in
    Element.column [] 
    ( Element.paragraph 
        ( Event.onClick (ThisReading thisService All day) 
        :: Palette.lessonTitle width 
        )
        [ Element.text (serviceTitle thisService) ]
      :: leznz
    )
    
showMenu : Bool -> Element.Attribute msg
showMenu bool =
    if bool then show else hide

menuOptions : Model -> Element.Element Msg
menuOptions model =
    Element.row []
    [ Element.column [ showMenu model.showMenu, scaleFont model.width 16, Element.paddingXY 20 0 ]
        [ clickOption "calendar" "Calendar"
        , clickOption "morning_prayer" "Morning Prayer"
        , clickOption "midday" "Midday Prayer"
        , clickOption "evening_prayer" "Evening Prayer"
        , clickOption "compline" "Compline"
        , clickOption "family" "Family Prayer"
        , clickOption "reconciliation" "Reconciliation"
        , clickOption "toTheSick" "To the Sick"
        , clickOption "communionToSick" "Communion to Sick"
        , clickOption "timeOfDeath" "Time of Death"
        , clickOption "vigil" "Prayer for a Vigil"
        ]
    , Element.column [ showMenu model.showMenu, scaleFont model.width 16, Element.paddingXY 20 0, Element.alignTop ]
        [ clickOption "about" "About"
        , clickOption "sync" "How to Install"
        , clickOption "sync" "Update Database"
        , clickOption "about" "Contact"
        ]
    ]
    

lesson : Mark.Block (Model -> Element.Element Msg)
lesson =
    Mark.block "Lesson"
        (\request model ->
            let
                thisLesson = case request |> String.trim of
                    "lesson1" -> showLesson model.lessons.lesson1.content model.width
                    "lesson2" -> showLesson model.lessons.lesson2.content model.width
                    "psalms"  -> showPsalms model.lessons.psalms.content model.width
                    "gospel"  -> showLesson model.lessons.gospel.content model.width
                    _         -> [Element.none]
    
            in
            
            Element.column (Palette.lesson model.width)
            ( List.concat
                [ [ Element.paragraph (Palette.lessonTitle model.width) [ Element.text "A Reading From..." ] ]
                , thisLesson
                , [ Element.paragraph [] [ Element.text "The Word of the Lord" ] ]
                ]
            )
        )
        Mark.string

showPsalms : List Reading -> Int -> List (Element.Element Msg)
showPsalms content width =
    content |> List.map (\l ->
        let
            pss = l.vss 
                |> List.map (\v -> psalmLine width v.vs v.text )
                |> List.concat
            nameTitle = l.read |> String.split "\n"
            thisName = nameTitle |> List.head |> Maybe.withDefault "" |> toTitleCase
            thisTitle = nameTitle |> getAt 1 |> Maybe.withDefault "" |> toTitleCase
        in
        Element.column 
        [ Element.paddingEach { top = 10, right = 40, bottom = 0, left = 0} 
        , Palette.maxWidth width
        ]
        (   Element.paragraph 
            (Palette.lessonTitle width) 
            [ Element.text thisName
            , Element.el 
                [ Font.alignRight
                , Font.italic
                , Element.paddingEach { top = 0, right = 0, bottom = 0, left = 20}
                ]
                (Element.text thisTitle)
            ]
        :: pss
        )
    )

psalmLine : Int -> Int -> String -> List (Element.Element Msg)
psalmLine width lineNumber str =
    let
        lns = str |> String.split "\n"
        -- lns |> List.head never return Nothing (in this case) 
        -- even if it's `Just ""`
        -- so a default is set and later check for empty String
        hebrew = lns |> List.head |> Maybe.withDefault ""
        psTitle = lns |> getAt 1
        ln1 = lns   |> getAt 2
                    |> Maybe.withDefault "" 
                    |> String.replace "&#42;" "*"
        ln2 = lns |> getAt 3 |> Maybe.withDefault ""

    in
    if hebrew |> String.isEmpty
        then
            [ renderPsLine1 width lineNumber ln1
            , renderPsLine2 width ln2
            ]
        else
            [ renderPsSection width psTitle hebrew
            , renderPsLine1 width lineNumber ln1
            , renderPsLine2 width ln2
            ]

renderPsSection : Int -> Maybe String -> String -> Element.Element Msg
renderPsSection width title sectionName =
    Element.paragraph [ Element.paddingXY 10 10, Palette.maxWidth width ]
    [ Element.el [] (Element.text sectionName)
    , Element.el 
        [Font.italic, Element.paddingXY 20 0] 
        (Element.text (title |> Maybe.withDefault "") )
    ]

renderPsLine1 : Int -> Int -> String -> Element.Element Msg
renderPsLine1 width lineNumber ln1 =
    Element.paragraph [ indent "3rem", Palette.maxWidth width ]
    [ Element.el [outdent "3rem"] Element.none
    , Element.el 
        [ Font.color Palette.darkRed
        , Element.padding 5
        ]
        ( Element.text (String.fromInt lineNumber) )
    , Element.el [] (Element.text ln1)
    ]

renderPsLine2 : Int -> String -> Element.Element Msg
renderPsLine2 width ln2 =
    Element.paragraph [ indent "4rem" , Palette.maxWidth width ]
    [ Element.el [ outdent "2rem"] Element.none
    , Element.text ln2
    ]

showLesson : List Reading -> Int -> List (Element.Element Msg)
showLesson content width =
    content |> versesFromLesson width

versesFromLesson : Int -> List Reading -> List (Element.Element Msg)
versesFromLesson width readings =
    let
        vss =
            readings
            |> List.map(\r ->
                let
                    rvss = 
                        r.vss
                        |> List.foldr (\t acc -> t.text :: acc) []
                        |> String.join " "
                        |> fixPTags
                        |> parseLine
                in
                Element.column (Palette.lesson width) rvss
            
            )

    in
    vss
    


fixPTags : String -> String
fixPTags str =
    let
        firstOpenedPTag = str |> String.indexes "<p" |> List.head |> Maybe.withDefault 0
        firstClosedPTag = str |> String.indexes "</p" |> List.head |> Maybe.withDefault 0
        openedPTags = str |> countOccurrences "<p"
        closedPTags = str |> countOccurrences "</p"
    in

    if firstClosedPTag < firstOpenedPTag then
        fixPTags ("<p>" ++ str)
    else if openedPTags > closedPTags then
        fixPTags (str ++ "</p>")
    else if closedPTags > openedPTags then
        fixPTags ("<p>" ++ str)
    else
        str
    

parseLine : String -> List (Element.Element Msg)
parseLine str = 
    case Html.Parser.run str of
        Ok nodes ->
            Html.Parser.Util.toVirtualDom nodes
            |> List.map (\el -> Element.html el)

        Err msg ->
            [ Element.paragraph []
                [ Element.el [ Font.color Palette.darkRed] (Element.text "ERROR: COULDN'T PARSE STRING -> ")
                , Element.el [ Font.color Palette.darkBlue] (Element.text str)
                ]
            ]


finish : Mark.Block (Model -> Element.Element Msg)
finish =
    Mark.block "Finish"
    (\office model ->
        Element.none
    )
    Mark.string

backgroundGradient : String -> List (Element.Attribute msg)
backgroundGradient s =
    let
        ang = 3.0
        (foreground, grad) = case s of
            "white" ->
                ( Palette.darkBlue
                , {angle = ang, steps = [Element.rgb255 233 255 2, Element.rgb255 237 239 210]}
                )
            "green" ->
                ( Palette.darkPurple
                , {angle = ang, steps = [Element.rgb255 23 102 10, Element.rgb255 226 255 221]}
                )
            "red"   ->
                ( Palette.foggy
                , {angle = ang, steps = [Element.rgb255 119 2 14, Element.rgb255 255 226 229]}
                )
            "violet"->
                ( Palette.foggy
                , {angle = ang, steps = [Element.rgb255 60 1 99, Element.rgb255 241 229 249]}
                )
            "blue"  ->
                ( Palette.foggy
                , {angle = ang, steps = [Element.rgb255 0 5 99, Element.rgb255 220 230 239]}
                )
            "rose"  ->
                ( Palette.darkGrey
                , {angle = ang, steps = [Element.rgb255 188 9 103, Element.rgb255 239 220 230]}
                )
            "gold"  ->
                ( Palette.darkGrey
                , {angle = ang, steps = [Element.rgb255 233 255 2, Element.rgb255 237 239 210]}
                )
            _       ->
                ( Palette.foggy
                , {angle = 1.0, steps = [Palette.foggy, Palette.foggy]}
                )
    in
    [ Font.color foreground, Background.gradient grad ]

clickOption : String -> String -> Element.Element Msg
clickOption request label =
    Element.el
    [ Event.onClick (Office request) ]
    ( Element.text label )


service : Mark.Block { description : String, maintainer : String, contact: String, title : String }
service =
    Mark.record "Service"
        (\maintainer contact title description ->
            { maintainer = maintainer
            , contact = contact
            , title = title
            , description = description
            }
        )
        |> Mark.field "maintainer" Mark.string
        |> Mark.field "contact" Mark.string
        |> Mark.field "title" Mark.string
        |> Mark.field "description" Mark.string
        |> Mark.toBlock


renderHeader : String -> String -> (Model -> Element.Element Msg)
renderHeader title description =
    \model ->
        Element.column []
        [ Element.column (List.append (backgroundGradient model.color) (Palette.menu model.width) )
            [ Element.row [Element.paddingXY 20 0, Palette.maxWidth model.width]
                [ Element.image 
                    ( List.append (backgroundGradient model.color)
                        [ Element.height (Element.px 36)
                        , Element.width (Element.px 35)
                        , Event.onClick ToggleMenu
                        ]
                    )
                    { src = "./menu.svg"
                    , description = "Toggle Menu"
                    }
                , Element.el [scaleFont model.width 18, Element.paddingXY 30 20] (Element.text "Legereme")
                , Element.el 
                    [ scaleFont model.width 14
                    , Font.color Palette.darkRed
                    , Font.alignRight
                    , Palette.adjustWidth model.width -230
                    ]
                    (Element.text model.online)
                ]
            , menuOptions model
            ]
        , Element.column ( Palette.officeTitle model.width )
            [ Element.paragraph
                [ Region.heading 1
                , scaleFont model.width 32
                , Font.center
                , Element.width (Element.px model.width)
                ]
                [ Element.text title ]
            , Element.paragraph 
                [ Font.center, scaleFont model.width 18] 
                [ Element.text model.today ]
            , Element.paragraph
                [ Font.center, scaleFont model.width 18]
                [ Element.text ((model |> getSeason |> toTitleCase) ++ " " ++ model.week) 
                , Element.el [Font.italic] (Element.text model.year)
                ]
            ]
        ]



toggle: Mark.Block (Model -> Element.Element Msg)
toggle =
    Mark.block "Toggle"
        (\everything model ->
            let
                t = everything |> stringToOptions
                opts = case thisOptions t.tag model.options of
                    Just o -> o
                    Nothing ->
                        let
                            _ = update (UpdateOption t)
                        in
                        t
                btns = opts.options |> List.map (\o -> 
                    Input.button
                    (Palette.button model.width)
                    { onPress = Just (ClickToggle opts.tag o.tag opts)
                    , label = Element.text o.label
                    }
                    )
                selectedText = opts.options
                    |> List.foldl (\o acc ->
                        if o.selected == "True" then acc ++ o.text else acc
                        ) ""
            in
            Element.column []
            [ Element.el [ Palette.maxWidth model.width ] (Element.text opts.label)
            , Element.row [ Element.spacing 10, Element.padding 10 ] btns
            , Element.el [ Element.alignLeft, Palette.maxWidth model.width ] (Element.text selectedText)
            ]    
        )
        Mark.string

optionButtons : Model -> String -> { btns: List (Element.Element Msg), label: String, text: String }
optionButtons model everything =
    let
        t = everything |> stringToOptions
        opts = case thisOptions t.tag model.options of
            Just o -> o
            Nothing -> 
                let
                    _ = update (UpdateOption t)
                in 
                t

        btns = opts.options |> List.map(\o ->
            Input.button 
             (Palette.button model.width)
             -- opts.tag == the options group tag
             -- o.tag == the selected option tag
             { onPress = Just (ClickOption opts.tag o.tag opts) 
             , label = Element.text o.label
             }
            )
        selectedText = opts.options
            |> List.foldl (\o acc ->
                if o.selected == "True" then acc ++ o.text else acc
            ) ""
    in
    { btns = btns, label = opts.label, text = selectedText }


optionalPrayer : Mark.Block (Model -> Element.Element Msg)
optionalPrayer =
    Mark.block "OptionalPrayer"
        (\everything model ->
            let
                opts = optionButtons model everything
            in

            Element.column [Element.paddingXY 10 0, Palette.maxWidth model.width] 
            [ Element.paragraph [] [Element.text opts.label]
            , Element.wrappedRow [ Element.spacing 10, Element.padding 10] opts.btns
            , Element.el [ Element.alignLeft, Palette.maxWidth model.width ] (Element.text opts.text)
            ]
        )
        Mark.string

optionalPsalms : Mark.Block (Model -> Element.Element Msg)
optionalPsalms =
    Mark.block "OptionalPsalms"
    (\everything model ->
        let
            opts = optionButtons model everything
        in
        
        Element.column [Element.paddingXY 10 0, Palette.maxWidth model.width] 
        (  Element.paragraph [] [Element.text opts.label]
        :: Element.wrappedRow [ Element.spacing 10, Element.padding 10] opts.btns
        :: parsePsalm model opts.text
        )
    )
    Mark.string

parsePsalm: Model -> String -> List ( Element.Element Msg )
parsePsalm model ps =
    ps 
    |> String.lines 
    |> List.map (\l -> stringToPsalmLine model.width l )

stringToPsalmLine : Int -> String -> Element.Element Msg
stringToPsalmLine width vs =
    -- if the first word of the line is digits
    -- consider it to be a verse number
    -- thus the first line of the verse
    -- else the second
    let
        words = vs |> String.words
        vsNum = words 
                |> List.head |> Maybe.withDefault ""
                |> String.toInt
    in
    case vsNum of
        Nothing -> 
            renderPsLine2 width vs
        Just n ->
            renderPsLine1 width n (
                words 
                |> List.tail 
                |> Maybe.withDefault [] 
                |> String.join " "
                )

seasonal : Mark.Block (Model -> Element.Element Msg)
seasonal =
    Mark.block "Seasonal"
    (\everything model ->
        let
            (_, tList) = everything |> parseSeasonal
            (newModel, _) = update (UpdateOpeningSentences tList) model
            thisSeason = newModel.openingSentences 
                |> List.foldl (\os acc 
                    -> if os.tag == getSeason model || os.tag == "anytime"
                        then os :: acc
                        else acc
                    ) []
                |> List.reverse
                |> List.map (\os ->
                    Element.textColumn []
                    [ if os.label == "BLANK"
                        then Element.paragraph (Palette.rubric model.width) [Element.text "or this"]
                        else Element.paragraph (Palette.openingSentenceTitle model.width) [Element.text os.label]
                    , Element.paragraph (Palette.openingSentence model.width) [Element.text os.text]
                    , Element.paragraph (Palette.reference model.width) [Element.text os.ref]
                    ]
                )
        in

        Element.textColumn
        [ Palette.maxWidth model.width]
        thisSeason
        
    )
    Mark.string
    
parseSeasonal : String -> ( String, List OpeningSentence )
parseSeasonal everything =
    let
        lns = everything |> String.split "--"
        ofType = lns |> List.head |> Maybe.withDefault "no_type"
        seasonList = lns |> linesToSeasonalList
    in
    (ofType, seasonList)
    
linesToSeasonalList : List String -> List OpeningSentence 
linesToSeasonalList lns =
    lns
    |> List.tail
    |> Maybe.withDefault []
    |> replaceSplitter
    |> List.map (\l ->
        case Parser.run seasonalOpeningSentenceParser l of
            Ok os -> os
            Err x ->
                { tag = "err"
                , label = "ERROR PARSING SEASONAL->"
                , ref = ""
                , text = "Text->\n" ++ l
                }

    )

openingSentence : Mark.Block (Model -> Element.Element msg)
openingSentence =
    Mark.block "OpeningSentence"
        (\parseThis model -> 
            let
                okParsed = Parser.run openingSentenceParser parseThis
            in
            case okParsed of
                Ok os ->
                    Element.textColumn [ Palette.maxWidth model.width ] 
                    [ Element.paragraph (Palette.openingSentenceTitle model.width)
                        [ Element.text (if os.label == "BLANK" then "" else os.label |> toTitleCase) ]
                    , Element.paragraph (Palette.openingSentence model.width) [Element.text (os.text |> collapseWhiteSpace)]
                    , Element.paragraph (Palette.reference model.width) [ Element.text (os.ref |> toTitleCase) ]
                    ]
                _ ->
                    Element.paragraph [] [Element.text "Opening Sentence Error"]
            
        )
        Mark.string


-- MODEL 

init : List Int -> ( Model, Cmd Msg )
init  list =
    let
        winWd = list |> getAt 1 |> Maybe.withDefault 375 -- iphone = 375
        wd = min winWd 800
        firstModel = { initModel | width = wd, windowWidth = winWd }
    in
    
    ( firstModel, Cmd.none )

-- REQUEST PORTS


port requestReference : (List String) -> Cmd msg
port requestOffice : String -> Cmd msg
-- port requestReadings : String -> Cmd msg
port requestLessons : String -> Cmd msg
port calendarReadingRequest : ServiceReadingRequest -> Cmd msg
port toggleButtons : (List String) -> Cmd msg
-- port requestTodaysLessons : (String, CalendarDay) -> Cmd msg
-- port clearLessons : String -> Cmd msg
port changeMonth : (String, Int, Int) -> Cmd msg


-- SUBSCRIPTIONS


--port receivedReading : (Reading -> msg) -> Sub msg
port receivedCalendar : (String -> msg) -> Sub msg
port receivedOffice : (List String -> msg) -> Sub msg
port receivedLesson : (String -> msg) -> Sub msg
port newWidth : (Int -> msg) -> Sub msg
port onlineStatus : (String -> msg) -> Sub msg
-- port receivedPsalms : (String -> msg) -> Sub msg
-- port receivedLesson1 : (String -> msg) -> Sub msg
-- port receivedLesson2 : (String -> msg) -> Sub msg
-- port receivedGospel : (String -> msg) -> Sub msg



subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ receivedCalendar UpdateCalendar
        , receivedOffice UpdateOffice
        , receivedLesson UpdateLesson
        , newWidth NewWidth
        , onlineStatus UpdateOnlineStatus
        ]

serviceToString : Service -> String
serviceToString s =
    case s of
        Eucharist -> "eu"
        MorningPrayer -> "mp"
        EveningPrayer -> "ep"

readingTypeToString : ReadingType -> String
readingTypeToString r =
    case r of
        Lesson1 -> "lesson1"
        Lesson2 -> "lesson2"
        Psalms  -> "psalms"
        Gospel  -> "gospel"
        All     -> "all"

serviceTitle : Service -> String
serviceTitle s =
    case s of
        Eucharist -> "Eucharist"
        MorningPrayer -> "Morning Prayer"
        EveningPrayer -> "Evening Prayer"

type Msg 
    = NoOp
    | GotSrc (Result Http.Error String)
    | UpdateOption Options
    | ClickOption String String Options
    | ClickToggle String String Options
    | UpdateCalendar String
    | UpdateOffice (List String)
    | UpdateLesson String
    | UpdateOnlineStatus String
    | UpdateOpeningSentences (List OpeningSentence)
    | ShowCalendar
    | Office String
    | AltButton String String
    | RequestReference String String
    | ThisDay CalendarDay
    | ThisReading Service ReadingType CalendarDay
    | ChangeMonth String Int Int
    | ToggleMenu
    | NewWidth Int

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        NoOp -> (model, Cmd.none)

        GotSrc result ->
            case result of
                Ok src ->
                    ( { model | source = Just src }
                    , Cmd.none
                    )

                Err err ->
                    ( model, Cmd.none )


        UpdateOption opts ->
            let
                newModel = { model | options = updateOptions opts model.options }
            in
            (newModel, Cmd.none)

        ClickOption grp t opts ->
            let
                newOpts = { opts | options = opts.options |> List.map 
                            (\o ->
                                if o.tag == t 
                                then { o | selected = "True"}
                                else { o | selected = "False"}
                            )
                        }
                
                newModel = {model | options = updateOptions newOpts model.options }
            in
            (newModel, Cmd.none)

        ClickToggle grp t opts ->
            let
                newOpts = { opts | options = opts.options |> List.map
                        (\o -> if o.selected == "True" 
                            then { o | selected = "False"}
                            else { o | selected = "True"}
                        )
                    }
                newModel = {model | options = updateOptions newOpts model.options}
            in
            (newModel, Cmd.none)
            

        UpdateCalendar daz ->
            let
                newModel = case Decode.decodeString calendarDecoder daz of
                    Ok cal ->
                        { model | calendar = cal.calendar}
                        
                    _  -> 
                        model
            in
            
            ( newModel, Cmd.none )
        
        UpdateOffice recvd ->
            let
                newModel = { model
                    | today = recvd |> requestedOfficeAt 0
                    , day = recvd |> requestedOfficeAt 1
                    , week = recvd |> requestedOfficeAt 2
                    , year = recvd |> requestedOfficeAt 3
                    , season = (recvd |> requestedOfficeAt 4, initTempSeason)
                    , color = recvd |> requestedOfficeAt 5
                    , pageName = recvd |> requestedOfficeAt 6
                    , source = Just (recvd |> requestedOfficeAt 7 |> String.replace "\\n" "\n")
                    }

            in
            
            (newModel, requestLessons newModel.pageName )

        UpdateLesson s ->
            (addNewLesson s model, Cmd.none)

        UpdateOnlineStatus s ->
            let
                thisCmd = if s == "All Ready"
                    then requestOffice "currentOffice"
                    else Cmd.none
            in
            
            ( {model | online = s}, thisCmd )

        UpdateOpeningSentences l ->
            ( {model | openingSentences = l}, Cmd.none)
            
----

        ShowCalendar ->
            let
                temp = model.season |> Tuple.second
                newModel = { model 
                            | season = (temp.season, initTempSeason)
                            , week = temp.week
                            , year = temp.year
                            , today = temp.today
                            , showThisCalendarDay = -1
                            }
            in
            ( newModel, Cmd.none )
                    
        Office o ->
            ( { model | showMenu = False}
            , Cmd.batch [requestOffice o, Cmd.none] 
            )

        AltButton altDiv buttonLabel ->
            (model, Cmd.batch [toggleButtons [altDiv, buttonLabel], Cmd.none] )  

        RequestReference readingId ref ->
            (model, Cmd.batch [requestReference [readingId, ref], Cmd.none] )  

        ThisDay day ->
            let
                today = 
                    Date.fromCalendarDate day.year (Date.numberToMonth (day.month + 1)) day.dayOfMonth
                    |> Date.format "EEEE, d MMMM y"
                season = if String.isEmpty day.pTitle
                            then { season = day.season, week = day.week, year = day.lityear, today = model.today}
                            else { initTempSeason | season = day.pTitle}
                tempSeason = {season = getSeason model, week = model.week, year = model.year, today = model.today}
            in
            
            ( { model 
                | showThisCalendarDay = day.id
                , today = today
                , season = (season.season, tempSeason)
                , week = season.week
                , year = season.year
                , eu = initLessons
                , mp = initLessons
                , ep = initLessons
                }
            , Cmd.none
            )

        ThisReading thisService thisReading day -> 
            let
                servRequest = 
                    { id = day.id
                    , reading = readingTypeToString thisReading
                    , service = serviceToString thisService
                    , dayOfMonth = day.dayOfMonth
                    , month = day.month
                    , year = day.year
                    }
                newModel = 
                    { model
                    | lessons = initLessons
                    , eu = initLessons
                    , mp = initLessons
                    , ep = initLessons
                    }
            in
            (newModel, Cmd.batch [ calendarReadingRequest servRequest, Cmd.none ] )
            

        ChangeMonth toWhichMonth month year ->
            (model, Cmd.batch [changeMonth (toWhichMonth, month, year), Cmd.none] ) 

        ToggleMenu ->
            ( { model | showMenu = not model.showMenu }, Cmd.none )

        NewWidth i ->
            ( { model 
                | windowWidth = i
                , width = (min i 500) - 20
            }, Cmd.none)


addNewLesson : String -> Model -> Model
addNewLesson str model =
    let
        newModel = case Decode.decodeString lessonDecoder str of
            Ok l ->
                let
                    lessons = case l.spa_location of
                        "eu" -> model.eu
                        "mp" -> model.mp
                        "ep" -> model.ep
                        -- default is office
                        _ -> model.lessons
                

                    newLessons = case l.lesson of
                        "lesson1" -> {lessons | lesson1 = l }
                        "lesson2" -> {lessons | lesson2 = l }
                        "psalms"  -> {lessons | psalms = l }
                        "gospel"  -> {lessons | gospel = l }
                        _         -> lessons
                    
                in
                case l.spa_location of
                    "eu" -> { model | eu = newLessons }
                    "mp" -> { model | mp = newLessons }
                    "ep" -> { model | ep = newLessons }
                    -- default is office
                    _ -> { model | lessons = newLessons }
            
            _  -> 
                model
    in
    newModel
                    
requestedOfficeAt : Int -> List String -> String
requestedOfficeAt i list =
    list |> getAt i |> Maybe.withDefault ""

thisOptions : String -> List Options -> Maybe Options
thisOptions tag opts =
    opts |> find (\o -> tag == o.tag)

updateOptions : Options -> List Options -> List Options
updateOptions opt oList =
    case optionsIndex opt.tag oList of
        Just i ->
            oList |> setAt i opt
        Nothing ->
            opt :: oList

optionsIndex : String -> List Options -> Maybe Int
optionsIndex tag olist =
    olist |> findIndex (\o -> o.tag == tag)
    
view : Model -> Document Msg
view model =
    { title = "Legereme"
    , body = 
        [ case model.source of
            Nothing ->
                Element.layout []
                (renderHeader "Getting Service" "Patience is a virtue" model)
            
            Just source ->
                case Mark.compile document source of
                    Mark.Success thisService ->
                        let
                            rez = List.map (\fn -> fn model) thisService.body
                        in
                        Element.layout 
                        [ Html.Attributes.style "overflow" "hidden" |> Element.htmlAttribute
                        , Palette.scaleFont model.width 14
                        ] 
                        ( Element.column [ ] rez )

                    -- Mark.Almost {resp, errors} ->
                    Mark.Almost x ->
                        -- this is the case where there has been an error,
                        -- but it hs been caught by `Mark.onError` and is still rendeable
                        -- let
                        -- -- convert List (model -> Element.Element msg) to List (Element.Element msg)
                        --     rez = List.map (\fn -> fn model) thisService.body
                        -- in
                        Element.layout [] ( Element.paragraph [] [ Element.text "ERRORS GO HERE" ] )
                        -- Element.layout []
                        -- ( Element.column [] 
                        --    ( List.concat [(viewErrors errors), rez] )
                        -- )

                    Mark.Failure errors ->
                        Element.layout []
                        ( Element.column [] (viewErrors errors) )
        ]
    }


viewErrors : List Error -> List (Element.Element Msg)
viewErrors errors =
    List.map
        (Mark.Error.toHtml Mark.Error.Light)
        errors
    |> List.map Element.html

main =
    Browser.document
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }

