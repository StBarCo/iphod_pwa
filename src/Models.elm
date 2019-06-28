module Models exposing (..)

import Element
import Json.Decode as Decode exposing (Decoder, int, string)
import Json.Decode.Pipeline exposing (required, optional)

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
    |> required "book" string
    |> required "chap" int
    |> required "vs" int
    |> optional "vss" string ""

type alias Reading =
    { ref: String
    , style: String
    , vss: List Verse
    }

initReading : Reading
initReading = 
    { ref = ""
    , style = "req"
    , vss = []
    }

readingDecoder : Decoder Reading
readingDecoder =
    Decode.succeed Reading
    |> required "ref" string
    |> required "style" string
    |> required "vss" (Decode.list vsDecoder)


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
    |> required "lesson" string
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
    -- , lessons   : Lessons
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
    -- , lessons    = []
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
    , season : String
    , color : String
    , showCalendar : Bool
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
    , season        = ""
    , color         = ""
    , showCalendar  = False
    , options       = []
    , calendar      = []
    , showMenu      = False
    , lessons       = initLessons
    , openingSentences = []
    , online        = "loading"
    }

