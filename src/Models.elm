module Models exposing (..)

import Element
import Json.Decode as Decode exposing (Decoder, int, string, bool, succeed)
import Json.Decode.Pipeline exposing (required, optional, hardcoded)
import Date exposing (Date, today)
import Time exposing (Month(..), utc, millisToPosix)
import Task
import MySwiper as Swiper


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

type alias RandomCanticle =
    { for: String }

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


type alias Prayer =
    { id: String
    , who: String
    , why: String
    , ofType: String
    , opId: String
    , tillWhen: Date
    }

prayerDecoder : Decoder Prayer
prayerDecoder =
    Decode.succeed Prayer
    |> required "id" string
    |> required "who" string
    |> required "why" string
    |> required "ofType" string
    |> optional "opId" string "op000"
    |> hardcoded (Date.fromCalendarDate 1970 Jan 1)

initPrayer : Prayer
initPrayer =
    { id = "new"
    , who = ""
    , why = ""
    , ofType = ""
    , opId = "op000"
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


type alias OccasionalPrayer =
    { id : String
    , category : String
    , title : String
    , source : String
    , prayer : String
    , show : Bool
    }

initOccassionalPrayer : OccasionalPrayer
initOccassionalPrayer = 
    { id = "id000"
    , category = "Other"
    , title = ""
    , source = "Self"
    , prayer = ""
    , show = False
    }
  
type alias OPList =
    { cat: String
    , prayers : List OccasionalPrayer 
    }

opDecoder : Decoder OccasionalPrayer
opDecoder =
    Decode.succeed OccasionalPrayer
    |> required "id" string
    |> required "category" string
    |> required "title" string
    |> required "source" string
    |> required "prayer" string
    |> hardcoded False


opListDecoder : Decoder OPList
opListDecoder =
    Decode.succeed OPList
    |> required "cat" string
    |> required "prayers" (Decode.list opDecoder)

type alias OccasionalPrayers =
    { categories : String -- seperated by "\n"
    , thisCat : String
    , list : List OccasionalPrayer
    }

initOPs : OccasionalPrayers
initOPs =
    { categories = ""
    , thisCat = ""
    , list = []
    }

type alias Collect =
    { id : String
    , title : String
    , text : String
    , show : Bool
    }

initCollect : Collect
initCollect =
    { id = ""
    , title = ""
    , text = ""
    , show = False
    }

type alias Canticle =
    { id : String
    , officeId: String
    , name : String
    , title : String
    , number : String
    , reference : String
    , notes : String
    , text : String
    }

canticleDecoder : Decoder Canticle
canticleDecoder =
    Decode.succeed Canticle
    |> required "_id" string
    |> optional "officeId" string "unknown"
    |> required "name" string
    |> required "title" string
    |> required "number" string
    |> required "reference" string
    |> required "notes" string
    |> required "text" string

type alias CanticleList = 
    { canticles: List Canticle }

canticleListDecoder : Decoder CanticleList
canticleListDecoder = 
    Decode.succeed CanticleList
    |> required "canticles" (Decode.list canticleDecoder)


initCanticle : Canticle
initCanticle = 
    { id = ""
    , officeId = ""
    , name = ""
    , title = ""
    , number = ""
    , reference = ""
    , notes = ""
    , text = ""
    }

type alias Timer =
    { id : String
    , end : Time.Posix
    }

initTimer : Timer
initTimer =
    { id = ""
    , end = millisToPosix 0
    }

type alias Device =
    { readingCycle : String
    , psalmsCycle : String
    , fontSize : Int
    }

initDevice : Device
initDevice =
    { readingCycle = "OneYear"
    , psalmsCycle = "ThirtyDay"
    , fontSize = 14
    }

deviceDecoder : Decoder Device
deviceDecoder =
    Decode.succeed Device
    |> required "readingCycle" string
    |> required "psalmsCycle" string
    |> required "fontSize" int


type alias Model =
    { config : Device
    , windowWidth : Int
    , width : Int
    , time : Time.Posix
    , timers : List Timer
    , swipingState : Swiper.SwipingState
    , pageTitle : String
    , pageName : String
    , source : Maybe String
    , requestLesson : String
    , currentAlt : String
    , today : String -- date string
    , day : String -- day of week string
    , week : String
    , year : String
    , season : (String, TempSeason)
    , color : String
    , showConfig : Bool
    , showCalendar : Bool
    , showThisCalendarDay : Int
    , options : List Options
    , calendar : List CalendarDay
    , showMenu : Bool
    , prayerList : PrayerList
    , collects : List Collect
    , canticles : List Canticle
    , officeCanticles : List Canticle
    , lessons : Lessons
    , eu : Lessons
    , mp : Lessons
    , ep : Lessons
    , openingSentences : List OpeningSentence
    , online : String
    , ops : OccasionalPrayers
    }
    

initModel : Model
initModel =
    { config = initDevice
    , windowWidth = 375
    , width = 355 -- iphone minus 20
    , time = millisToPosix 0
    , timers = []
    , swipingState  = Swiper.initialSwipingState
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
    , showConfig    = False
    , showCalendar  = False
    , showThisCalendarDay = -1
    , options       = []
    , calendar      = []
    , showMenu      = False
    , prayerList    = initPrayerList
    , collects      = []
    , canticles     = []
    , officeCanticles = []
    , lessons       = initLessons
    , eu            = initLessons
    , mp            = initLessons
    , ep            = initLessons
    , openingSentences = []
    , online        = "loading"
    , ops           = initOPs
    }

