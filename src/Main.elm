port module Main exposing (main)

import Browser exposing (Document)
import Browser.Events
import Element
import Element.Background as Background
import Element.Border as Border
import Element.Input as Input
-- Event is singular on purpose
import Element.Events as Event
import Element.Font as Font
import Element.Region as Region
import Html exposing (..)
import Html.Attributes
import Html.Parser
import Http
import Platform.Sub as Sub exposing (batch)
import Platform.Cmd as Cmd exposing (Cmd)
import Mark
import Mark.Error exposing (Error)
import Parser exposing ( .. )
import Regex exposing(replace, Regex)
import List.Extra exposing (getAt, last, find, findIndex, setAt, updateAt, updateIf)
-- import Parser.Advanced exposing ((|.), (|=), Parser)
import String.Extra exposing (toTitleCase, toSentence, countOccurrences)
import MyParsers exposing (..)
import Palette exposing (scale, scaleFont, pageWidth, indent, outdent, show, hide)
import Models exposing (..)
import Json.Decode as Decode



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
            , body = (renderHeader meta.title meta.description) :: body
                -- renderTitle model meta
                --     :: body
--                Html.node "style" [] [ Html.text stylesheet ]
--                    :: Html.h1 [] meta.title
--                    :: body
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
                -- Toplevel Text
            --    , Mark.map (Html.p []) Mark.text
                ]
        }

emptyDivWithId : Model -> String -> Element.Element msg
emptyDivWithId model s =
    let 
        attrs = 
            [ (Html.Attributes.id s) |> Element.htmlAttribute
            , Html.Attributes.class "lessons" |> Element.htmlAttribute
            , pageWidth model
            ]
    in
    Element.textColumn attrs [Element.none]

showMenu : Model -> Element.Attribute msg
showMenu model =
    if model.showMenu then show else hide

