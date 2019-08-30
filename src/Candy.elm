module Candy exposing (..)

import Html
import Html.Attributes
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


isEven : Int -> Bool
isEven n = 
    modBy 2 n == 0

stringNotEmpty : String -> Bool
stringNotEmpty str =
    not (String.isEmpty str)


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



renderPlainText : Int -> String -> (Element msg)
renderPlainText width str =
    paragraph
    ( Palette.plain width )
    [ text (str |> collapseWhiteSpace ) ]

renderSectionTitle : Int -> String -> (Element msg)
renderSectionTitle width str =
    paragraph
    (Palette.section width)
    [ text (str |> toTitleCase) ]

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
                paragraph [indent "3rem", Element.width (px (width - 70))] 
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

