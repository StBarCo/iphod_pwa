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
import Markdown
import Platform.Sub as Sub exposing (batch)
import Platform.Cmd as Cmd exposing (Cmd)
import Mark
import Mark.Default
import Parser exposing ( .. )
import Regex exposing(replace, Regex)
import List.Extra exposing (getAt, last, find, findIndex, setAt, updateAt, updateIf)
-- import Parser.Advanced exposing ((|.), (|=), Parser)
import String.Extra exposing (toTitleCase)
import MyParsers exposing (..)
import Palette exposing (scale, scaleFont, pageWidth)
import Models exposing (..)
import Json.Decode as Decode



{-| Here we define our document.

This may seem a bit overwhelming, but 95% of it is copied directly from `Mark.Default.document`. You can then customize as you see fit!

-}
document =
    let
        defaultText =
            Mark.Default.textWith
                { code = Mark.Default.defaultTextStyle.code
                , link = Mark.Default.defaultTextStyle.link
                , inlines =
                    [ Mark.inline "Drop"
                        (\txt model ->
                            Element.row [ Font.variant Font.smallCaps ]
                                (List.map (\item -> Mark.Default.textFragment item model) txt)
                        )
                        |> Mark.inlineText
                    ]
                , replacements = Mark.Default.defaultTextStyle.replacements
                }
    in
    Mark.document
        (\children model ->
            Element.textColumn
                [ Element.spacing (scale model 18)
                , Element.padding 10
                , Element.centerX
                , pageWidth model
                , scaleFont model 18
                ]
                (List.map (\child -> child model) children)
        )
        (Mark.startWith
            (\myTitle myContent ->
                myTitle :: myContent
            )
            ( begining )
            (Mark.manyOf
                [ title [ Font.size 48, Font.center ] defaultText
                , Mark.Default.header [ Font.size 36 ] defaultText
                , Mark.Default.image []
                , rubric
                , quote
                , reference
                , prayer
                , plain
                , versicals 
                , psalmTitle
                , pageNumber
                , MyParsers.section
                , collectTitle defaultText
                , openingSentence
                , toggle
                , options
                , antiphon 
                , lesson
                , finish 
                -- Toplevel Text
                , Mark.map (\viewEls model -> 
                    Element.paragraph 
                        [ Font.alignLeft
                        ] 
                        (viewEls model)
                    ) 
                    defaultText
                ]
            )
        )

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

hide : Element.Attribute msg
hide = 
    Html.Attributes.style "display" "none"
    |> Element.htmlAttribute

show : Element.Attribute msg
show = 
    Html.Attributes.style "display" "block"
    |> Element.htmlAttribute

showMenu : Model -> Element.Attribute msg
showMenu model =
    if model.showMenu then show else hide

menuOptions : Model -> Element.Element Msg
menuOptions model =
    Element.column [ showMenu model, scaleFont model 18 ]
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
                |> List.map (\v -> psalmLine v.vs v.text )
                |> List.concat
            nameTitle = l.ref |> String.split "\n"
            thisName = nameTitle |> List.head |> Maybe.withDefault "" |> toTitleCase
            thisTitle = nameTitle |> getAt 1 |> Maybe.withDefault "" |> toTitleCase
        in
        Element.column [ Element.paddingEach { top = 10, right = 40, bottom = 0, left = 0} ]
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

psalmLine : Int -> String -> List (Element.Element Msg)
psalmLine n str =
    let
        lns = str |> String.split "\n"
        hebrew = lns |> List.head |> Maybe.withDefault ""
        psTitle = lns |> getAt 1 |> Maybe.withDefault ""
        ln1 = lns   |> getAt 2
                    |> Maybe.withDefault "" 
                    |> String.replace "&#42;" "*"
        ln2 = lns |> getAt 3 |> Maybe.withDefault ""
        psSection = if hebrew |> String.isEmpty
            then Element.none
            else
                Element.paragraph [Element.paddingXY 0 10]
                [ Element.el 
                    [ Element.htmlAttribute <| Html.Attributes.style "margin-left" "-3rem"]
                    (Element.text hebrew)
                , Element.el [Font.italic, Element.paddingXY 20 0] (Element.text psTitle)
                ]

    in
    -- all the weird margin-left stuff is for outdenting
    [ Element.paragraph [Element.htmlAttribute <| Html.Attributes.style "margin-left" "3rem"]
        [ psSection
        , Element.el [Element.htmlAttribute <| Html.Attributes.style "margin-left" "-3rem"] Element.none
        , Element.el 
            [ Font.color Palette.darkRed
            , Element.padding 5
            ]
            ( Element.text ( String.fromInt n ) )
        , Element.el [] (Element.text ln1)
        ]
    , Element.paragraph [Element.htmlAttribute <| Html.Attributes.style "margin-left" "4rem"] 
        [ Element.el [Element.htmlAttribute <| Html.Attributes.style "margin-left" "-2rem"] Element.none 
        , Element.text ln2 
        ]
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
        
        Element.column []
        [ Element.paragraph (Palette.lessonTitle model) [Element.text l.ref]
        , Element.paragraph [] vss
        ]
    )
    
fixPTags : String -> String
fixPTags str =
    let
        openP = str |> String.indexes "<p"
        closeP = str |> String.indexes "/p"

        openP1 = openP |> List.head |> Maybe.withDefault 0
        closeP1 = closeP |> List.head |> Maybe.withDefault 0
        newStr = if openP1 > closeP1 then "<p>" ++ str else str
        
        openPLast = openP |> last |> Maybe.withDefault 0
        closePLast = closeP |> last |> Maybe.withDefault 0
    in
    if openPLast > closePLast then newStr ++ "</p>" else newStr
    

