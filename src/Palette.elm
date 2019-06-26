module Palette exposing (..)

import Html.Attributes
import Element exposing (Attribute, rgb255, rgba255, paddingEach, padding, paddingXY, spacing, px, width, moveLeft)
import Element.Background as Background
import Element.Border as Border
import Element.Input as Input
import Element.Font as Font
import Models exposing(..)

darkRed = rgb255 100 0 0
darkBlue = rgb255 13 44 117
darkGrey = rgb255 80 80 80 
foggy = rgb255 250 250 250
litGreen = rgb255 16 104 16
litWhite = rgb255 255 226 12
litPurple = rgb255 109 8 168
litRed = rgb255 188 5 33

edges : { top: Int, right: Int, bottom: Int, left: Int }
edges = { top = 0, right = 0, bottom = 0, left = 0 }

fixedPosition : Element.Attribute msg
fixedPosition =
    Html.Attributes.style "position" "fixed" |> Element.htmlAttribute

zIndex : Int -> Element.Attribute msg
zIndex z =
    Html.Attributes.style "z-index" (z |> String.fromInt) |> Element.htmlAttribute

scale: Model -> Int -> Int
scale model n =
    if model.width > 700 
    then
        ((toFloat model.width  / 700) * (toFloat n)) |> round
    else
        ((toFloat model.width  / 375) * (toFloat n)) |> round

scalePx : Model -> Int -> Element.Length
scalePx model n =
    Element.px (scale model n)

scaleWidth : Model -> Int -> Attribute msg
scaleWidth model n =
    Element.width (scalePx model n)

--maxWidth : Model -> Attribute msg
--maxWidth model =
--    scaleWidth model (model.width - 25)

adjustWidth : Model -> Int -> Attribute msg
adjustWidth model adj =
    width (px (model.width + adj) )

maxWidth : Model -> Attribute msg
maxWidth model =
    width (px (model.width - 25))

scaleFont : Model -> Int -> Attribute msg
scaleFont model n = 
    (scale model n) |> Font.size

pageWidth : Model -> Attribute msg
pageWidth model = 
    Element.width (px model.width)

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

antiphon : Model -> List (Attribute msg)
antiphon model =
    [ maxWidth model 
    , paddingEach { edges | top = 10, left = 10 }
    ]
            
antiphonTitle : Model -> List (Attribute msg)
antiphonTitle model =
    [ paddingEach { edges | top = 10 }
    , Font.italic
    , Font.color darkBlue
    , Font.variant Font.smallCaps
    , outdent "3rem"
    ] 

button : Model -> List (Attribute msg)
button model =
    [ Border.color darkRed
    , Border.rounded 5
    , Border.width 5
    , padding 10
    , spacing 10
    , Background.color darkRed
    , Font.color foggy
    ]

collectTitle : Model -> List (Attribute msg)
collectTitle model =
    [ paddingEach { edges | top = 10, left = 10, bottom = 2 }
    , Font.variant Font.smallCaps
    , Font.color darkBlue
    , scaleFont model 16
    , maxWidth model
    ]

lesson : Model -> List (Attribute msg)
lesson model =
    [ paddingXY 10 0 ]

lessonTitle : Model -> List (Attribute msg)
lessonTitle model =
    [ Font.color darkBlue
    , Font.variant Font.smallCaps
    , scaleFont model 16
    , paddingEach { top = 10, right = 0, bottom = 5, left = 10}
    ]

menu : Model -> List (Attribute msg)
menu model =
    [ pageWidth model
    , Element.paddingXY 0 0
    , fixedPosition
    , zIndex 9
    ]

officeTitle : Model -> List (Attribute msg)
officeTitle model = 
    [ paddingEach { edges | top = 65 }
    , Element.centerX
    ]

openingSentenceTitle : Model -> List (Attribute msg)
openingSentenceTitle model =
    [ paddingEach {edges | top = 10, bottom = 2, left = 10}
    , Font.italic
    , Font.color darkBlue
    , Font.variant Font.smallCaps
    , maxWidth model
    ] 

openingSentence : Model -> List (Attribute msg)
openingSentence model =
    [ maxWidth model
    , paddingXY 10 0
    ]                                       

pageNumber : Model -> List (Attribute msg)
pageNumber model =
    [ scaleFont model 14
    , Font.italic
    , Font.color darkRed
    , Font.alignLeft
    , hide
    ]

plain : Model -> List (Attribute msg)
plain model =
    [ Font.alignLeft
    , Element.paddingEach { top= 10, right = 10, bottom = 10, left= 10}
    , maxWidth model
    ]

prayer : Model -> List (Attribute msg)
prayer model =
    [ Element.paddingEach { top = 0, right = 0, bottom = 0, left = 10}
    ]

psalmTitle : Model -> List (Attribute msg)
psalmTitle model =
    [ Font.variant Font.smallCaps
    , Font.color darkBlue
    , scaleFont model 16
    , paddingEach { edges | top = 0, bottom = 2, left = 10 }
    ]

quote : Model -> List (Attribute msg)
quote model =
    [ paddingXY 10 0
    , maxWidth model
    ]

radioRow : Model -> List (Attribute msg)
radioRow model =
    [ padding 10
    , spacing 10
    , maxWidth model
    ]

reference : Model -> List (Attribute msg)
reference model =
    [ scaleFont model 12
    , Font.italic
    , Font.color darkRed
    , paddingEach { top= 0, right= 10, bottom= 10, left= 10}
    , maxWidth model
    ]

rubric : Model -> List (Attribute msg)
rubric model =        
    [ scaleFont model 12
    , Font.italic
    , Font.color darkRed
    , Font.alignLeft
    , paddingEach { edges | top = 5, bottom = 10, left = 10 }
    , spacing 0
    , maxWidth model
    ]

section : Model -> List (Attribute msg)
section model =
    [ Font.variant Font.smallCaps
    , paddingEach { edges | top = 10, bottom = 2, left = 10 }
    , Font.color darkBlue
    ]

versicals : Model -> List (Attribute msg)
versicals model =
    [ paddingXY 10 0]

versicalSpeaker : Model -> List (Attribute msg)
versicalSpeaker model =
    [ Font.italic
    , Font.alignLeft
    , Element.alignTop
    , Element.width( Element.px (scale model 90))
    , Element.padding 0
    ] 

versicalSays : Model -> List (Attribute msg)
versicalSays model =
    [ Font.alignLeft
    , Element.alignTop
    , Element.padding 0
    , Element.width( Element.px (scale model (model.width - 110)) )
    ] 