menuOptions : Model -> Element.Element Msg
menuOptions model =
    Element.column [ showMenu model, scaleFont model 16 ]
        --[ clickOption "calendar" "Calendar"
        [ clickOption "morning_prayer" "Morning Prayer"
        , clickOption "midday" "Midday Prayer"
        , clickOption "evening_prayer" "Evening Prayer"
        , clickOption "compline" "Compline"
        , clickOption "family" "Family Prayer"
        , clickOption "reconciliation" "Reconciliation"
        , clickOption "toTheSick" "To the Sick"
        , clickOption "communionToSick" "Communion to Sick"
        , clickOption "timeOfDeath" "Time of Death"
        , clickOption "vigil" "Prayer for a Vigil"
        , Element.paragraph [] [Element.text "--"]
        , clickOption "sync" "Install Database"
        ]
    

lesson : Mark.Block (Model -> Element.Element Msg)
lesson =
    Mark.block "Lesson"
        (\request model ->
            let
                thisLesson = case (request |> String.trim) of
                    "lesson1" -> showLesson model model.lessons.lesson1
                    "lesson2" -> showLesson model model.lessons.lesson2
                    "psalms"  -> showPsalms model model.lessons.psalms
                    -- "gospel"  -> model.lessons.gospel
                    _         -> [Element.none]

            in
            
            Element.column []
            thisLesson
        )
        Mark.string

showPsalms : Model -> Lesson -> List (Element.Element Msg)
showPsalms model thisLesson =
    thisLesson.content |> List.map (\l ->
        let
            pss = l.vss 
                |> List.map (\v -> psalmLine model v.vs v.text )
                |> List.concat
            nameTitle = l.ref |> String.split "\n"
            thisName = nameTitle |> List.head |> Maybe.withDefault "" |> toTitleCase
            thisTitle = nameTitle |> getAt 1 |> Maybe.withDefault "" |> toTitleCase
        in
        Element.column 
        [ Element.paddingEach { top = 10, right = 40, bottom = 0, left = 0} 
        , Palette.maxWidth model
        ]
        (   Element.paragraph 
            (Palette.lessonTitle model) 
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

psalmLine : Model -> Int -> String -> List (Element.Element Msg)
psalmLine model lineNumber str =
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
            [ renderPsLine1 model lineNumber ln1
            , renderPsLine2 model ln2
            ]
        else
            [ renderPsSection model psTitle hebrew
            , renderPsLine1 model lineNumber ln1
            , renderPsLine2 model ln2
            ]

renderPsSection : Model -> Maybe String -> String -> Element.Element Msg
renderPsSection model title sectionName =
    Element.paragraph [ Element.paddingXY 10 10, Palette.maxWidth model ]
    [ Element.el [] (Element.text sectionName)
    , Element.el 
        [Font.italic, Element.paddingXY 20 0] 
        (Element.text (title |> Maybe.withDefault "") )
    ]

renderPsLine1 : Model -> Int -> String -> Element.Element Msg
renderPsLine1 model lineNumber ln1 =
    Element.paragraph [ indent "3rem", Palette.maxWidth model ]
    [ Element.el [outdent "3rem"] Element.none
    , Element.el 
        [ Font.color Palette.darkRed
        , Element.padding 5
        ]
        ( Element.text (String.fromInt lineNumber) )
    , Element.el [] (Element.text ln1)
    ]

renderPsLine2 : Model -> String -> Element.Element Msg
renderPsLine2 model ln2 =
    Element.paragraph [ indent "4rem" , Palette.maxWidth model ]
    [ Element.el [ outdent "2rem"] Element.none
    , Element.text ln2
    ]

showLesson : Model -> Lesson -> List (Element.Element Msg)
showLesson model thisLesson =
    thisLesson.content |> List.map (\l ->
        let
            -- put all the verse texts in to a single string (for parsing)
            -- and wrap in <p>...</p>, because sometimes the lesson will include </p><p>
            -- wrapping the whole thing fixes that
            vss = l.vss 
                |> List.foldr (\t acc -> t.text :: acc) [] 
                |> String.join " "
                |> fixPTags
                |> parseLine
        in
        
        Element.column ( Palette.lesson model )
        [ Element.paragraph (Palette.lessonTitle model) [Element.text l.ref]
        , Element.paragraph [ Palette.maxWidth model] vss
        ]
    )
    
fixPTags : String -> String
fixPTags str =
    let
        firstOpenedPTag = str |> String.indexes "<p" |> List.head |> Maybe.withDefault 0
        firstClosedPTag = str |> (String.indexes "</p") |> List.head |> Maybe.withDefault 0
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
    let
        parsed = Html.Parser.run str
    in
    case parsed of
        Ok nodes ->
            nodes |> List.map (\n -> parseNode n) |> List.concat

        Err msg ->
            [ Element.paragraph []
                [ Element.el [ Font.color Palette.darkRed] (Element.text "ERROR: COULDN'T PARSE STRING -> ")
                , Element.el [ Font.color Palette.darkBlue] (Element.text str)
                ]
            ]

-- we need parseNodes because Html.Parser.Element has a list of Nodes that will have to be parsed
parseNodes : List (Html.Parser.Node) -> List (Element.Element Msg)
parseNodes nodes =
    nodes |> List.map (\n -> parseNode n) |> List.concat

parseNode : Html.Parser.Node -> List (Element.Element Msg)
parseNode node = 
    case node of
        Html.Parser.Text s -> [Element.text s] 
        
        Html.Parser.Comment s -> [Element.none]

        Html.Parser.Element s attrs ndz ->
            newElement s attrs (parseNodes ndz)

newElement : String 
                -> List (Html.Parser.Attribute) 
                -> List (Element.Element Msg) 
                -> List (Element.Element Msg)
newElement ofType attrs withTheseEls =
    case ofType of
        "span" ->
            let
                thisClass = getClass attrs
                firstEl = getFirstEl withTheseEls
            in
            ( Element.el (Palette.class thisClass) firstEl)
            :: ( withTheseEls |> List.drop 1)
        "div" ->
            ( Element.paragraph 
                (Palette.class (getClass attrs) ) 
                [ getFirstEl withTheseEls ]
            )
            :: ( withTheseEls |> List.drop 1 )
        "p" ->
            ( Element.paragraph
                (Palette.class (getClass attrs) )
                [ getFirstEl withTheseEls ]
            )
            :: ( withTheseEls |> List.drop 1 )
        "br" ->
            ( Html.br [] [] |> Element.html )
            :: ( withTheseEls |> List.drop 1 )

        _ -> 
            ( Element.paragraph [Font.color Palette.darkRed] [Element.text ("Don't know tag: " ++ ofType)] )
            :: withTheseEls

getClass : List (Html.Parser.Attribute) -> String
getClass attrs =
    attrs
    |> List.filter (\tup -> (Tuple.first tup) == "class")
    |> List.head
    |> Maybe.withDefault ("class", "")
    |> Tuple.second

getFirstEl : List (Element.Element Msg) -> Element.Element Msg
getFirstEl list =
    list |> List.head |> Maybe.withDefault Element.none


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
                ( Palette.darkGrey
                , {angle = ang, steps = [Element.rgb255 233 255 2, Element.rgb255 237 239 210]}
                )
            "green" ->
                ( Palette.foggy
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
    (\model ->
        Element.column []
        [ Element.column (List.append (backgroundGradient model.color) (Palette.menu model) )
            [ Element.row [Element.paddingXY 20 0, Palette.maxWidth model]
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
                , Element.el [scaleFont model 18, Element.paddingXY 30 20] (Element.text "Legereme")
                , Element.el 
                    [ scaleFont model 14
                    , Font.color Palette.darkRed
                    , Font.alignRight
                    , Palette.adjustWidth model -230
                    ]
                    (Element.text model.online)
                ]
            , menuOptions model
            ]
        , Element.column ( Palette.officeTitle model )
            [ Element.paragraph
                [ Region.heading 1
                , scaleFont model 32
                , Font.center
                , Element.width (Element.px model.width)
                ]
                [ Element.text title ]
            , Element.paragraph 
                [ Font.center, scaleFont model 18] 
                [ Element.text model.today ]
            , Element.paragraph
                [ Font.center, scaleFont model 18]
                [ Element.text ((model.season |> toTitleCase) ++ " " ++ model.week) 
                , Element.el [Font.italic] (Element.text model.year)
                ]
            ]
        ]
    )


toggle: Mark.Block (Model -> Element.Element Msg)
toggle =
    Mark.block "Toggle"
        (\everything model ->
            let
                t = everything |> stringToOptions
                opts = case ( thisOptions t.tag model.options ) of
                    Just o -> o
                    Nothing ->
                        let
                            _ = update (UpdateOption t)
                        in
                        t
                btns = opts.options |> List.map (\o -> 
                    Input.button
                    (Palette.button model)
                    { onPress = Just (ClickToggle opts.tag o.tag opts)
                    , label = (Element.text o.label)
                    }
                    )
                selectedText = opts.options
                    |> List.foldl (\o acc ->
                        if o.selected == "True" then acc ++ o.text else acc
                        ) ""
            in
            Element.column []
            [ Element.el [ Palette.maxWidth model ] (Element.text opts.label)
            , Element.row [ Element.spacing 10, Element.padding 10 ] btns
            , Element.el [ Element.alignLeft, Palette.maxWidth model ] (Element.text selectedText)
            ]    
        )
        Mark.string

optionButtons : Model -> String -> { btns: List (Element.Element Msg), label: String, text: String }
optionButtons model everything =
    let
        t = everything |> stringToOptions
        opts = case ( thisOptions t.tag model.options ) of
            Just o -> o
            Nothing -> 
                let
                    _ = update (UpdateOption t)
                in 
                t

        btns = opts.options |> List.map(\o ->
            Input.button 
             (Palette.button model)
             -- opts.tag == the options group tag
             -- o.tag == the selected option tag
             { onPress = Just (ClickOption opts.tag o.tag opts) 
             , label = (Element.text o.label)
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

            Element.column [Element.paddingXY 10 0, Palette.maxWidth model] 
            [ Element.paragraph [] [Element.text opts.label]
            , Element.wrappedRow [ Element.spacing 10, Element.padding 10] opts.btns
            , Element.el [ Element.alignLeft, Palette.maxWidth model ] (Element.text opts.text)
            ]
        )
        Mark.string

optionalPsalms : Mark.Block (Model -> Element.Element Msg)
optionalPsalms =
    Mark.block "OptionalPsalms"
    (\everything model ->
        let
            opts = optionButtons model everything
            lns = parsePsalm model opts.text
        in
        
        Element.column [Element.paddingXY 10 0, Palette.maxWidth model] 
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
    |> List.map (\l -> stringToPsalmLine model l )

stringToPsalmLine : Model -> String -> Element.Element Msg
stringToPsalmLine model vs =
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
            renderPsLine2 model vs
        Just n ->
            renderPsLine1 model n (words |> List.tail |> Maybe.withDefault [] |> toSentence)

seasonal : Mark.Block (Model -> Element.Element Msg)
seasonal =
    Mark.block "Seasonal"
    (\everything model ->
        let
            (ofType, tList) = everything |> parseSeasonal
            (newModel, _) = update (UpdateOpeningSentences tList) model
            thisSeason = newModel.openingSentences 
                |> List.foldl (\os acc 
                    -> if os.tag == model.season || os.tag == "anytime"
                        then os :: acc
                        else acc
                    ) []
                |> List.reverse
                |> List.map (\os ->
                    Element.textColumn []
                    [ ( if os.label == "BLANK"
                        then Element.paragraph (Palette.rubric model) [Element.text "or this"]
                        else Element.paragraph (Palette.openingSentenceTitle model) [Element.text os.label]
                      )
                    , Element.paragraph (Palette.openingSentence model) [Element.text os.text]
                    , Element.paragraph (Palette.reference model) [Element.text os.ref]
                    ]
                )
        in

        Element.textColumn
        [ Palette.maxWidth model]
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
        case (Parser.run seasonalOpeningSentenceParser l) of
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
                    Element.textColumn [ Palette.maxWidth model ] 
                    [ Element.paragraph (Palette.openingSentenceTitle model)
                        [ Element.text (if os.label == "BLANK" then "" else os.label |> toTitleCase) ]
                    , Element.paragraph (Palette.openingSentence model) [Element.text (os.text |> collapseWhiteSpace)]
                    , Element.paragraph (Palette.reference model) [ Element.text (os.ref |> toTitleCase) ]
                    ]
                _ ->
                    Element.paragraph [] [Element.text "Opening Sentence Error"]
            
        )
        Mark.string


-- MODEL 

init : List Int -> ( Model, Cmd Msg )
init  list =
    let
        ht = list |> List.head |> Maybe.withDefault 0
        winWd = list |> getAt 1 |> Maybe.withDefault 375 -- iphone = 375
        wd = min winWd 800
        x = Element.classifyDevice { height = ht, width = wd}
        firstModel = { initModel | width = wd, windowWidth = winWd }
    in
    
    ( firstModel, requestOffice "currentOffice" )
    --( firstModel
    --, Http.get
    --    { url = "/services/morning_prayer.emu"
    --    , expect = Http.expectString GotSrc
    --    }
    --)

-- REQUEST PORTS


port requestReference : (List String) -> Cmd msg
port requestOffice : String -> Cmd msg
-- port requestReadings : String -> Cmd msg
port requestLessons : String -> Cmd msg
port toggleButtons : (List String) -> Cmd msg
port requestTodaysLessons : (String, CalendarDay) -> Cmd msg
port clearLessons : String -> Cmd msg
port changeMonth : (String, Int, Int) -> Cmd msg


-- SUBSCRIPTIONS


--port receivedReading : (Reading -> msg) -> Sub msg
port receivedCalendar : (List CalendarDay -> msg) -> Sub msg
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
--        , receivedPsalms UpdatePsalms
--        , receivedLesson1 UpdateLesson1
--        , receivedLesson2 UpdateLesson2
--        , receivedGospel UpdateGospel
        ]


type Msg 
    = NoOp
    | GotSrc (Result Http.Error String)
    | UpdateOption Options
    | ClickOption String String Options
    | ClickToggle String String Options
    | UpdateCalendar  (List CalendarDay)
    | UpdateOffice (List String)
    | UpdateLesson String
    | UpdateOnlineStatus String
    | UpdateOpeningSentences (List OpeningSentence)
    | DayClick CalendarDay
    | Office String
    | AltButton String String
    | RequestReference String String
    | TodaysLessons String CalendarDay
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
            (model, Cmd.none)

        UpdateOffice recvd ->
            let
                newModel = { model
                    | today = recvd |> requestedOfficeAt 0
                    , day = recvd |> requestedOfficeAt 1
                    , week = recvd |> requestedOfficeAt 2
                    , year = recvd |> requestedOfficeAt 3
                    , season = recvd |> requestedOfficeAt 4
                    , color = recvd |> requestedOfficeAt 5
                    , pageName = recvd |> requestedOfficeAt 6
                    , source = Just (recvd |> requestedOfficeAt 7 |> String.replace "\\n" "\n")
                    }

            in
            
            (newModel, requestLessons newModel.pageName )
            -- (newModel, Cmd.none )

        UpdateLesson s ->
            (addNewLesson s model, Cmd.none)

        UpdateOnlineStatus s ->
            ( {model | online = s}, Cmd.none )

        UpdateOpeningSentences l ->
            ( {model | openingSentences = l}, Cmd.none)
            
----

        DayClick day ->
            let
                -- newDay = { day | show = True}
                newCalendar = 
                    model.calendar 
                    |> updateIf (\d -> d.show) (\d -> { d | show = False})
                    |> updateAt day.id (\d -> { d | show = True})
                newModel = { model | calendar = newCalendar }
            in
                    
            ( newModel, Cmd.batch[ clearLessons "", Cmd.none ] )
                    
        Office o ->
            ( { model | showMenu = False}
            , Cmd.batch [requestOffice o, Cmd.none] 
            )

        AltButton altDiv buttonLabel ->
            (model, Cmd.batch [toggleButtons [altDiv, buttonLabel], Cmd.none] )  

        RequestReference readingId ref ->
            (model, Cmd.batch [requestReference [readingId, ref], Cmd.none] )  

        TodaysLessons office day ->
            (model, Cmd.batch[ requestTodaysLessons (office, day), Cmd.none])

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
        lessons = model.lessons
        newModel = case (Decode.decodeString lessonDecoder str) of
            Ok l    ->
                let
                    newLessons = case l.lesson of
                        "lesson1" -> {lessons | lesson1 = l }    
                        "lesson2" -> {lessons | lesson2 = l }    
                        "psalms"  -> {lessons | psalms = l }    
                        "gospel"  -> {lessons | gospel = l } 
                        _         -> lessons     
                in
                { model | lessons = newLessons }
            
            _       -> 
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
    case ( optionsIndex opt.tag oList ) of
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
                ((renderHeader "Getting Service" "Patience is a virtue") model)
            
            Just source ->
                case Mark.compile document source of
                    Mark.Success thisService ->
                        let
                        -- convert List (model -> Element.Element msg) to List (Element.Element msg)
                            rez = List.map (\fn -> fn model) thisService.body
                        in
                        Element.layout 
                        [ Html.Attributes.style "overflow" "hidden" |> Element.htmlAttribute
                        , Palette.scaleFont model 14
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