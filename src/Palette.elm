module Palette exposing (..)

import Html.Attributes
import Html
import Element exposing ( Attribute
                        , rgb255
                        , rgba255
                        , paddingEach
                        , padding
                        , paddingXY
                        , spacing
                        , spacingXY
                        , px
                        , width
                        , height
                        , moveLeft
                        , centerX
                        , centerY
                        )
import Element.Background as Background
import Element.Border as Border
import Element.Input as Input
import Element.Font as Font
import Models exposing(..)

darkRed = rgb255 100 0 0
darkBlue = rgb255 13 44 117
darkGrey = rgb255 80 80 80
darkPurple = rgb255 77 15 70
foggy = rgb255 250 250 250
litGreen = rgb255 16 104 16
litWhite = rgb255 255 226 12
litPurple = rgb255 109 8 168
litBlue = rgb255 0 5 99 -- this might not be right
litRed = rgb255 188 5 33
litRose = rgb255 188 9 103 -- this might not be right
black = rgb255 0 0 0

edges : { top: Int, right: Int, bottom: Int, left: Int }
edges = { top = 0, right = 0, bottom = 0, left = 0 }

wordBreak : Element.Attribute msg
wordBreak =
    Html.Attributes.style "word-break"  "break-word" |> Element.htmlAttribute

fixedPosition : Element.Attribute msg
fixedPosition =
    Html.Attributes.style "position" "fixed" |> Element.htmlAttribute

hyphenate : Element.Attribute msg
hyphenate =
     Html.Attributes.style "hyphens" "auto" |> Element.htmlAttribute

english : Element.Attribute msg
english =
    Html.Attributes.style "lang" "en" |> Element.htmlAttribute

whiteSpace : String -> Element.Attribute msg
whiteSpace str =
    Html.Attributes.style "white-space" str |> Element.htmlAttribute

placeholder : String -> Element.Attribute msg
placeholder str =
    Html.Attributes.placeholder str |> Element.htmlAttribute

zIndex : Int -> Element.Attribute msg
zIndex z =
    Html.Attributes.style "z-index" (z |> String.fromInt) |> Element.htmlAttribute

scale: Int -> Int -> Int
scale viewWidth n =
    if viewWidth > 700
    then
        ((toFloat viewWidth  / 700) * (toFloat n)) |> round
    else
        ((toFloat viewWidth  / 375) * (toFloat n)) |> round

scalePx : Int -> Int -> Element.Length
scalePx viewWidth n =
    Element.px (scale viewWidth n)

scaleWidth : Int -> Int -> Attribute msg
scaleWidth viewWidth n =
    Element.width (scalePx viewWidth n)

adjustWidth : Int -> Int -> Attribute msg
adjustWidth viewWidth adj =
    width (px (viewWidth + adj) )

maxWidth : Int -> Attribute msg
maxWidth viewWidth =
    width (px (viewWidth - 25))

scaleFont : Int -> Int -> Attribute msg
scaleFont viewWidth n =
    (scale viewWidth n) |> Font.size

pageWidth : Int -> Attribute msg
pageWidth viewWidth =
    Element.width (px viewWidth)

indent : String -> Attribute msg
indent s =
    Element.htmlAttribute <| Html.Attributes.style "margin-left" s

outdent : String -> Attribute msg
outdent s =
    Element.htmlAttribute <| Html.Attributes.style "margin-left" ("-" ++s)

hide : Element.Attribute msg
hide =
    Html.Attributes.style "display" "none"
    |> Element.htmlAttribute

show : Element.Attribute msg
show =
    Html.Attributes.style "display" "block"
    |> Element.htmlAttribute

swipe : List (Html.Attribute msg) -> List (Attribute msg)
swipe msgs =
    msgs |> List.map (\m -> Element.htmlAttribute m)

-- these classes come from an API and need to be mapped from text
class : String -> List (Attribute msg)
class name =
    case name of
        "vs" -> -- verse numner
            [ Font.color darkRed
            , paddingEach { top= 0, right= 10, bottom = 0, left = 10}
            ]
        "wj" -> -- words of Jesus
            [ Font.color darkRed ]
        "q" ->
            []
        "q2" ->
            [ paddingEach {edges | left = 10} ]
        "pi" ->
            [ paddingEach {edges | left = 10}
            ]
        _ ->
            []

antiphon : Int -> List (Attribute msg)
antiphon viewWidth =
    [ maxWidth viewWidth
    , paddingEach { edges | top = 10, left = 10 }
    ]

antiphonTitle : Int -> List (Attribute msg)
antiphonTitle viewWidth =
    [ paddingEach { edges | top = 10 }
    , Font.italic
    , Font.color darkBlue
    , Font.variant Font.smallCaps
    , outdent "3rem"
    ]

button : Int -> List (Attribute msg)
button viewWidth =
    [ Border.color darkRed
    , Border.rounded 5
    , Border.width 5
    , padding 10
    , spacing 10
    , Background.color darkRed
    , Font.color foggy
    , centerX
    , centerY
    ]

buttonAltInvitatory : Int -> List (Attribute msg)
buttonAltInvitatory viewWidth =
    [ Border.color darkRed
    , Border.rounded 5
    , Border.width 5
    , padding 10
    , spacing 10
    , Background.color darkRed
    , Font.color foggy
    , centerX
    , centerY
    , spacing 3
    , scaleFont viewWidth 12
    ]


calendarDay : Int -> List (Attribute msg)
calendarDay viewWidth =
    [ Border.width 1
    , Border.rounded 3
    , scaleFont viewWidth 8
    , width (scalePx viewWidth 50)
    , height (scalePx viewWidth 50)
    , english
    , hyphenate
    ]

collectTitle : Int -> List (Attribute msg)
collectTitle viewWidth =
    [ paddingEach { edges | top = 10, left = 10, bottom = 2 }
    , Font.variant Font.smallCaps
    , Font.color darkBlue
    , scaleFont viewWidth 16
    , maxWidth viewWidth
    ]

layout : Int -> List (Attribute msg)
layout viewWidth =
    [ Font.family [ Font.typeface "Georgia"]
    , maxWidth viewWidth
    , paddingEach { edges | left = 10, right = 10 }
    ]

lesson : Int -> List (Attribute msg)
lesson viewWidth =
    [ paddingXY 3 0
    , maxWidth viewWidth
    , whiteSpace "normal"
    ]

lessonTitle : Int -> List (Attribute msg)
lessonTitle viewWidth =
    [ Font.color darkBlue
    , Font.variant Font.smallCaps
    , scaleFont viewWidth 20
    , paddingEach { top = 10, right = 0, bottom = 5, left = 10}
    ]

menu : Int -> List (Attribute msg)
menu viewWidth =
    [ pageWidth viewWidth
    , Element.paddingXY 0 0
    , fixedPosition
    , zIndex 9
    ]

officeTitle : Int -> List (Attribute msg)
officeTitle viewWidth =
    [ paddingEach { edges | top = 80 }
    , Element.centerX
    , Html.Attributes.id "officeTitle" |> Element.htmlAttribute
    ]

openingSentenceTitle : Int -> List (Attribute msg)
openingSentenceTitle viewWidth =
    [ paddingEach {edges | top = 10, bottom = 2, left = 10}
    , Font.italic
    , Font.color darkBlue
    , Font.variant Font.smallCaps
    , maxWidth viewWidth
    ]

openingSentence : Int -> List (Attribute msg)
openingSentence viewWidth =
    [ maxWidth viewWidth
    , paddingXY 10 0
    ]

pageNumber : Int -> List (Attribute msg)
pageNumber viewWidth =
    [ scaleFont viewWidth 14
    , Font.italic
    , Font.color darkRed
    , Font.alignLeft
    , hide
    ]

plain : Int -> List (Attribute msg)
plain viewWidth =
    [ Font.alignLeft
    , Element.paddingEach { top= 10, right = 10, bottom = 10, left= 10}
    , maxWidth viewWidth
    ]

prayer : Int -> List (Attribute msg)
prayer viewWidth =
    [ Element.paddingEach { top = 0, right = 0, bottom = 0, left = 10}
    ]

prayerList : Int -> List (Attribute msg)
prayerList width =
    [ padding 5
    , scaleWidth 350 width
    , Border.width 1
    , Border.rounded 6
    ]

psalmTitle : Int -> List (Attribute msg)
psalmTitle viewWidth =
    [ Font.variant Font.smallCaps
    , Font.color darkBlue
    , scaleFont viewWidth 16
    , paddingEach { edges | top = 0, bottom = 2, left = 10 }
    ]

quote : Int -> List (Attribute msg)
quote viewWidth =
    [ paddingXY 10 0
    , maxWidth viewWidth
    ]

radioRow : Int -> List (Attribute msg)
radioRow viewWidth =
    [ padding 10
    , spacing 10
    , maxWidth viewWidth
    ]

readingRef : String -> Int -> List (Attribute msg)
readingRef req viewWidth =
    if req == "req"
        then [ Font.color black, paddingXY 20 5 ]
        else [ Font.color darkBlue, paddingXY 20 5 ]

reference : Int -> List (Attribute msg)
reference viewWidth =
    [ scaleFont viewWidth 12
    , Font.italic
    , Font.color darkRed
    , paddingEach { top= 0, right= 10, bottom= 10, left= 10}
    , maxWidth viewWidth
    ]

rubric : Int -> List (Attribute msg)
rubric viewWidth =
    [ scaleFont viewWidth 12
    , Font.italic
    , Font.color darkRed
    , Font.alignLeft
    , paddingEach { edges | top = 5, bottom = 10, left = 10 }
    , spacing 0
    , maxWidth viewWidth
    ]

section : Int -> List (Attribute msg)
section viewWidth =
    [ Font.variant Font.smallCaps
    , paddingEach { edges | top = 10, bottom = 2, left = 10 }
    , Font.color darkBlue
    ]

versicals : Int -> List (Attribute msg)
versicals viewWidth =
    [ paddingXY 10 0]

versicalSpeaker : Int -> List (Attribute msg)
versicalSpeaker viewWidth =
    [ Font.italic
    , Font.alignLeft
    , Element.alignTop
    , Element.width( Element.px (scale viewWidth 90))
    , Element.padding 0
    ]

versicalSays : Int -> List (Attribute msg)
versicalSays viewWidth =
    [ Font.alignLeft
    , Element.alignTop
    , Element.padding 0
    , Element.width( Element.px (scale viewWidth (viewWidth - 110)) )
    ]

wordOfTheLord : Int -> List (Attribute msg)
wordOfTheLord viewWidth =
    [ paddingEach { edges | bottom = 30 }
    ]
