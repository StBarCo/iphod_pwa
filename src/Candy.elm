module Candy exposing (..)

import Html exposing (audio)
import Html.Attributes exposing( controls, src)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Input as Input
import Element.Font as Font
import Element.Events as Event
import Mark
import Parser exposing ( .. )
import Regex exposing(replace, Regex)
import List.Extra exposing (getAt)
import String.Extra exposing (toTitleCase, toSentence)
import Palette exposing(scaleFont, scale, indent, outdent, scaleWidth)
import Models exposing (..)
import Time exposing (..)

audioParagraph : String -> Element msg
audioParagraph name =
  let
    audioFile = "./audio/" ++ name ++ ".mp3"
  in
  paragraph []
      [ html (audio [ src audioFile, controls True ]
          [Html.text (audioFile ++ " not available")] )
      ]

altCanticleLabel : String -> String -> Element msg
altCanticleLabel number name =
    paragraph []
      [ el [ width (px 50) ] ( text (number ++ ". ") )
      , el [] ( text (toTitleCase name) )
      ]

readingIntroduction : Model -> String -> List( Element msg )
readingIntroduction model lesson =
    let
        (skipIntro, ref) = case lesson of
           "lesson1" -> (False, model.lessons.lesson1.bookName)
           "lesson2" -> (skipLesson2 model lesson, model.lessons.lesson2.bookName)
           _ -> (True, "")

    in
    if skipIntro
        then
           [ none ]
        else
            [ paragraph (Palette.lessonTitle model.width)  [ text ("A Reading From " ++ ref) ]
            ]


addWordOfTheLord : List (Element msg) -> List (Element msg)
addWordOfTheLord vss =
    [ vss
    ,   [ paragraph [ indent "6rem", paddingXY 10 0 ] [ text "The Word of the Lord" ]
        , paragraph [ paddingXY 10 0 ]
            [ el [ ] ( text "People")
            , el [ indent "3.2rem" ] ( text "Thanks be to God" )
            ]
        ]
    ]
    |> List.concat

timeIsAfter : Posix -> Posix -> Bool
timeIsAfter t1 t2 =
    (posixToMillis t2) > (posixToMillis t1)

skipLesson2 : Model -> String -> Bool
skipLesson2 model lesson =
    model.config.readingCycle == "TwoYear" && (lesson == "lesson2" || lesson == "canticle2")

isEven : Int -> Bool
isEven n =
    modBy 2 n == 0

stringNotEmpty : String -> Bool
stringNotEmpty str =
    not (String.isEmpty str)


leadingSpaces : String -> Bool
leadingSpaces s =
    String.left 4 s == "    "

-- if the string begins with 4 spaces, indent
indentableParagraph : Int -> Int -> String -> Element msg
indentableParagraph normal indent s =
    let
        x = if leadingSpaces s
            then indent
            else normal
    in
    paragraph [ paddingXY x 0 ] [ text s ]

elsWithItalics : String -> List (Element msg)
elsWithItalics str =
    str
    |> String.split "/"
    |> List.filter stringNotEmpty
    |> List.indexedMap (\i txt ->
        if isEven i
        then
            el [] (text txt)
        else
            el [ Font.italic ] (text txt)
    )

collapseWhiteSpace : String -> String
collapseWhiteSpace str =
    let
        tabsEtc = Maybe.withDefault Regex.never <|
            Regex.fromString "[\\t\\n\\r]"
        multipleWhiteSpace = Maybe.withDefault Regex.never <|
            Regex.fromString "\\s\\s+"
    in
        str |> replace tabsEtc (\_ -> " ")
            |> replace multipleWhiteSpace (\_ -> " ")

insertAudio : String -> Element.Element msg
insertAudio query =
  let
    src = "https://audio.esv.org/hw/" ++ query
  in
  ( Html.audio [ Html.Attributes.controls True, Html.Attributes.src src] [] )
  |> Element.html

pageBreak : String -> Element.Element msg
pageBreak str =
    ( Html.a [ Html.Attributes.class "page" ] [] )
    |> Element.html


