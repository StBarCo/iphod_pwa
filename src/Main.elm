port module Main exposing (main)

import Browser exposing (Document)
import Element exposing (..)
import Element.Background as Background
import Element.Input as Input
-- Event is singular on purpose
import Element.Events as Event
import Element.Font as Font
import Element.Region as Region
import Element.Border as Border
-- import Html
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
import List.Extra exposing (getAt, find, findIndex, setAt, groupWhile, dropWhile, takeWhile, updateAt, updateIf, filterNot)
import String.Extra exposing (toTitleCase, countOccurrences)
import MyParsers exposing (..)
import Palette exposing (scaleFont, pageWidth, indent, outdent, show, hide, edges)
import Models exposing (..)
import Json.Decode as Decode
import Date
import Task
import Time exposing (..)
import Candy exposing (..)
import MySwiper as Swiper exposing (..)


getSeason : Model -> String
getSeason m =
    m.season |> Tuple.first

{-| Here we define our document.

This may seem a bit overwhelming, but 95% of it is copied directly from `Mark.Default.document`. You can then customize as you see fit!

-}

--  document : Mark.Document
--          { body : List (Model -> Element Msg)
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
                , thisCollect
                , openingSentence
                , toggle
                , optionalPrayer
                , optionalPsalms
                , antiphon 
                , lesson
                , finish 
                , seasonal
                , calendar
                , prayerList
                , newPrayerListItem
                , openPrayerList
                , occasionalPrayers
                , canticle
                , randomCanticle
                -- Toplevel Text
            --    , Mark.map (Html.p []) Mark.text
                ]
        }


thisCollect : Mark.Block (Model -> Element Msg)
thisCollect =
    Mark.record "ThisCollect"
    (\ofType title id model ->
        let
            element = case ofType of 
                "seasonal" -> renderTodaysCollect ofType model
                "daily" -> renderTodaysCollect ofType model
                _ -> renderOtherCollects title id model
        in
        element    
    
    )
    |> Mark.field "ofType" Mark.string
    |> Mark.field "title" Mark.string
    |> Mark.field "id" Mark.string
    |> Mark.toBlock

renderTodaysCollect : String -> Model -> Element msg
renderTodaysCollect ofType model = 
    let
        width = model.width
        dayName = " /" ++ model.day ++ "/"
        collect = case model.collects |> find (\c -> c.id == ofType) of
                    Just c -> c
                    Nothing -> initCollect
        title = if ofType == "daily"
                then collect.title ++ " /" ++ model.day ++ "/"
                else collect.title

    in
    renderDailyCollect width title collect.text
    

renderOtherCollects : String -> String -> Model -> Element Msg
renderOtherCollects title id model = 
    -- if today is Tuesday and name is "Peace" then skip, etc
    let
        skip = case (model.day, id) of
            ("Tuesday", "collect_tuesday_mp") -> True -- collect for peace
            ("Wednesday", "collect_wednesday_mp") -> True -- collect for grace
            ("Monday", "collect_monday_ep") -> True -- ep collect for peace
            ("Tuesday", "collect_tuesday_ep") -> True
            _ -> False
        element = if skip 
            then none
            else 
                renderAdditionalConditionalCollect model id title
    in
    element
    
getCollect : Model -> String -> Collect
getCollect model id =
    case ( model.collects |> find (\c -> c.id == id) ) of
        Just coll -> coll
        Nothing -> initCollect 

renderAdditionalConditionalCollect : Model -> String -> String -> Element Msg
renderAdditionalConditionalCollect model id title =
    -- the collect may or may not be present
    -- if it's not present, use the show button to go get it
    let
        width = model.width
        (collect, show) = case model.collects |> find (\c -> c.id == id) of
            Just c -> (c, c.show)
            Nothing -> (initCollect, False)
    in
    if show
    then
        column [ padding 10 ]
            [ paragraph 
                ( Event.onClick (ToggleCollect id) :: Palette.button width )
                [ text ("Hide: " ++ title) ]
            , renderCollectTitle width collect.title
            , renderPlainText width collect.text
            ]
    else
        column [ padding 10 ]
            [ paragraph
                ( Event.onClick (ToggleCollect id) :: Palette.button width )
                [ text ("Show: " ++ title) ]
            ]


canticle : Mark.Block (Model -> Element Msg)
canticle =
    Mark.record "Canticle"
    (\id model ->
        renderCanticle (getCanticle model id) model.width
    
    )
    |> Mark.field "canticle" Mark.string
    |> Mark.toBlock


renderCanticle : Canticle -> Int -> Element Msg
renderCanticle c width =
    let
        lines = c.text
            |> String.lines
            |> List.map (\t -> t |> indentableParagraph 10 30 )

        (alt, number) = if c.officeId == "invitatory"
            -- if it's the invitatory, add the alt button and leave off the Canticle number
            then
                ( Input.button
                    ( Palette.buttonAltInvitatory width )
                    --[ text ("Other Invitatories") ]
                    { onPress = Just (RollInvitatory c.id)
                    , label = text "Other Invitatories"
                    }
                , none
                )
            -- if it's not the invitatory, leave off the alt button and add the Canticle number
            else (none, paragraph [ Font.center, Palette.scaleFont width 22 ] [ text c.number ])

    in
    column [ paddingXY 0 20, Font.family [ Font.typeface "Georgia"] ]
    ( [ alt, number
    , paragraph [ Font.center ] [ text (String.toUpper c.name) ]
    , paragraph [ Font.center, Font.italic ] [ text c.title ]
    , paragraph (Palette.rubric width) [ text c.notes ] 
    ] 
    ++ lines
    ++ [ paragraph 
        [ Font.alignRight, Palette.scaleFont width 10, paddingXY 10 5 ]
        [ text (String.toUpper c.reference) ]
       ]
    )

getCanticle : Model -> String -> Canticle
getCanticle model id =
    case ( model.canticles |> find (\c -> c.id == id) ) of
        Just coll -> coll
        Nothing -> initCanticle


randomCanticle : Mark.Block (Model -> Element Msg)
randomCanticle =
    Mark.record "RandomCanticle"
    (\officeId model ->
        let
            cant = case (model.officeCanticles |> find (\c -> c.officeId == officeId) ) of
               Just c -> c
               Nothing -> initCanticle
        in
        if skipLesson2 model officeId
            then none
            else renderCanticle cant model.width
    )
    |> Mark.field "for" Mark.string
    |> Mark.toBlock


occasionalPrayers : Mark.Block (Model -> Element Msg)
occasionalPrayers =
    Mark.block "OccasionalPrayers"
    (\placeholder model ->
        let
            opCats = model.ops.categories |> String.split "\n"
            elements =
                model.ops.categories
                |> String.split "\n"
                |> List.map (\c ->
                    let
                        thesePrayers = if c == model.ops.thisCat
                            then renderThisCat model.width model.ops.list
                            else []

                    in
                    paragraph [ Event.onClick (RequestOPsByCat c) ] [text c]
                    :: thesePrayers
                )
        in
        column [] (elements |> List.concat)
    )
    Mark.string


renderThisCat : Int -> List OccasionalPrayer -> List (Element Msg)
renderThisCat width prayers =
    prayers 
    |> List.map
    (\p ->
        let
            thisPrayer = if p.show
                then paragraph [moveRight 30.0, Palette.scaleWidth width 350, padding 10] [text p.prayer]
                else none
        in
        [ paragraph [Event.onClick (ToggleOP p.id), moveRight 20.0] [text (toTitleCase p.title)]
        , thisPrayer
        ]
    )
    |> List.concat

openPrayerList : Mark.Block (Model -> Element Msg)
openPrayerList =
    Mark.block "OpenPrayerList"
    (\show model ->
        let
            elements = if model.prayerList.prayers |> List.isEmpty
                then [none]
                else
                    if model.prayerList.show
                        then prayerListButton "Hide Prayer List" model.width
                             :: renderOfficePrayerList model False
                             
                        else prayerListButton "Show Prayer List" model.width
                             :: [none]
                             
        in
        column [] elements
        
    )
    Mark.bool

prayerListButton : String -> Int -> Element Msg
prayerListButton buttonText buttonWidth =
    paragraph
    ( Event.onClick ShowPrayerList
    :: width (px 160)
    :: Palette.button buttonWidth
    )
    [ text buttonText ]

newPrayerListItem : Mark.Block (Model -> Element Msg)
newPrayerListItem =
    Mark.block "NewListItem"
    (\show model ->
        let
            (prayers, addButton) = if model.prayerList.edit
                then
                    ( model.prayerList.prayers
                        |> List.head 
                        |> Maybe.withDefault initPrayer
                        |> editPrayer model
                    , [ none ]
                    )
                else
                    (model.prayerList.prayers
                        |> renderPrayerList True model.width
                    , [ image 
                        [ Element.height (px 36)
                        , Element.width (px 35)
                        , Event.onClick (AddToPrayerList)
                        ]
                        { src = "./addToList.ico"
                        , description = "Add New Item"
                        }
                        , el [ paddingXY 20 0 ] (text "Add New Item")
                        ]
                    )

            elements = 
                row [ paddingXY 20 0 ] addButton
                :: prayers 
        in
        column [] elements
    )
    Mark.bool


editPrayer : Model -> Prayer -> List (Element Msg)
editPrayer model prayer =
    let
        width = model.width
        oPCats = model.ops.categories
            |> String.split "\n"
            |> (::) "Other"
            |> List.map 
            (\c -> 
                if c == model.ops.thisCat
                    then 
                        model.ops.list
                        |> List.map 
                        (\ p -> 
                            Input.option 
                                p.title 
                                ( column [] 
                                    [ renderSectionTitle width p.title
                                    , renderPlainText width p.prayer
                                    ]
                                )
                        )
                        |> (::) (Input.option c (text c) )
                    else [ Input.option c (text c) ]
            )
            |> List.concat
    in
    [ column []
        [ row [ paddingXY 20 20 ]
            [ Input.multiline 
                [ Palette.scaleWidth 300 width
                , Palette.placeholder "Who/What to pray for\nAnd reason"
                , height shrink
                , paddingEach {edges | bottom = 30}
                ] 
                { onChange = UpdateNewPrayer
                , text = prayer.who
                , placeholder = Nothing -- does not work in this version of elm-ui
                , label = Input.labelAbove [] (text "New Prayer")
                , spellcheck = True
                }
            ]
        , row 
            [ paddingXY 20 0 ]
            [ image 
                [ Element.height (px 36)
                , Element.width (px 35)
                , Event.onClick SavePrayerItem
                ]
                { src = "./save.ico"
                , description = "Save"
                }
            , el [ paddingXY 20 0 ] (text "Save")
            , image 
                [ Element.height (px 36)
                , Element.width (px 35)
                , Event.onClick SavePrayerItem
                , paddingXY 40 0
                ]
                { src = "./delete.ico"
                , description = "Cancel"
                }
            , el [ paddingXY 20 0 ] (text "Cancel")
            ]
        , paragraph 
            [ Font.color Palette.darkBlue, moveRight 70.0] 
            [ text (toTitleCase prayer.ofType)] 
        , column [ Palette.scaleWidth 200 width ]
            [   Input.radio
                [ padding 5
                , spacing 10
                , Palette.wordBreak
                ]
                { onChange = PrayerCategory
                , selected = Just prayer.ofType
                , label = Input.labelAbove [] (text "Prayer Type")
                , options = oPCats
                }
            ]
        ]
    ]



renderPrayerList : Bool -> Int -> List Prayer -> List (Element Msg)
renderPrayerList editable width prayers =
    prayers 
    |> List.map (\p ->
        let
            (clickable, removable) = if editable
                then
                    (   [ Event.onClick (EditPrayerListItem p.id)
                        , Palette.scaleWidth 250 width
                        , padding 5
                        ]
                    ,   image 
                        [ Element.height (px 36)
                        , Element.width (px 35)
                        , Event.onClick (RemoveFromPrayerList p.id)
                        ]
                        { src = "./delete.ico"
                        , description = "Remove"
                        }
                    )
                else
                    (   [ Palette.scaleWidth 250 width, padding 5 ]
                    ,   none
                    )
        in
        row (Palette.prayerList width)
        [ column 
            clickable
            [ renderPlainText width p.who
            , renderPlainText width p.why
            , renderSectionTitle width p.ofType
            ]
        , removable
        ]
    )

renderOfficePrayerList : Model -> Bool -> List (Element Msg)
renderOfficePrayerList model show = 
    let
        width = model.width
        thisPrayerList = model.prayerList.prayers
        elements = model.ops.list
            -- map the occasional prayers
            |> List.map
            (\op ->
                let 
                    -- render this prayer
                    thisPrayer = renderPrayerListItem width op
                    
                    -- render those that goes along with thisPrayer
                    forThese =
                        thisPrayerList
                        |> List.filter 
                        (\p -> p.opId == op.id)
                        |> List.map
                        (\p ->
                            column []
                            [ paragraph [ paddingXY 20 0, Font.bold ] [ text p.who ]
                            , paragraph [ paddingXY 20 0] [ text p.why]
                            ]
                        )
                in
                column 
                    [ padding 20
                    , Border.width 1
                    , Border.rounded 5
                    , Palette.scaleWidth 350 width
                    , moveRight 10
                    ]
                    (List.concat [thisPrayer ++ forThese])
            )
    in
    elements


prayerList : Mark.Block (Model -> Element Msg)
prayerList  =
    Mark.block "PrayerList"
    (\_ model -> none )
    Mark.string -- this string is ignored

calendar : Mark.Block (Model -> Element Msg)
calendar =
    Mark.block "Calendar"
    (\month model ->
        let
            dayId = model.showThisCalendarDay
            align = if dayId < 0
                then [ centerX ]
                else [ alignLeft, paddingXY 10 5 ]
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
                                    column 
                                    ( Event.onClick (ThisDay day) :: (backgroundGradient day.color ++ Palette.calendarDay model.width))
                                    [ paragraph [ padding 2 ] 
                                      [ el [] (text (day.dayOfMonth |> String.fromInt))
                                      , el [ padding 2 ] (text day.pTitle)
                                      ]
                                    ]
                                )
                        in
                        row [] thisWeek
                    )
                else
                    let
                        day = model.calendar 
                            |> getAt dayId
                            |> Maybe.withDefault initCalendarDay
                        
                    in
                    [ column [Font.alignLeft]
                        [ Input.button (padding 20 :: Palette.button model.width)
                            { onPress = Just ShowCalendar
                            , label = text "Return to Calendar"
                            }
                        , serviceReadings Eucharist day model
                        , serviceReadings MorningPrayer day model
                        , serviceReadings EveningPrayer day model
                        , Input.button (moveDown 20.0 :: Palette.button model.width)
                            { onPress = Just ShowCalendar
                            , label = text "Return to Calendar"
                            }
                        ]
                    ]


        in
        column align rows
        
    )
    Mark.string


referenceText : Int -> CalendarDay -> Service -> ReadingType -> List (Element Msg)
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
            paragraph
                ( Event.onClick (ThisReading thisService thisReading day) 
                :: Palette.readingRef r.style width 
                ) 
                [ text ref]
        )

    
serviceReadings : Service -> CalendarDay -> Model -> Element Msg
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
    column [] 
    ( paragraph 
        ( Event.onClick (ThisReading thisService All day) 
        :: Palette.lessonTitle width 
        )
        [ text (serviceTitle thisService) ]
      :: leznz
    )
    
showMenu : Bool -> Attribute msg
showMenu bool =
    if bool then show else hide

menuOptions : Model -> Element Msg
menuOptions model =
    let 
        showConfig = if model.showConfig
            then renderConfig model
            else none
    in
    column []
        [ row []
            [ column [ showMenu model.showMenu, scaleFont model.width 16, paddingXY 20 0, alignTop ]
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
            , column [ showMenu model.showMenu, scaleFont model.width 16, paddingXY 20 0, alignTop ]
                [ clickOption "prayerList" "Prayer List"
                , clickOption "occasionalPrayers" "Occasional Prayers"
                , clickOption "canticles" "Canticles"
                , clickOption "about" "About"
                , clickOption "sync" "How to Install"
                , clickOption "sync" "Update Database"
                , clickOption "about" "Contact"
                , clickOption "angChurchChat" "Church Chat"
                , clickOption "config" "Config"
                ]
            ]
        , showConfig
        ]
    
renderConfig : Model -> Element Msg
renderConfig model =
    column 
        [ Palette.scaleWidth model.width 300
        , Border.width 2
        , Border.rounded 4
        , Border.glow Palette.darkGrey 5.0
        , padding 20
        , centerX
        , Background.color Palette.foggy
        ]
        [ paragraph [] 
            [ Input.radioRow
                [ padding 10
                , spacing 20
                ]
                { onChange = Configure
                , selected = Just model.config.readingCycle
                , label = Input.labelAbove [] (text "Reading Cycle")
                , options =
                    [ Input.option "OneYear" (text "One Year")
                    , Input.option "TwoYear" (text "Two Year")
                    ]
                }
            ]
        , paragraph []
            [ Input.radioRow
                [ padding 10
                , spacing 20
                ]
                { onChange = Configure
                , selected = Just model.config.psalmsCycle
                , label = Input.labelAbove [] (text "Psalm Cycle")
                , options =
                    [ Input.option "ThirtyDay" (text "30 Day")
                    , Input.option "SixtyDay" (text "60 Day")
                    ]
                }
            ]
        , row [] 
            [ column [] 
                [ Input.slider
                    [ Element.height (Element.px 30)

                    -- Here is where we're creating/styling the "track"
                    , Element.behindContent
                        (Element.el
                            [ Element.width Element.fill
                            , Element.height (Element.px 2)
                            , Element.centerY
                            , Background.color Palette.darkGrey
                            , Border.rounded 2
                            ]
                            Element.none
                        )
                    ]
                    { onChange = round >> AdjustFont
                    , label =
                        Input.labelAbove []
                            (text "Font Size")
                    , min = 4
                    , max = 24
                    , step = Just 1
                    , value = toFloat model.config.fontSize
                    , thumb =
                        Input.defaultThumb
                    }
                ]
            , column []
                [ el [  Palette.scaleFont model.width model.config.fontSize ] 
                    ( text "Font Size")
                ]
            ]
        ]


lesson : Mark.Block (Model -> Element Msg)
lesson =
    Mark.block "Lesson"
        (\request model ->
            let
                thisRequest = request |> String.trim
                thisLesson = case thisRequest of
                    "lesson1" -> 
                        addWordOfTheLord (showLesson model.lessons.lesson1.content model.width)
                    "lesson2" -> 
                        if skipLesson2 model thisRequest
                            then
                                [ none ]
                            else
                                addWordOfTheLord (showLesson model.lessons.lesson2.content model.width)
                    "psalms"  -> showPsalms model.lessons.psalms.content model.width
                    "gospel"  -> 
                        showLesson model.lessons.gospel.content model.width
                    _         -> [none]
    
            in
            
            column (Palette.lesson model.width)
            ( List.concat
                [ readingIntroduction model thisRequest
                , thisLesson
                ]
            )
        )
        Mark.string

showPsalms : List Reading -> Int -> List (Element Msg)
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
        column 
        [ paddingEach { top = 10, right = 40, bottom = 0, left = 0} 
        , Palette.maxWidth width
        ]
        (   paragraph 
            (Palette.lessonTitle width) 
            [ text thisName
            , el 
                [ Font.alignRight
                , Font.italic
                , paddingEach { top = 0, right = 0, bottom = 0, left = 20}
                ]
                (text thisTitle)
            ]
        :: pss
        )
    )

psalmLine : Int -> Int -> String -> List (Element Msg)
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

renderPsSection : Int -> Maybe String -> String -> Element Msg
renderPsSection width title sectionName =
    paragraph [ paddingXY 10 10, Palette.maxWidth width ]
    [ el [] (text sectionName)
    , el 
        [Font.italic, paddingXY 20 0] 
        (text (title |> Maybe.withDefault "") )
    ]

renderPsLine1 : Int -> Int -> String -> Element Msg
renderPsLine1 width lineNumber ln1 =
    paragraph [ indent "3rem", Palette.maxWidth (width - 30) ]
    [ el [outdent "3rem"] none
    , el 
        [ Font.color Palette.darkRed
        , padding 5
        ]
        ( text (String.fromInt lineNumber) )
    , el [] (text ln1)
    ]

renderPsLine2 : Int -> String -> Element Msg
renderPsLine2 width ln2 =
    paragraph [ indent "4rem" , Palette.maxWidth (width - 30) ]
    [ el [ outdent "2rem"] none
    , text ln2
    ]

showLesson : List Reading -> Int -> List (Element Msg)
showLesson content width =
    content |> versesFromLesson width

versesFromLesson : Int -> List Reading -> List (Element Msg)
versesFromLesson width readings =
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
            column (Palette.lesson width) rvss
            
        )
    


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
    

parseLine : String -> List (Element Msg)
parseLine str = 
    case Html.Parser.run str of
        Ok nodes ->
            Html.Parser.Util.toVirtualDom nodes
            |> List.map (\el -> html el)

        Err msg ->
            [ paragraph []
                [ el [ Font.color Palette.darkRed] (text "ERROR: COULDN'T PARSE STRING -> ")
                , el [ Font.color Palette.darkBlue] (text str)
                ]
            ]


finish : Mark.Block (Model -> Element Msg)
finish =
    Mark.block "Finish"
    (\office model ->
        none
    )
    Mark.string

clickOption : String -> String -> Element Msg
clickOption request label =
    el
    [ Event.onClick (Office request) ]
    ( text label )


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


renderHeader : String -> String -> (Model -> Element Msg)
renderHeader title description =
    \model ->
        column []
        [ column 
            ( backgroundGradient model.color
            ++ borderShadow model.color
            ++ (Palette.menu model.width) 
            ++ Palette.swipe (onSwipeEvents HeaderMenu)
            )
            [ row [paddingXY 20 0, spacing 20, Palette.maxWidth model.width]
                [ image 
                    [ height (px 36)
                    , width (px 35)
                    , Event.onClick ToggleMenu
                    ]
                    { src = "./prayerbook.ico"
                    , description = "Toggle Menu"
                    }
                , image
                    [ height (px 36)
                    , width (px 35)
                    , Event.onClick (Office "calendar")
                    ]
                    { src = "./calendar.ico"
                    , description = "Toggle Calendar"
                    }
                , image
                    [ height (px 36)
                    , width (px 35)
                    , Event.onClick (Office "prayerList")
                    ]
                    { src = "./prayerlist.png"
                    , description = "Prayer List"
                    }
                , el [scaleFont model.width 18, paddingXY 30 20] (text "Legereme")
                , el 
                    [ scaleFont model.width 14
                    , Font.color Palette.darkRed
                    , Font.alignRight
                    , Palette.adjustWidth model.width -430
                    ]
                    (text model.online)
                ]
            , menuOptions model
            ]
        , column ( Palette.officeTitle model.width )
            [ paragraph
                [ Region.heading 1
                , scaleFont model.width 32
                , Font.center
                , width (px model.width)
                ]
                [ text title ]
            , paragraph 
                [ Font.center, scaleFont model.width 18] 
                [ text model.today ]
            , paragraph
                [ Font.center, scaleFont model.width 18]
                [ text ((model |> getSeason |> toTitleCase) ++ " " ++ model.week) 
                , el [Font.italic] (text model.year)
                ]
            ]
        ]



toggle: Mark.Block (Model -> Element Msg)
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
                    , label = text o.label
                    }
                    )
                selectedText = opts.options
                    |> List.foldl (\o acc ->
                        if o.selected == "True" then acc ++ o.text else acc
                        ) ""
            in
            column []
            [ el [ Palette.maxWidth model.width ] (text opts.label)
            , row [ spacing 10, padding 10 ] btns
            , el [ alignLeft, Palette.maxWidth model.width ] (text selectedText)
            ]    
        )
        Mark.string

optionButtons : Model -> String -> { btns: List (Element Msg), label: String, text: String }
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
             , label = text o.label
             }
            )
        selectedText = opts.options
            |> List.foldl (\o acc ->
                if o.selected == "True" then acc ++ o.text else acc
            ) ""
    in
    { btns = btns, label = opts.label, text = selectedText }


optionalPrayer : Mark.Block (Model -> Element Msg)
optionalPrayer =
    Mark.block "OptionalPrayer"
        (\everything model ->
            let
                opts = optionButtons model everything
                thisText = if String.contains "EMPTY" opts.text
                    then text ""
                    else text opts.text
            in

            column [paddingXY 10 0, Palette.maxWidth model.width] 
            [ renderPlainText model.width opts.label
            , wrappedRow [ spacing 10, padding 10] opts.btns
            , el [ alignLeft, Palette.maxWidth model.width ] thisText
            ]
        )
        Mark.string

optionalPsalms : Mark.Block (Model -> Element Msg)
optionalPsalms =
    Mark.block "OptionalPsalms"
    (\everything model ->
        let
            opts = optionButtons model everything
        in
        
        column [paddingXY 10 0, Palette.maxWidth model.width] 
        (  paragraph [] [text opts.label]
        :: wrappedRow [ spacing 10, padding 10] opts.btns
        :: parsePsalm model opts.text
        )
    )
    Mark.string

parsePsalm: Model -> String -> List ( Element Msg )
parsePsalm model ps =
    ps 
    |> String.lines 
    |> List.map (\l -> stringToPsalmLine model.width l )

stringToPsalmLine : Int -> String -> Element Msg
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

seasonal : Mark.Block (Model -> Element Msg)
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
                    textColumn []
                    [ if os.label == "BLANK"
                        then paragraph (Palette.rubric model.width) [text "or this"]
                        else paragraph (Palette.openingSentenceTitle model.width) [text os.label]
                    , paragraph (Palette.openingSentence model.width) [text os.text]
                    , paragraph (Palette.reference model.width) [text os.ref]
                    ]
                )
        in

        textColumn
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

openingSentence : Mark.Block (Model -> Element msg)
openingSentence =
    Mark.block "OpeningSentence"
        (\parseThis model -> 
            let
                okParsed = Parser.run openingSentenceParser parseThis
            in
            case okParsed of
                Ok os ->
                    textColumn [ Palette.maxWidth model.width ] 
                    [ paragraph (Palette.openingSentenceTitle model.width)
                        [ text (if os.label == "BLANK" then "" else os.label |> toTitleCase) ]
                    , paragraph (Palette.openingSentence model.width) [text (os.text |> collapseWhiteSpace)]
                    , paragraph (Palette.reference model.width) [ text (os.ref |> toTitleCase) ]
                    ]
                _ ->
                    paragraph [] [text "Opening Sentence Error"]
            
        )
        Mark.string


-- MODEL 

-- getTimeNow : Cmd Msg
-- getTimeNow = 
--     Task.perform NewTime Time.now

init : List Int -> ( Model, Cmd Msg )
init  list =
    let
        winWd = list |> getAt 1 |> Maybe.withDefault 375 -- iphone = 375
        wd = min winWd 800
        firstModel = { initModel | width = wd, windowWidth = winWd }
    in
    
    ( firstModel
    , Cmd.batch 
        [ requestOffice "currentOffice"
        , Task.perform Tick Time.now 
        ] 
    )

-- REQUEST PORTS


port requestReference : (List String) -> Cmd msg
port requestOffice : String -> Cmd msg
port requestLessons : String -> Cmd msg
port requestOPsByCat : String -> Cmd msg
port requestCollect : String -> Cmd msg
port requestNextInvitatory : String -> Cmd msg
port calendarReadingRequest : ServiceReadingRequest -> Cmd msg
port toggleButtons : (List String) -> Cmd msg
port changeMonth : (String, Int, Int) -> Cmd msg
port prayerListDB : (List String) -> Cmd msg
port swipeLeftRight : String -> Cmd msg
port saveConfig : Models.Device -> Cmd msg


-- SUBSCRIPTIONS


port receivedCalendar : (String -> msg) -> Sub msg
port receivedOffice : (List String -> msg) -> Sub msg
port receivedLesson : (String -> msg) -> Sub msg
port receivedPrayerList : (String -> msg) -> Sub msg
port receivedCollect : (List String -> msg) -> Sub msg
port receivedOPCats : (String -> msg) -> Sub msg
port receivedOPs : (String -> msg) -> Sub msg
port newWidth : (Int -> msg) -> Sub msg
port onlineStatus : (String -> msg) -> Sub msg
port receivedAllCanticles : (String -> msg) -> Sub msg
port receivedOfficeCanticles : (String -> msg) -> Sub msg
port receivedNewCanticle : (String -> msg) -> Sub msg
port receivedConfig : (String -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ receivedCalendar UpdateCalendar
        , receivedOffice UpdateOffice
        , receivedLesson UpdateLesson
        , receivedPrayerList UpdatePrayerList
        , receivedCollect UpdateCollect
        , newWidth NewWidth
        , onlineStatus UpdateOnlineStatus
        , receivedOPCats UpdateOPCats
        , receivedOPs UpdateOPs
        , receivedAllCanticles UpdateAllCanticles
        , receivedOfficeCanticles UpdateOfficeCanticles
        , receivedNewCanticle UpdateOneOfficeCanticle
        , receivedConfig UpdateConfig
        , Time.every 1000 Tick
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
    | Configure String
    | UpdateConfig String
    | AdjustFont Int
    | Tick Time.Posix
    | NewTimer String Int Time.Posix
    | FinishedTimers (List Timer)
    | GotSrc (Result Http.Error String)
    | UpdateOption Options
    | ClickOption String String Options
    | ClickToggle String String Options
    | UpdateCalendar String
    | UpdateOffice (List String)
    | UpdateCollect (List String)
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
    | EditPrayerListItem String
    | RemoveFromPrayerList String
    | AddToPrayerList
    | CancelPrayerItem
    | UpdateNewPrayer String
    | SavePrayerItem
    | PrayerCategory String
    | UpdatePrayerList String -- json
    | ShowPrayerList
    | UpdateOPCats String
    | RequestOPsByCat String
    | UpdateOPs String
    | ToggleOP String
    | ToggleCollect String
    | RequestCollect String
    | HeaderMenu SwipeEvent
    | PageSwipe SwipeEvent
    | UpdateAllCanticles String
    | UpdateOfficeCanticles String
    | UpdateOneOfficeCanticle String
    | RollInvitatory String

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        NoOp -> (model, Cmd.none)

        Configure opt ->
            let
                config = model.config
                lessons = model.lessons
                newModel = case opt of
                    "OneYear" ->
                        let
                            newConfig = { config | readingCycle = opt }
                            
                        in
                        { model | config = newConfig}
                    "TwoYear" ->
                        let
                            newConfig = { config | readingCycle = opt }
                            newLessons = { lessons | lesson2 = initLesson }
                        in
                        { model | config = newConfig, lessons = newLessons }
                    "ThirtyDay" ->
                        let
                            newConfig = { config | psalmsCycle = opt }
                        in
                        { model | config = newConfig }
                    "SixtyDay" ->
                        let
                            newConfig = { config | psalmsCycle = opt }
                        in
                        { model | config = newConfig }
                    _ -> model
            in
            ( newModel, saveConfig newModel.config)

        UpdateConfig json ->
            let
                newModel = case Decode.decodeString deviceDecoder json of
                    Ok c ->
                        { model | config = c }
                    _ ->
                        model
            in
            (newModel, Cmd.none)

        AdjustFont i ->
            let
                config = model.config
                newConfig = { config | fontSize = i }
            in
            ( { model | config = newConfig }, saveConfig newConfig)

        Tick t -> 
            let 
                finishedTimers = model.timers
                    |> takeWhile (\tx -> t |> timeIsAfter tx.end)
                newTimers = model.timers
                    |> dropWhile (\tx -> t |> timeIsAfter tx.end)
            in
            update (FinishedTimers finishedTimers) {model | time = t, timers = newTimers}

        NewTimer name msec t ->
            let
                timeOut = t |> posixToMillis |> (+) msec |> millisToPosix
                newTimers = model.timers
                    |> dropWhile (\tx -> tx.id == name)
                    |> (::) { id = name, end = timeOut}
            in
            ({model | timers = newTimers}, Cmd.none)

        FinishedTimers list ->
            let
                h = list |> List.head
                t = list |> List.tail |> Maybe.withDefault []
                updateThis = case h of
                    Just job -> 
                        case job.id of
                            "status" -> -- ({model | online = ""}, Task.perform FinishedTimers (Never t) )
                                update (FinishedTimers t) {model | online = ""}
                            _ -> (model, Cmd.none)
                    Nothing ->
                        (model, Cmd.none)

            in
            updateThis

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

        UpdateCollect coll ->
            let
                ofType = coll |> getAt 0 |> Maybe.withDefault "traditional"
                id = coll |> getAt 1 |> Maybe.withDefault "id0"
                t = coll |> getAt 2 |> Maybe.withDefault "Collect of the Day"
                c = coll |> getAt 3 |> Maybe.withDefault "Goes Here"
                newCollects = if ofType == "True"
                    then [ Collect id t c True ]
                    else ( Collect id t c True ) :: model.collects 

            in
            ( { model | collects = newCollects }
            , Cmd.none
            )

        UpdateLesson s ->
            (addNewLesson s model, Cmd.none)

        UpdateOnlineStatus s ->
            ( {model | online = s}, Task.perform (NewTimer "status" 5000) Time.now )

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
            let
                updateThis = case o of
                    "config" ->
                        ( { model | showConfig = not model.showConfig }, Cmd.none )
                    _ ->
                        ( { model | showMenu = False, showConfig = False }, requestOffice o)
            in
            updateThis

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
            ( { model | showMenu = not model.showMenu, showConfig = False }, Cmd.none )

        NewWidth i ->
            ( { model 
                | windowWidth = i
                , width = (min i 500) - 20
            }, Cmd.none)

        EditPrayerListItem id ->
            let
                -- get the prayer by it's ID
                -- remove it from the original list
                -- add the why field to the who field
                -- the edit section on works on the why field
                -- put the prayer at the top of the list
                -- , edit = true
                tp = 
                    model.prayerList.prayers
                    |> find(\p -> p.id == id)
                    |> Maybe.withDefault initPrayer
                ep = { tp | who = (tp.who ++ "\n" ++ tp.why)}
                newPrayers = ep :: (filterNot(\p -> p.id == id) model.prayerList.prayers)
                pl = model.prayerList
                newPl = { pl | edit = True, prayers = newPrayers }

            in
            ( { model | prayerList = newPl }, Cmd.none)

        RemoveFromPrayerList id ->
            let

                pl = model.prayerList
                cmds = case (find(\el -> el.id == id) pl.prayers) of
                    Just thisPrayer ->
                        [ prayerListCommand "delete" thisPrayer, Cmd.none ]
                    _ -> 
                        [Cmd.none]

            in
            (model, Cmd.batch cmds)

        AddToPrayerList ->
            let
                newPl = 
                    { edit = True
                    , show = False
                    , prayers = initPrayer :: model.prayerList.prayers 
                    }
            in
            ( { model | prayerList = newPl }, Cmd.none )

        CancelPrayerItem ->
            ( model, Cmd.batch [ requestOffice "prayerList", Cmd.none ])

        PrayerCategory ofType ->
            let 
                pl = model.prayerList
                thisOP = model.ops.list
                    |> find (\o -> o.title == ofType)
                    |> Maybe.withDefault initOccassionalPrayer
                updatedPrayers = 
                    pl.prayers
                    |> updateAt 0 (\p -> { p | ofType = ofType, opId = thisOP.id} )
                newList =
                    { pl
                    | prayers = updatedPrayers
                    }
            in
            ( { model | prayerList = newList }
            , Cmd.batch [ requestOPsByCat ofType, Cmd.none] )
                    

        UpdateNewPrayer str ->
            let
                newList = model.prayerList.prayers |> updateAt 0 (\p -> {p | who = str})
                pl = model.prayerList
                newPl = { pl | prayers = newList}
            in
            ( { model | prayerList = newPl }, Cmd.none)

        SavePrayerItem ->
            let
                thisPrayer = 
                    model.prayerList.prayers 
                    |> getAt 0 
                    |> Maybe.withDefault initPrayer
                plist = thisPrayer.who |> String.split "\n"
                who = plist |> getAt 0 |> Maybe.withDefault ""
                why = plist
                    |> List.tail
                    |> Maybe.withDefault []
                    |> String.join "\n"
                thisType = if thisPrayer.ofType |> String.isEmpty
                    then "Other"
                    else thisPrayer.ofType
                newPrayer = { thisPrayer | who = who, why = why, ofType = thisType }
            in
            ( model, Cmd.batch [prayerListCommand "save" newPrayer, Cmd.none] 
            )

        UpdatePrayerList jsonPrayers ->
            let
                newPrayerList = case Decode.decodeString prayerListDecoder jsonPrayers of
                    Ok p -> p
                    Err str -> model.prayerList
            in
            ( { model | prayerList = newPrayerList }, Cmd.none )

        ShowPrayerList ->
            let
                pl = model.prayerList
                newModel = if pl.prayers |> List.isEmpty
                    then 
                        model
                    else
                        let
                            newPl = { pl | show = not pl.show }
                        in
                        { model | prayerList = newPl}
                        
            in
            (newModel, Cmd.none)

        UpdateOPCats str ->
            let
                ops = model.ops
                newOps = { ops | categories = str }
            in
            ( { model | ops = newOps }, Cmd.none )

        RequestOPsByCat str ->
            ( model
            , Cmd.batch [ requestOPsByCat str, Cmd.none ]
            )

        UpdateOPs str ->
            let
                newOPs = case Decode.decodeString opListDecoder str of
                    Ok ops ->
                        { categories = model.ops.categories
                        , thisCat = ops.cat
                        , list = ops.prayers
                        }

                    Err err ->
                        model.ops
            in
            ( { model | ops = newOPs }, Cmd.none )

        ToggleOP id ->
            let
                opList = model.ops.list
                newList = case findIndex (\p -> p.id == id) opList of
                    Just i ->
                        opList |> updateAt i (\p -> { p | show = not p.show} )
                    Nothing ->
                        opList
                ops = model.ops
                newOPs = { ops | list = newList }
            in
            ( { model | ops = newOPs }, Cmd.none)

        ToggleCollect id ->
            let
                cmd = case model.collects |> find (\c -> c.id == id) of
                    Just c -> Cmd.none
                    Nothing -> requestCollect id

                newCollects = 
                    model.collects
                    |> updateIf 
                        (\c -> c.id == id) 
                        (\c -> { c | show = not c.show } )
            in
            ( { model | collects = newCollects }, cmd )

        RequestCollect id ->
            (model, Cmd.batch[ requestCollect id, Cmd.none ] )


        HeaderMenu evt ->
            let
                (newState, swipedDown) =
                    hasSwipedDown 20 evt model.swipingState
                (newState2, swipedUp) =
                    hasSwipedUp 20 evt model.swipingState

                swipeDirection = 
                    if swipedDown then Down
                    else if swipedUp then Up
                    else Neither

                newModel = 
                    if touchFinished evt
                    then 
                        case (swipeDirection, model.showMenu) of
                            (Down, True) -> { model | swipingState = newState }
                            (Up, False) -> { model | swipingState = newState }
                            (Up, True) -> { model | swipingState = newState, showMenu = False }
                            (Down, False) -> { model | swipingState = newState, showMenu = True }
                            (_, _) -> model
                                -- case model.swipingState of
                                --     Nothing -> { model | swipingState = newState }
                                --     _ -> model
                    else 
                        { model | swipingState = newState }
            in
            ( newModel, Cmd.none )


        PageSwipe evt ->
            let
                (newState, swipedLeft) =
                    hasSwipedLeft 100 evt model.swipingState
                (newState2, swipedRight) =
                    hasSwipedRight 100 evt model.swipingState
                swipeCmd = 
                    if swipedLeft then swipeLeftRight "left"
                    else if swipedRight then swipeLeftRight "right"
                    else Cmd.none

            in
            ( { model | swipingState = newState }, swipeCmd )

        UpdateAllCanticles json ->
            let
                newModel = case Decode.decodeString canticleListDecoder json of
                    Ok c ->
                        { model | canticles = c.canticles }
                        
                    _  -> 
                        model

            in
            (newModel, Cmd.none)

        UpdateOfficeCanticles json ->
            let
                newModel = case Decode.decodeString canticleListDecoder json of
                    Ok c ->
                        { model | officeCanticles = c.canticles }

                    _ -> 
                        model
            in
            (newModel, Cmd.none)

        UpdateOneOfficeCanticle json ->
            let
                newModel = case Decode.decodeString canticleListDecoder json of
                    Ok list ->
                        let
                            -- we only want the first canticle
                            c = list.canticles |> getAt 0 |> Maybe.withDefault initCanticle
                            newCanticles = model.officeCanticles 
                                -- remove the old officeCanticle (by officeId)
                                |> filterNot(\cant -> cant.officeId == c.officeId )
                                -- push in the new one
                                |> (::) c
                        in
                        {model | officeCanticles = newCanticles}
                    _ -> -- for errors
                        model
            in
            ( newModel, Cmd.none )
            
        RollInvitatory inv ->
            (model, requestNextInvitatory inv)
type SwipeDirection
    = Up
    | Down
    | Left
    | Right
    | Neither


prayerListCommand : String -> Prayer -> Cmd msg
prayerListCommand cmd thisPrayer =
    let
        thisCmd = if thisPrayer.id == "new"
            then "new"
            else cmd
    in
    
    prayerListDB
        [ thisCmd
        , thisPrayer.id
        , thisPrayer.who
        , thisPrayer.why
        , thisPrayer.ofType
        , thisPrayer.opId
        , "date goes here"
        ]

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
                layout ( Palette.layout model.width )
                ( column []
                    [ renderHeader "Getting Service" "Patience is a virtue" model
                    , image [ Palette.scaleWidth 200 model.width, centerX, centerY, paddingXY 0 20 ] 
                        { src = "https://media.giphy.com/media/ByuDOrJgpKCeA/source.gif"
                        , description = "Getting Service"
                        }
                    ]
                )
            Just source ->
                case Mark.compile document source of
                    Mark.Success thisService ->
                        let
                            rez = List.map (\fn -> fn model) thisService.body
                        in
                        layout
                        ( 
                            [ Html.Attributes.style "overflow" "hidden" |> htmlAttribute
                            , Palette.scaleFont model.width model.config.fontSize
                            , Font.family [ Font.typeface "Georgia"]
                            ] 
                            ++ Palette.swipe (onSwipeEvents PageSwipe)
                             
                        )
                        ( column [ ] rez )

                    -- Mark.Almost {resp, errors} ->
                    Mark.Almost x ->
                        -- this is the case where there has been an error,
                        -- but it hs been caught by `Mark.onError` and is still rendeable
                        -- let
                        -- -- convert List (model -> Element msg) to List (Element msg)
                        --     rez = List.map (\fn -> fn model) thisService.body
                        -- in
                        layout [] ( paragraph [] [ text "ERRORS GO HERE" ] )
                        -- layout []
                        -- ( column [] 
                        --    ( List.concat [(viewErrors errors), rez] )
                        -- )

                    Mark.Failure errors ->
                        layout []
                        ( column [] (viewErrors errors) )
        ]
    }


viewErrors : List Error -> List (Element Msg)
viewErrors errors =
    List.map
        (Mark.Error.toHtml Mark.Error.Light)
        errors
    |> List.map html

main =
    Browser.document
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }

