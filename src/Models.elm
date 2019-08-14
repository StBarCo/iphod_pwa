module Models exposing (..)

import Element
import Json.Decode as Decode exposing (Decoder, int, string, bool, succeed)
import Json.Decode.Pipeline exposing (required, optional, hardcoded)
import Date exposing (Date, today)
import Time exposing (Month(..))

-- PARSER MODELS

type alias OpeningSentence =
    { tag: String
    , label: String
    , ref: String
    , text: String
    }

type alias Antiphon =
    { tag: String
    , label: String
    , text: String
    }
type alias Option =
    { selected: String
    , tag: String
    , label: String
    , text: String
    }

type alias Options =
    { tag: String
    , label: String
    , options: List Option
    }

type alias OptionsHeader = 
    { tag: String
    , label: String
    }
type alias TempSeason =
    { season: String
    , week: String
    , year: String
    , today: String
    }

type Service
    = Eucharist
    | MorningPrayer
    | EveningPrayer

type ReadingType
    = Lesson1
    | Lesson2
    | Psalms
    | Gospel
    | All

type alias ServiceReadingRequest =
    { id : Int
    , reading : String
    , service : String
    , dayOfMonth : Int
    , month : Int
    , year : Int
    }

initTempSeason : TempSeason
initTempSeason =
    { season = ""
    , week = ""
    , year = ""
    , today = ""
    }


initOption : Option
initOption =
    { selected = "True"
    , tag = ""
    , label = "Error Parsing Option"
    , text = ""
    }

initOptions : Options
initOptions = 
    { tag = ""
    , label = "NoOptions Available"
    , options = []
    }

initOptionsHeader : OptionsHeader
initOptionsHeader =
    { tag = ""
    , label = "Error Parsing Options Header"
    }

-- PAGE MODELS

type alias Verse =
    { book: String
    , chap: Int
    , vs: Int
    , text: String
    }

initVerse : Verse
initVerse = 
    { book = ""
    , chap = 0
    , vs = 0
    , text = ""
    }

vsDecoder : Decoder Verse
vsDecoder =
    Decode.succeed Verse
    |> optional "book" string ""
    |> optional "chap" int 0
    |> optional "vs" int 0
    |> optional "vss" string ""

type alias Reading =
    { id: Int
    , read: String
    , style: String
    , vss: List Verse
    }

initReading : Reading
initReading = 
    { id = 0
    , read = ""
    , style = "req"
    , vss = []
    }

readingDecoder : Decoder Reading
readingDecoder =
    Decode.succeed Reading
    |> optional "id" int 0
    |> required "ref" string
    |> required "style" string
    |> optional "vss" (Decode.list vsDecoder) []


type alias Lesson =
    { lesson: String
    , content: List Reading 
    , spa_location: String
    }

initLesson : Lesson
initLesson = 
    { lesson = ""
    , content = [] 
    , spa_location = ""
    }

lessonDecoder : Decoder Lesson
lessonDecoder =
    Decode.succeed Lesson
    |> optional "lesson" string ""
    |> required "content" (Decode.list readingDecoder)
    |> optional "spa_location" string "office"


type alias Lessons =
    { lesson1: Lesson
    , lesson2: Lesson
    , psalms: Lesson
    , gospel: Lesson
    }

initLessons : Lessons
initLessons =
    { lesson1 = initLesson
    , lesson2 = initLesson
    , psalms = initLesson
    , gospel = initLesson
    }

serviceLessonsDecoder : Decoder Lessons
serviceLessonsDecoder =
    Decode.succeed Lessons
    |> required "lesson1" lessonDecoder 
    |> required "lesson2" lessonDecoder 
    |> required "psalms" lessonDecoder 
    |> optional "gospel" lessonDecoder initLesson

type alias CalendarDay = 
    { show      : Bool
    , id        : Int
    , pTitle    : String
    , eTitle    : String
    , color     : String
    , colors    : List String
    , season    : String
    , week      : String
    , weekOfMon : Int
    , lityear   : String
    , month     : Int
    , dayOfMonth : Int
    , year      : Int
    , dow       : Int
    , mp        : Lessons
    , ep        : Lessons
    , eu        : Lessons
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
    , weekOfMon  = 0
    , lityear    = ""
    , month      = 0
    , dayOfMonth = 0
    , year       = 0
    , dow        = 0
    , mp         = initLessons
    , ep         = initLessons
    , eu         = initLessons
    }

type alias Calendar = 
    { calendar: List CalendarDay }

calendarDecoder : Decoder Calendar
calendarDecoder =
    Decode.succeed Calendar
    |> required "calendar" (Decode.list dayDecoder)