renderPlainText : Int -> String -> (Element msg)
renderPlainText width str =
    paragraph
    ( Palette.plain width )
    [ text (str |> collapseWhiteSpace ) ]

renderSectionTitle : Int -> String -> (Element msg)
renderSectionTitle width str =
    let
        link = str |> String.replace " " "_"
    in
    paragraph
    (Palette.section width)
    [ pageBreak link
    , text (str |> toTitleCase)
    ]

renderCollectTitle : Int -> String -> (Element msg)
renderCollectTitle width str =
    paragraph
    ( Palette.collectTitle width )
    ( elsWithItalics (str |> toTitleCase) )

renderDailyCollect : Int -> String -> String -> (Element msg)
renderDailyCollect width title text =
    column []
        [ renderCollectTitle width title
        , renderPlainText width text
        ]


-- prayers come with indents
renderPrayer : Int -> String -> (Element msg)
renderPrayer width str =
    let
        lns = str
            |> String.split "\n"
            |> List.map (\l ->
                let
                    x = if leadingSpaces l then 30 else 10
                in

                paragraph [indent "3rem", Element.width (px (width - 70)), paddingXY x 0 ]
                [ el [outdent "3rem"] none
                , text (String.trimRight l)
                ]
            )
    in
    column (Palette.prayer width) lns

renderPrayerListItem : Int -> OccasionalPrayer -> List (Element msg)
renderPrayerListItem width op =
    [ paragraph
        [ Font.bold ]
        [ text (op.category ++ ": " ++ (toTitleCase op.title)) ]
    , renderPlainText width op.prayer
    ]

backgroundGradient : String -> List (Attribute msg)
backgroundGradient s =
    let
        ang = 3.0
        (foreground, grad) = case s of
            "white" ->
                ( Palette.darkBlue
                , {angle = ang, steps = [rgb255 233 255 2, rgb255 237 239 210]}
                )
            "green" ->
                ( Palette.darkPurple
                , {angle = ang, steps = [rgb255 23 102 10, rgb255 226 255 221]}
                )
            "red"   ->
                ( Palette.foggy
                , {angle = ang, steps = [rgb255 119 2 14, rgb255 255 226 229]}
                )
            "violet"->
                ( Palette.foggy
                , {angle = ang, steps = [rgb255 60 1 99, rgb255 241 229 249]}
                )
            "blue"  ->
                ( Palette.foggy
                , {angle = ang, steps = [rgb255 0 5 99, rgb255 220 230 239]}
                )
            "rose"  ->
                ( Palette.darkGrey
                , {angle = ang, steps = [rgb255 188 9 103, rgb255 239 220 230]}
                )
            "gold"  ->
                ( Palette.darkGrey
                , {angle = ang, steps = [rgb255 233 255 2, rgb255 237 239 210]}
                )
            _       ->
                ( Palette.foggy
                , {angle = 1.0, steps = [Palette.foggy, Palette.foggy]}
                )
    in
    [ Font.color foreground, Background.gradient grad ]

borderShadow : String -> List (Attribute msg)
borderShadow color =
    case color of
        "white" -> [Border.shadow { offset = (5.0, -2.0), size = 5.0, blur = 20.0, color = Palette.litWhite} ]
        "green" -> [Border.shadow { offset = (5.0, -2.0), size = 5.0, blur = 20.0, color = Palette.litGreen} ]
        "red" -> [Border.shadow { offset = (5.0, -2.0), size = 5.0, blur = 20.0, color = Palette.litRed} ]
        "violet" -> [Border.shadow { offset = (5.0, -2.0), size = 5.0, blur = 20.0, color = Palette.litPurple} ]
        "blue" -> [Border.shadow { offset = (5.0, -2.0), size = 5.0, blur = 20.0, color = Palette.litBlue} ]
        "rose" -> [Border.shadow { offset = (5.0, -2.0), size = 5.0, blur = 20.0, color = Palette.litRose} ]
        "gold" -> [Border.shadow { offset = (5.0, -2.0), size = 5.0, blur = 20.0, color = Palette.darkGrey} ]
        _ -> [Border.shadow { offset = (5.0, -2.0), size = 5.0, blur = 20.0, color = Palette.foggy} ]
