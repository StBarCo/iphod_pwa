module Palette exposing (..)

import Html.Attributes
import Element exposing (Attribute, rgb255, rgba255, paddingEach, padding, spacing, px, width)
import Element.Background as Background
import Element.Border as Border
import Element.Input as Input
import Element.Font as Font
import Models exposing(..)

darkRed = rgb255 100 0 0
darkBlue = rgb255 0 0 200
darkGrey = rgb255 80 80 80 
foggy = rgb255 250 250 250
litGreen = rgb255 16 104 16
litWhite = rgb255 255 226 12
litPurple = rgb255 109 8 168
litRed = rgb255 188 5 33

scale: Model -> Int -> Int
scale model n =
    ((toFloat model.width  / 375) * (toFloat n)) |> round

scalePx : Model -> Int -> Element.Length
scalePx model n =
    Element.px (scale model n)

scaleWidth : Model -> Int -> Attribute msg
scaleWidth model n =
    Element.width (scalePx model n)

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
            [ paddingEach { top = 0, right = 0, bottom = 0, left = 10}]
        _ ->
            -- let
            --     _ = Debug.log "UNRECOGNIZED CLASS NAME:" name
            -- in
            []
            

reference : Model -> List (Attribute msg)
reference model =
    [ scaleFont model 14
    , Font.italic
    , Font.color darkRed
    , Font.alignLeft
    --, paddingEach { top= 0, right= 10, bottom= 0, left= 0}
    ]

rubric : Model -> List (Attribute msg)
rubric model =        
    [ scaleFont model 14
    , Font.italic
    , Font.color darkRed
    , Font.alignLeft
    , paddingEach { top= 0, right= 0, bottom= 0, left= 0}
    , spacing 0
    ]
radioRow : Model -> List (Attribute msg)
radioRow model =
    [ padding 10
    , spacing 10
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

lessonTitle : Model -> List (Attribute msg)
lessonTitle model =
    [ Font.color darkBlue
    , Font.variant Font.smallCaps
    , scaleFont model 18
    , paddingEach { top = 10, right = 0, bottom = 5, left = 0}
    ]

antiphonTitle : Model -> List (Attribute msg)
antiphonTitle model =
    [ Font.center
    , Font.italic
    , Font.color darkBlue
    , Font.variant Font.smallCaps
    , outdent "3rem"
    ] 

pageNumber : Model -> List (Attribute msg)
pageNumber model =
    [ scaleFont model 14
    , Font.italic
    , Font.color darkRed
    , Font.alignLeft
    --, paddingEach { top= 0, right= 10, bottom= 10, left= 0}
    , hide
    ]

psalmTitle : Model -> List (Attribute msg)
psalmTitle model =
    [ Font.variant Font.smallCaps
    , Font.color darkBlue
    , scaleFont model 18
    ]

collectTitle : Model -> List (Attribute msg)
collectTitle model =
    [ Font.center
    , Font.variant Font.smallCaps
    , Font.color darkBlue
    , scaleFont model 18
    ]

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

openingSentenceTitle : Model -> List (Attribute msg)
openingSentenceTitle model =
    [ Font.center
    , Font.italic
    , Font.color darkBlue
    , Font.variant Font.smallCaps
    ] 

openingSentence : Model -> List (Attribute msg)
openingSentence model =
    [ Font.alignRight
    , Font.italic
    , Font.variant Font.smallCaps
    , Font.color darkRed
    , scaleFont model 18
    ]                                       

menu : Model -> List (Attribute msg)
menu model =
    [ Background.color litGreen
    , Font.color foggy
    , spacing 10
    , padding 10
    , pageWidth model
    ]