dayDecoder : Decoder CalendarDay
dayDecoder =
    Decode.succeed CalendarDay
    |> required "show" bool
    |> required "id" int
    |> required "pTitle" string
    |> required "eTitle" string
    |> required "color" string
    |> required "colors" (Decode.list string)
    |> required "season" string
    |> required "week" string
    |> required "weekOfMon" int
    |> required "lityear" string
    |> required "month" int
    |> required "dayOfMonth" int
    |> required "year" int
    |> required "dow" int
    |> required "mp" serviceLessonsDecoder
    |> required "ep" serviceLessonsDecoder
    |> required "eu" serviceLessonsDecoder

type PrayerType
    = Sick
    | SickChild
    | Surgery
    | Strength
    | Sanctification
    | Health
    | Recovery
    | LittleHope
    | Other

prayerTypeToTitle : PrayerType -> String
prayerTypeToTitle pt =
    case pt of
        Sick -> "For A Sick Person"
        SickChild -> "For A Sick Child"
        Surgery -> "Before An Operation"
        Strength -> "For Strength and Confidence"
        Sanctification -> "For the Sanctification of Illness"
        Health -> "For Health of Body and Soul"
        Recovery -> "Thanksgiving For A Beginning Of Recovery"
        LittleHope -> "Little Hope of Recovery"
        Other -> "Other"


prayerTypeToString : PrayerType -> String
prayerTypeToString pt = 
    case pt of
        Sick -> "sick"
        SickChild -> "sick_child"
        Surgery -> "surgery"
        Strength -> "strength"
        Sanctification -> "sanctification"
        Health -> "health"
        Recovery -> "recovery"
        LittleHope -> "little_hope"
        Other -> "other"

stringToPrayerType : String ->  Decoder PrayerType
stringToPrayerType str =
    case str of
        "sick" ->  succeed Sick
        "sick_child" ->  succeed SickChild
        "surgery" ->  succeed Surgery
        "strength" ->  succeed Strength
        "santification" ->  succeed Sanctification
        "health" ->  succeed Health
        "recovery" ->  succeed Recovery
        "little_hope" ->  succeed LittleHope
        "other" ->  succeed Other
        _ -> succeed Other


type alias Prayer =
    { id: String
    , who: String
    , why: String
    , ofType: PrayerType
    , tillWhen: Date
    }

prayerDecoder : Decoder Prayer
prayerDecoder =
    Decode.succeed Prayer
    |> required "id" string
    |> required "who" string
    |> required "why" string
    |> required "ofType" (string |> Decode.andThen stringToPrayerType)
    |> hardcoded (Date.fromCalendarDate 1970 Jan 1)

initPrayer : Prayer
initPrayer =
    { id = "new"
    , who = ""
    , why = ""
    , ofType = Other
    , tillWhen = Date.fromCalendarDate 1970 Jan 1
    }

type alias PrayerList =
    { show : Bool
    , edit : Bool
    , prayers : List Prayer
    }

initPrayerList : PrayerList
initPrayerList = 
    { show = False
    , edit = False
    , prayers = []
    }

prayerListDecoder : Decoder PrayerList
prayerListDecoder =
    Decode.succeed PrayerList
    |> hardcoded False
    |> hardcoded False
    |> required "prayers" (Decode.list prayerDecoder)

prayerCategories =
    { sick = "For the Sick"
    , sickChild = "Sick Child"
    , surgery = "Before an Surgery"
    , strength = "Strength & Confidence"
    , sanctification = "Sanctification of Illness"
    , health = "Health of Body & Soul"
    , recovery = "Beginning of Recovery"
    , littleHope = "Little Hope of Recovery"
    }


type alias Model =
    { windowWidth : Int
    , width : Int
    , pageTitle : String
    , pageName : String
    , source : Maybe String
    , requestLesson : String
    , currentAlt : String
    , today : String -- date string
    , day : String
    , week : String
    , year : String
    , season : (String, TempSeason)
    , color : String
    , showCalendar : Bool
    , showThisCalendarDay : Int
    , options : List Options
    , calendar : List CalendarDay
    , showMenu : Bool
    , prayerList : PrayerList
    , lessons : Lessons
    , eu : Lessons
    , mp : Lessons
    , ep : Lessons
    , openingSentences : List OpeningSentence
    , online : String
    }
    

initModel : Model
initModel =
    { windowWidth = 375
    , width = 355 -- iphone minus 20
    , pageTitle     = "Legereme"
    , pageName      = "currentOffice"
    , source        = Nothing
    , requestLesson = ""
    , currentAlt    = ""
    , today         = ""
    , day           = ""
    , week          = ""
    , year          = ""
    , season        = ("", initTempSeason)
    , color         = ""
    , showCalendar  = False
    , showThisCalendarDay = -1
    , options       = []
    , calendar      = []
    , showMenu      = False
    , prayerList    = initPrayerList
    , lessons       = initLessons
    , eu            = initLessons
    , mp            = initLessons
    , ep            = initLessons
    , openingSentences = []
    , online        = "loading"
    }

