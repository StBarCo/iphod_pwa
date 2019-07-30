module Models exposing (..)

import Element
import Json.Decode as Decode exposing (Decoder, int, string, bool)
import Json.Decode.Pipeline exposing (required, optional, hardcoded)

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
    |> required "id" int
    |> required "ref" string
    |> required "style" string
    |> optional "vss" (Decode.list vsDecoder) []


type alias Lesson =
    { lesson: String
    , content: List Reading 
    }

initLesson : Lesson
initLesson = 
    { lesson = ""
    , content = [] 
    }

lessonDecoder : Decoder Lesson
lessonDecoder =
    Decode.succeed Lesson
    |> optional "lesson" string ""
    |> required "content" (Decode.list readingDecoder)


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
    , lessons : Lessons
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
    , lessons       = initLessons
    , openingSentences = []
    , online        = "loading"
    }