parseLine : String -> List (Element.Element Msg)
parseLine str = 
    let
        els = case (Html.Parser.run str) of
            Ok nodes ->
                nodes |> List.map (\n -> parseNode n) |> List.concat

            _ ->
                [ Element.paragraph []
                    [ Element.el [Font.color Palette.darkRed] (Element.text "ERROR: COULDN'T PARSE STRING -> ")
                    , Element.el [Font.color Palette.darkBlue] (Element.text str)
                    ]
                ]
    in
    els

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

begining : Mark.Block (Model -> Element.Element Msg)
begining =
    Mark.stub "Begin"
    (\ model ->
        Element.column (Palette.menu model)
        [ Element.row [Element.centerX, Element.spacing (scale model 200)]
            [ Element.el [scaleFont model 18] (Element.text "Legereme")
            , Element.image 
                [ Element.height (Element.px 36)
                , Element.width (Element.px 35)
                , Element.alignRight
                , Background.color (Element.rgba 0.9 0.9 0.9 0.7)
                , Event.onClick ToggleMenu
                ] 
                { src = "https://legereme.com/pwa/menu.svg"
                , description = "Toggle Menu"
                }
            ]
        , menuOptions model
--            ]
        ]
    )

clickOption : String -> String -> Element.Element Msg
clickOption request label =
    Element.el
    [ Event.onClick (Office request) ]
    ( Element.text label )

title : List (Element.Attribute msg) 
    -> Mark.Block (Model -> List (Element.Element msg)) 
    -> Mark.Block (Model -> Element.Element msg)
title attrs titleText =
    Mark.block "Title"
        (\elements model ->
            Element.column [ ]
            [ Element.paragraph
                (Region.heading 1 :: attrs)
                (elements model)
            ]
        )
        titleText


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
            [ Element.el [] (Element.text opts.label)
            , Element.row [ Element.spacing 10, Element.padding 10 ] btns
            , Element.el [ Element.alignLeft ] (Element.text selectedText)
            ]    
        )
        Mark.multiline

options: Mark.Block (Model -> Element.Element Msg)
options =
    Mark.block "Options"
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

            Element.column [] 
            [ Element.paragraph [] [Element.text opts.label]
            , Element.wrappedRow [ Element.spacing 10, Element.padding 10] btns
            , Element.el [ Element.alignLeft ] (Element.text selectedText)
            ]

            
        )
        Mark.multiline

openingSentence : Mark.Block (Model -> Element.Element msg)
openingSentence =
    Mark.block "OpeningSentence"
        (\parseThis model -> 
            let
                okParsed = Parser.run openingSentenceParser parseThis
            in
            case okParsed of
                Ok os ->
                    Element.textColumn [ pageWidth model ] 
                    [ Element.paragraph (Palette.openingSentenceTitle model)
                        [ Element.text (if os.label == "BLANK" then "" else os.label |> toTitleCase) ]
                    , Element.paragraph [] [Element.text (os.text |> collapseWhiteSpace)]
                    , Element.paragraph (Palette.reference model) [ Element.text (os.ref |> toTitleCase) ]
                    ]
                _ ->
                    Element.paragraph [] [Element.text "Opening Sentence Error"]
            
        )
        Mark.multiline


-- MODEL 

init : List Int -> ( Model, Cmd Msg )
init  list =
    let
        ht = list |> List.head |> Maybe.withDefault 667 -- iphone
        wd = list |> getAt 1 |> Maybe.withDefault 375 -- iphone
        x = Element.classifyDevice { height = ht, width = wd}
        firstModel = { initModel | width = wd - 20}
    in
    
    ( firstModel, requestOffice "currentOffice" )

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
--        , receivedPsalms UpdatePsalms
--        , receivedLesson1 UpdateLesson1
--        , receivedLesson2 UpdateLesson2
--        , receivedGospel UpdateGospel
        ]






type Msg 
    = NoOp
    | UpdateOption Options
    | ClickOption String String Options
    | ClickToggle String String Options
    | UpdateCalendar  (List CalendarDay)
    | UpdateOffice (List String)
    | UpdateLesson String
    | DayClick CalendarDay
    | Office String
    | AltButton String String
    | RequestReference String String
    | TodaysLessons String CalendarDay
    | ChangeMonth String Int Int
    | ToggleMenu

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        NoOp -> (model, Cmd.none)

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
                    | day = recvd |> requestedOfficeAt 0
                    , week = recvd |> requestedOfficeAt 1
                    , year = recvd |> requestedOfficeAt 2
                    , season = recvd |> requestedOfficeAt 3
                    , pageName = recvd |> requestedOfficeAt 4
                    , source = recvd |> requestedOfficeAt 5 |> String.replace "\\n" "\n"
                    }
            in
            
            (newModel, requestLessons newModel.pageName )
            -- (newModel, Cmd.none )

        UpdateLesson s ->
            (addNewLesson s model, Cmd.none)
            
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
    { title = "Morning Prayer"
    , body = 
        [ case Mark.parse document model.source of
            Ok element ->
                Element.layout
                    [ Font.family [ Font.typeface "EB Garamond" ]
                    , pageWidth model
                    ]
                    (element model) 

            Err errors ->
                Element.layout
                    []
                    (Element.text "Error parsing document!")
        ]
    }

main =
    Browser.document
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }