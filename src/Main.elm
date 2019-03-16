port module Main exposing (..)

-- where

-- import Debug


-- import StartApp

import Browser exposing (Document)
import Html exposing (..)
import Html
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Platform.Sub as Sub exposing (batch)
import Platform.Cmd as Cmd exposing (Cmd)
import Markdown
import Update.Extra as Update exposing (andThen, filter)
import List.Extra exposing (getAt, splitWhen, groupsOf, updateAt, updateIf)
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Bootstrap.Navbar as Navbar
import Regex


-- MAIN
{-
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
-}

main = 
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


-- MODEL

type alias ReferenceStyle =
    { style: String
    , read: String
    } 

type alias AssignedReadings =
    { lesson1: List ReferenceStyle
    , lesson2: List ReferenceStyle
    , psalms: List String
    , gospel: List ReferenceStyle
    }

initAssignedReadings : AssignedReadings
initAssignedReadings =
    { lesson1 = []
    , lesson2 = []
    , psalms = []
    , gospel = []
    }

type alias Reading =
    { key: String
    , text: String
    }
initReading : Reading
initReading =
    { key = ""
    , text = ""
    }

type alias CalendarDay = 
    { show      : Bool
    , id        : Int
    , pTitle    : String
    , eTitle    : String
    , color     : String
    , colors    : List String
    , season    : String
    , week      : String
    , lityear   : String
    , month     : Int
    , dayOfMonth: Int
    , year      : Int
    , dow       : Int
    , mp        : AssignedReadings
    , ep        : AssignedReadings
    , eu        : AssignedReadings
    }


initCalendarDay : CalendarDay
initCalendarDay =
    { show       = False
    , id         = 0
    , pTitle     = ""
    , eTitle     = ""
    , color      = ""
    , colors     = []
    , season     = ""
    , week       = ""
    , lityear    = ""
    , month      = 0
    , dayOfMonth = 0
    , year       = 0
    , dow        = 0
    , mp         = initAssignedReadings
    , ep         = initAssignedReadings
    , eu         = initAssignedReadings
    }

type alias Model =
    { pageTitle: String
    , pageName: String
    , page: List (Html Msg)
    , navbarState : Navbar.State
    , raw : List String -- raw data
    , requestLesson : String
    , currentAlt : String
    , day : String
    , week : String
    , year : String
    , season : String
    , showCalendar : Bool
    , calendar : List CalendarDay
    }

initModel : Navbar.State -> Model
initModel state =
    { pageTitle     = "Legereme"
    , pageName      = "currentOffice"
    , page          = []
    , navbarState   = state
    , raw           = []
    , requestLesson = ""
    , currentAlt    = ""
    , day           = ""
    , week          = ""
    , year          = ""
    , season        = ""
    , showCalendar  = False
    , calendar      = []
    }


init : () -> ( Model, Cmd Msg )
init _ =
    let
        (navbarState, navbarCmd) =
            Navbar.initialState NavbarMsg
    in
    ( initModel navbarState, Cmd.batch[requestOffice "currentOffice", navbarCmd] )

-- tempModel is used to build protions of a page to be embedded in div's etc
tempModel : String -> Model -> Model
tempModel label model =
    { model 
    | page = []
    , requestLesson = ""
    , currentAlt = label
    }


-- REQUEST PORTS


port requestReference : List String -> Cmd msg
port requestOffice : String -> Cmd msg
-- port requestReadings : String -> Cmd msg
port requestLessons : String -> Cmd msg
port toggleButtons: List String -> Cmd msg
port requestTodaysLessons : (String, CalendarDay) -> Cmd msg
port clearLessons : String -> Cmd msg


-- SUBSCRIPTIONS


--port receivedReading : (Reading -> msg) -> Sub msg
port receivedCalendar : (List CalendarDay -> msg) -> Sub msg
port receivedOffice : (List String -> msg) -> Sub msg
-- port receivedPsalms : (String -> msg) -> Sub msg
-- port receivedLesson1 : (String -> msg) -> Sub msg
-- port receivedLesson2 : (String -> msg) -> Sub msg
-- port receivedGospel : (String -> msg) -> Sub msg



subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ receivedCalendar UpdateCalendar
        , receivedOffice UpdateOffice
--        , receivedPsalms UpdatePsalms
--        , receivedLesson1 UpdateLesson1
--        , receivedLesson2 UpdateLesson2
--        , receivedGospel UpdateGospel
        ]



-- UPDATE


type ShowHide
    = Show
    | Hide


type Msg
    = NoOp
    | NavbarMsg Navbar.State
    | UpdateCalendar (List CalendarDay)
    | UpdateReading Reading
    | UpdateOffice (List String)
    | Calendar
    | DayClick CalendarDay
    | MorningPrayer
    | MiddayPrayer
    | EveningPrayer
    | Compline
    | Family
    | AltButton String String
    | RequestReference String String
    | TodaysLessons String CalendarDay
--    | RequestLessons
--    | UpdatePsalms String
--    | UpdateLesson1 String
--    | UpdateLesson2 String
--    | UpdateGospel String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        NavbarMsg state ->
            ( { model | navbarState = state}, Cmd.none)

        UpdateCalendar newCalendar ->
            let
                newModel = initModel model.navbarState
            in
                    
            ( { newModel 
                | calendar = newCalendar
                , showCalendar = True
              }
            , Cmd.none
            )

        UpdateReading newReading ->
            ( model , Cmd.none )

        UpdateOffice raw ->
            let
                newModel =
                    formatOffice <|
                        { model 
                        | page = []
                        , day = raw |> getAt 0 |> Maybe.withDefault "Sunday" 
                        , week = raw |> getAt 1 |> Maybe.withDefault "1"
                        , year = raw |> getAt 2 |> Maybe.withDefault "a"
                        , season = raw |> getAt 3 |> Maybe.withDefault "anytime"
                        , pageName = raw |> getAt 4 |> Maybe.withDefault "currentOffice"
                        , raw = raw |> List.drop 5
                        , showCalendar = False
                        , calendar = []
                        }
            in
            ( newModel, Cmd.batch[ requestLessons newModel.pageName, Cmd.none ] )
                -- |> Update.andThen update AddToOffice

        Calendar -> 
            ( { model | pageTitle = "Calendar", pageName = "calendar", page = [] }
            , Cmd.batch [ requestOffice "calendar"
                        , Cmd.none
                        ]
            )

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
                    

        MorningPrayer ->
            ( {model | pageTitle = "Morning Prayer", pageName = "morning_prayer", page = []}
            , Cmd.batch [   requestOffice "morning_prayer"
                        ,   Cmd.none
                        ] 
            )
                    
        MiddayPrayer ->
            -- requestOffice "midday"
            ( {model | pageTitle = "Midday Prayer", pageName = "midday", page = []}
            , Cmd.batch [   requestOffice "midday"
                        ,   Cmd.none
                        ]
            )
                    
        EveningPrayer ->
            ( {model | pageTitle = "Evening Prayer", pageName = "evening_prayer", page = []}
            , Cmd.batch [   requestOffice "evening_prayer"
                        ,   Cmd.none
                        ]
            )
                    
        Compline ->
            ( {model | pageTitle = "Compline", pageName = "compline", page = []}
            , Cmd.batch [requestOffice "compline", Cmd.none] 
            )

        Family -> 
            ( {model | pageTitle = "Family", pageName = "family", page = []}
            , Cmd.batch [requestOffice "family_prayer", Cmd.none] 
            )

        AltButton altDiv buttonLabel ->
            (model, Cmd.batch [toggleButtons [altDiv, buttonLabel], Cmd.none] )  

        RequestReference readingId ref ->
            (model, Cmd.batch [requestReference [readingId, ref], Cmd.none] )  

        TodaysLessons office day ->
            let
                _ =
                    Debug.log "ToDaysLessons: " (office, day)
            in
            (model, Cmd.batch[ requestTodaysLessons (office, day), Cmd.none])
                    




-- HELPERS

formatOffice : Model -> Model
formatOffice model =
    case (model.raw |> List.head) of
        Nothing -> model -- nothing left
        Just "--EOF--" ->
            { model | raw = model.raw |> List.drop 1 }

        Just "--END--" -> 
            { model | raw = model.raw |> List.drop 1 }

        Just "alternatives" -> 
            alternatives model |> formatOffice
        Just "alternative" -> 
            alternative model "alternative" |> formatOffice
        Just "collect" -> collect model |> formatOffice
        Just "default" -> 
            alternative model "alternative default" |> formatOffice
        Just "indent" -> oneArg model |> formatOffice
        Just "line" -> oneArg model |> formatOffice
        Just "prayer" -> oneArg model |> formatOffice
        Just "psalm_name" -> psalmName model |> formatOffice
        Just "psalm1" -> psalm1 model |> formatOffice
        Just "psalm2" -> oneArg model  |> formatOffice
        Just "reading" -> reading model |> formatOffice
        Just "ref" -> reference model |> formatOffice
        Just "referenceText" -> referenceText model |> formatOffice
        Just "rubric" -> oneArg model |> formatOffice
        Just "scripture" -> scripture model |> formatOffice
        Just "section" -> oneArg model |> formatOffice
        Just "title" -> oneArg model |> formatOffice
        Just "versical" -> versical model |> formatOffice
        _ ->
            { model | raw = model.raw |> List.drop 1 } |> formatOffice


-- create and div to hold all the alternatives
-- the buttons go into sub div class "altButtons"                
alternatives : Model -> Model
alternatives model =
    let
        c = model.raw |> getAt 0 |> Maybe.withDefault ""
        label = model.raw |> getAt 2 |> Maybe.withDefault ""
        altsId =  label |> makeId "alternatives_"
        temp = { model | raw = model.raw |> List.drop 3 } |> tempModel label
        subModel =  temp |> formatOffice
        newDiv =
            div [ id altsId, class c ]
            (   (div [ class "altButtons" ] ( buttonBuilder temp.raw label [] )
                ) :: subModel.page
            )
                    
            -- do some smart stuff here
    in
    { model
    | page = [newDiv] |> List.append model.page
    , raw = subModel.raw
    }

alternative : Model -> String -> Model
alternative model ofType =
    let
        -- c = model.raw |> getAt 0 |> Maybe.withDefault ""
        label = model.currentAlt
        altId = model.raw |> getAt 2 |> Maybe.withDefault "" |> makeId (label ++ "Id_")
        subModel = { model | raw = model.raw |> List.drop 3 } |> (tempModel label) |> formatOffice
        newDiv = 
            div [ id altId, class ofType ] subModel.page
    in
    { model 
    | page = [newDiv] |> List.append model.page
    , raw = subModel.raw
    }


dropThroughKey : a -> List a -> List a
dropThroughKey key list =
    case (list |> List.Extra.elemIndex key) of
        Just n -> 
            list |> List.drop (n + 1)
        Nothing -> list


buttonBuilder : List String -> String -> List (Html Msg) -> List (Html Msg)
buttonBuilder list superClass buttons =
    let
        subLists = subListTuple list "--END--"
        subList1 = subLists |> Tuple.first
        subList2 = subLists |> Tuple.second
        allDone = subList1 |> List.isEmpty
            
    in
    case allDone of
        True -> buttons |> List.reverse            
        False ->
            let
                cls = subList1 |> getAt 0 |> Maybe.withDefault "" |> makeId "button_"
                label = subList1 |> getAt 2 |> Maybe.withDefault ""
                -- altDivId = label |> makeId ""
                buttonId = label |> makeId (superClass ++ "Button_")
        
            in
            ( button  [ id buttonId
                    , class cls
                    , onClick (AltButton superClass buttonId)
                    ]                    
                    [ Markdown.toHtml [] label ] :: buttons
            ) |> buttonBuilder subList2 superClass


collect : Model -> Model
collect model =
    let
        cls = "collectContent"
        s = model.raw |> getAt 4 |> Maybe.withDefault ""
        title = if s |> String.isEmpty 
            then "" 
            else  
                   (model.raw |> getAt 1 |> Maybe.withDefault "")
                ++ " _"
                ++ (model.raw |> getAt 2 |> Maybe.withDefault "")
                ++ "_"     

        collectId = if s |> String.isEmpty
            then "collectOfDay"
            else title |> makeId "collect_"
            
    in
    { model 
    | page = 
        [ div [ id collectId, class cls ] 
            [ div [ class "collectTitle" ] [ Markdown.toHtml [] title ]
            , div [ class cls ] [ Markdown.toHtml [] s ] 
            ]
        ] |> List.append model.page
    , raw = model.raw |> List.drop 5
    }
            

oneArg : Model -> Model
oneArg model =
    let
        s = model.raw |> getAt 1 |> Maybe.withDefault ""
        c = model.raw |> getAt 0 |> Maybe.withDefault ""
    in
    { model
    | page = [ div [ class c ] [ Markdown.toHtml [] s ] ] |> List.append model.page 
    , raw = model.raw |> List.drop 2
    }

psalmName : Model -> Model
psalmName model =
    let
        c = model.raw |> getAt 0 |> Maybe.withDefault ""
        name = model.raw |> getAt 1 |> Maybe.withDefault ""
        title = model.raw |> getAt 2 |> Maybe.withDefault ""
            
    in
    { model
    | page = [ p [ class c ] [ text name, span [] [ text title ] ] ] |> List.append model.page
    , raw = model.raw |> List.drop 2
    }
            

psalm1 : Model -> Model
psalm1 model =
    let
        c = model.raw |> getAt 0 |> Maybe.withDefault ""
        n = model.raw |> getAt 1 |> Maybe.withDefault ""
        s = model.raw |> getAt 2 |> Maybe.withDefault ""
            
    in
    { model
    | page = [ p [ class c ] [ sup [] [ text n], text s ] ] |> List.append model.page 
    , raw = model.raw |> List.drop 3
    }
            
scripture : Model -> Model
scripture model =
    let
        c = model.raw |> getAt 0 |> Maybe.withDefault ""
        s = model.raw |> getAt 1 |> Maybe.withDefault ""
        ref = model.raw |> getAt 2 |> Maybe.withDefault ""
            
    in
    { model
    | page = [ div [ class c ] [ text s, span [ class "ref" ] [ text ref ]] ] |> List.append model.page 
    , raw = model.raw |> List.drop 2
    }

versical : Model -> Model
versical model =
    let
        c = model.raw |> getAt 0 |> Maybe.withDefault ""
        speaker = model.raw |> getAt 1 |> Maybe.withDefault ""
        says = model.raw |> getAt 2 |> Maybe.withDefault ""
            
    in
    { model
    | page = 
        [ Grid.simpleRow
            [ Grid.col [ Col.xs2, Col.sm2, Col.md1, Col.lg1] [ em [] [ text speaker ] ]
            , Grid.col [ Col.xs8, Col.sm8, Col.md4, Col.lg4] [ text says ]
            ]
        ] |> List.append model.page 
    , raw = model.raw |> List.drop 3
    }

reading : Model -> Model
reading model =
    let
        c = model.raw |> getAt 0 |> Maybe.withDefault ""
        mpep = model.raw |> getAt 1 |> Maybe.withDefault ""
        thisReading = mpep
              
    in
    { model
    | page = [ div [ id mpep ] [] ] |> List.append model.page 
    , raw = model.raw |> List.drop 2
    , requestLesson = mpep
    }

reference : Model -> Model
reference model =
    let
        c = model.raw |> getAt 0 |> Maybe.withDefault ""
        ref = model.raw |> getAt 1 |> Maybe.withDefault ""
            
    in
    { model
    | page = [ p [class c] [text ref] ] |> List.append model.page 
    , raw = model.raw |> List.drop 2
    }


referenceText : Model -> Model
referenceText model =
    let
        c = model.raw |> getAt 0 |> Maybe.withDefault ""
        ref = model.raw |> getAt 1 |> Maybe.withDefault ""
        readingId = ref |> makeId "button_"
               
    in
    { model
    | page =
        [ p [ class c ] 
            [ button [ id readingId, onClick (RequestReference readingId ref) ] 
              [ text ref ] 
            ]
        ] |> List.append model.page 
    , raw = model.raw |> List.drop 2
    }

userReplace : String -> (Regex.Match -> String) -> String -> String
userReplace userRegex replacer string =
    case Regex.fromString userRegex of
        Nothing -> string
        Just regex ->
            Regex.replace regex replacer string

makeId : String -> String -> String
makeId idType string =
    let
        labelName =
            (userReplace "[^a-zA-Z0-9]" (\_ -> "_") string)
            
    in
            
    (idType ++ labelName) |> String.toLower

subListTuple : List String -> String -> (List String, List String)
subListTuple list splitHere =
    case ( list |> splitWhen (\s -> s == splitHere) ) of
        Just (a, b) -> (a,  b |> List.drop 1 )
        Nothing -> ([], [])

-- VIEW


view : Model -> Document Msg
view model =
    let
        page = if model.showCalendar
            then
                [ div [ id "calendar" ] (calendar model.calendar) 
                , div [ id "daily_readings_list" ] (daily_readings_list model
                    )
                ]
            else
                [ div [ id "service"] model.page ]

    in
            
    { title = model.pageTitle
    , body = navigation model :: page
    }
            
navigation : Model -> Html Msg
navigation model =
    Navbar.config NavbarMsg
        |> Navbar.brand [ href "#" ] [ text "Legereme"]
        |> Navbar.items
            [ Navbar.itemLink [ href "#", onClick Calendar ] [ text "Calendar"]
            , Navbar.itemLink [ href "#", onClick MorningPrayer ] [ text "Morning" ]
            , Navbar.itemLink [ href "#", onClick MiddayPrayer ] [ text "Midday" ]
            , Navbar.itemLink [ href "#", onClick EveningPrayer ] [ text "Evening" ]
            , Navbar.itemLink [ href "#", onClick Compline ] [ text "Compline" ]
            , Navbar.itemLink [ href "#", onClick Family ] [ text "Family" ]

            ]
        |> Navbar.view model.navbarState

daily_readings_list : Model -> List (Html Msg)
daily_readings_list model =
    let
        d = 
            model.calendar 
            |> List.filter (\c -> c.show == True)
            |> getAt 0
            |> Maybe.withDefault initCalendarDay
        _ = Debug.log "THIS DAY: " d
    in
    if d.show then buildDayList d else []       

calendar : List CalendarDay -> List (Html Msg)
calendar days =
    let
        thisCalendar = if days |> List.isEmpty
            then []
            else buildMonth days
    in
    thisCalendar

buildDayList : CalendarDay -> List (Html Msg)
buildDayList d =
    [ div [] 
      [ p [] [ text 
            ( [ intToDay(d.dow)
              , intToMonth(d.month)
              , String.fromInt(d.dayOfMonth)
              , String.fromInt(d.year)
              , d.season
              , d.week
              , d.lityear
              ] |> String.join " "
            ) ]
      , ul [] 
        [ li [ onClick (TodaysLessons "mp" d) ] 
          [ text "Morning Prayer"
          , ul [] 
            [ li [] 
              [ text ("Psalms: " ++ (d.mp.psalms |> String.join ", ")) 
              , div [ id "mpp_today", class "lessons_today"] []
              ]
            , li [] 
              [ text (lessonToText "Lesson 1:" d.mp.lesson1) 
              , div [ id "mp1_today", class "lessons_today"] []
              ]
            , li [] 
              [ text (lessonToText "Lesson 2:" d.mp.lesson2) 
              , div [ id "mp2_today", class "lessons_today"] []
              ]
            ]
          ]
        , li [ onClick (TodaysLessons "ep" d) ] 
            [ text "Evening Prayer"
            , ul [] 
              [ li [] 
                [ text ("Psalms: " ++ (d.ep.psalms |> String.join ", ")) 
                , div [ id "epp_today", class "lessons_today"] []
                ]
              , li [] 
                [ text (lessonToText "Lesson 1:" d.ep.lesson1) 
                , div [ id "ep1_today", class "lessons_today"] []
                ]
              , li [] 
                [ text (lessonToText "Lesson 2:" d.ep.lesson2) 
                , div [ id "ep2_today", class "lessons_today"] []
                ]
              ]
            ]
        , li [ onClick (TodaysLessons "eu" d) ] 
            [ text ("Holy Eucharist: " ++ d.eTitle)
            , ul [] 
              [ li [] 
                [ text (lessonToText "Lesson 1:" d.eu.lesson1) 
                , div [ id "eu1_today", class "lessons_today"] []
                ]
              , li [] 
                [ text ("Psalms: " ++ (d.eu.psalms |> String.join " or ")) 
                , div [ id "eup_today", class "lessons_today"] []
                ]
              , li [] 
                [ text (lessonToText "Lesson 2:" d.eu.lesson2) 
                , div [ id "eu2_today", class "lessons_today"] []
                ]
              , li [] 
                [ text (lessonToText "Gospel" d.eu.gospel) 
                , div [ id "eugs_today", class "lessons_today"] []
                ]
              ]
           ]
        ]
      ] 
    ]

lessonToText : String -> List ReferenceStyle -> String
lessonToText label refs =
    let
        lessonRef ref = 
            if ref.style == "req"
            then ref.read
            else "[" ++ ref.read ++ "]"
            
    in
    label ++ " " ++ (List.map lessonRef refs |> String.join ", ")


buildMonth : List CalendarDay -> List (Html Msg)
buildMonth days =
    let
        week sevenDays = buildWeek sevenDays
            
    in
    [ table [ id "calendar_month" ]
        (List.map week (days |> groupsOf 7) )
    ]    

            
buildWeek : List CalendarDay -> Html Msg
buildWeek days =
    let
        buildDay day =
            td [ class ("calendar_day day_" ++ day.color), onClick (DayClick day) ]
            [ p [] [ text (day.dayOfMonth |> String.fromInt) ]
            , p [] [ text day.pTitle ]
            ]
                
    in
    tr [ class "calendar_week" ]
      ( List.map buildDay days )
   
intToDay : Int -> String
intToDay n =
    case n of
    0 -> "Sunday"     
    1 -> "Monday"     
    2 -> "Tueday"     
    3 -> "Wednesday"     
    4 -> "Thursday"     
    5 -> "Friday"     
    6 -> "Saturday"     
    _ -> "Invalid Day: " ++ (String.fromInt n)

intToMonth : Int -> String
intToMonth n =
    case n of
        1 -> "January"
        2 -> "February"
        3 -> "March"
        4 -> "April"
        5 -> "May"
        6 -> "June"
        7 -> "July"
        8 -> "August"
        9 -> "September"
        10 -> "October"
        11 -> "November"
        12 -> "December"
        _ -> "Invalid Month: " ++ (String.fromInt n)

