module MyParsers exposing (..)

import Html exposing (..)
import Html.Attributes
import Element
import Element.Background as Background
import Element.Border as Border
import Element.Input as Input
import Element.Font as Font
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

restOfLine : String -> Parser String
restOfLine str =
        succeed identity
        |. keyword str
        |. spaces
        |= (getChompedString <| chompUntil "\n") 
        |. spaces

selected : Parser String
selected =
    succeed identity
    |. keyword "selected:"
    |. spaces
    |= (getChompedString <| chompWhile (\c -> Char.isAlphaNum c || c == '_'))
    |. spaces

tag : Parser String
tag =
    succeed identity
    |. keyword "tag:"
    |. spaces
    |= (getChompedString <| chompWhile (\c -> Char.isAlphaNum c || c == '_'))
    |. spaces

label : Parser String
label =
    "label:" |> restOfLine
    
ref : Parser String
ref =
    "ref:" |> restOfLine

text : Parser String
text =
    succeed identity 
    |. keyword "text:"
    |. spaces
    |= (getChompedString <| chompUntil "\n--")
    |. spaces

openingSentenceParser : Parser OpeningSentence
openingSentenceParser =
    succeed OpeningSentence
    |. Parser.spaces
    |= tag
    |= label
    |= ref
    |= text
    |. spaces

seasonalOpeningSentenceParser : Parser OpeningSentence
seasonalOpeningSentenceParser =
    succeed OpeningSentence
    |. spaces
    |= tag
    |= label
    |= ref
    |= text
    |. spaces

antiphonParser : Parser Antiphon
antiphonParser =
    succeed Antiphon
    |. spaces
    |= tag
    |= label
    |. spaces
    |= text

optionParser : Parser Option
optionParser =
    succeed Option
    |. spaces
    |= selected
    |= tag
    |= label
    |= text

optionsHeaderParser : Parser OptionsHeader
optionsHeaderParser =
    succeed OptionsHeader
    |. spaces
    |= tag
    |. spaces
    |= label
    |. spaces


antiphon : Mark.Block (Model -> Element.Element msg)
antiphon =
    Mark.block "Antiphon"
        (\parseThis model ->
            let
                okParsed = Parser.run antiphonParser parseThis
            in
            case okParsed of
                Ok a ->
                    let
                        lns = a.text |> String.split "\n"
                        h = lns |> List.head |> Maybe.withDefault ""
                        line1 = if String.length h == 0 
                                then Element.none 
                                else 
                                    Element.paragraph 
                                    [ indent "3rem"] 
                                    [ Element.el 
                                        [ outdent "3rem"]
                                        Element.none
                                    , Element.el [] (Element.text h)
                                    ]
                        t = lns 
                            |> List.tail 
                            |> Maybe.withDefault [""]
                            |> List.map (\l ->
                                if String.length l == 0 
                                then Element.none
                                else Element.el [Element.spacing 10] (Element.text l)

                            )
                    in
                    
                    Element.textColumn 
                    ( Palette.antiphon model.width )
                    ([ Element.el (Palette.antiphonTitle model.width)
                        ( Element.text (if a.label == "BLANK" then "" else a.label |> toTitleCase) )
                    , line1
                    ] ++ t)
                    

                _  ->
                    Element.paragraph [] [Element.text "Antiphon Error"]

        )
        Mark.string

title : Mark.Block (Model -> Element.Element msg)
title =
    Mark.block "Title"
        (\str model ->
            Element.paragraph 
            [ Font.center
            , scaleFont model.width 32
            ]
            [ Element.text str ]
        )
        Mark.string


season : Mark.Block (model -> Element.Element msg)
season =
    Mark.block "Season"
        (\str model ->
            Element.el [] (Element.text ("season:" ++ str))
        )
        Mark.string
        
seasonTitle : Mark.Block (model -> Element.Element msg)
seasonTitle =
    Mark.block "SeasonTitle"
        (\str model ->
            Element.el [] (Element.text ("seasonTitle:" ++ str))
        )
        Mark.string
        
pageNumber : Mark.Block (Model -> Element.Element msg)
pageNumber =
    Mark.block "PageNumber"
        (\str model ->
            Element.el (Palette.pageNumber model.width)
            (Element.text str)
        )
        Mark.string

elsWithItalics : String -> List (Element.Element msg)
elsWithItalics str =
    str 
    |> String.split "/"
    |> List.filter stringNotEmpty
    |> List.indexedMap (\i txt ->  
        if isEven i
        then 
            Element.el [] (Element.text txt)
        else
            Element.el [ Font.italic ] (Element.text txt)
    )
    

collectTitle : Mark.Block (Model -> Element.Element msg)
collectTitle =
    Mark.block "CollectTitle"
        (\str model ->
            Element.paragraph (Palette.collectTitle model.width) ( elsWithItalics (str |> toTitleCase) )
        )
        Mark.string

section : Mark.Block (Model -> Element.Element msg)
section =
    Mark.block "Section"
        (\str model -> 
            Element.paragraph
            ( Palette.section model.width )
            [ Element.text (str |> toTitleCase) ]
        )
        Mark.string

psalmTitle :Mark.Block (Model -> Element.Element msg)
psalmTitle = 
    Mark.block "PsalmTitle"
        (\str model ->
            let
                lines = str |> String.lines
                line1 = lines |> List.head |> Maybe.withDefault "" |> toTitleCase
                line2 = lines |> getAt 1 |> Maybe.withDefault "" |> toTitleCase
            in
            Element.paragraph
            ( Palette.psalmTitle model.width )
            [ Element.el [] (Element.text line1)
            , Element.el [ Font.italic, Element.paddingXY 20 0 ] (Element.text line2)
            ]
        )
        Mark.string

reference : Mark.Block (Model -> Element.Element msg)
reference =
    Mark.block "Ref"
        (\str model ->
            Element.el
            (Palette.reference model.width)
            (Element.text str)
        )
        Mark.string

plain : Mark.Block (Model -> Element.Element msg)
plain =
    Mark.block "Plain"
        (\str model ->
            Element.paragraph
            ( Palette.plain model.width )
            [ Element.text (str |> collapseWhiteSpace)]
        )
        Mark.string


versicals : Mark.Block (Model -> Element.Element msg)
versicals =
    Mark.block "Versicals"
        (\str model ->
            Element.column ( Palette.versicals model.width ) (listOfVersicals model str)
        )
        Mark.string

listOfVersicals : Model -> String -> List (Element.Element msg)
listOfVersicals model str =
    str |> String.lines |> List.map (makeVersical model)

makeVersical : Model -> String -> Element.Element msg
makeVersical model str =
    let
        word1 = str |> String.words |> List.head |> Maybe.withDefault ""
        (speaker, wordLen) = if word1 == "BLANK"
            then ("", (word1 |> String.length) + 1)
            else (word1, (word1 |> String.length) + 1)
        -- get the length of the first word plus it's trailing space
        says = str |> String.dropLeft wordLen
        el1 = Element.column [scaleWidth model.width 90] [ Element.text speaker ]
        el2 = Element.column []
            [ Element.paragraph [scaleWidth model.width 250] [Element.text says ]
            ]
    in
        Element.paragraph
        [ ]
        [ el1
        , el2
        ]
    

quote : Mark.Block (Model -> Element.Element msg)
quote =
    Mark.block "Quote"
        (\str model ->
            Element.paragraph
            ( Palette.quote model.width )
            [ Element.text (str |> collapseWhiteSpace)]
        )
        Mark.string


rubric : Mark.Block (Model -> Element.Element msg)
rubric = 
    Mark.block "Rubric"
        (\str model ->
            Element.paragraph
            (Palette.rubric model.width)
            [ Element.text (str |> collapseWhiteSpace) ]
        )
        Mark.string

prayer : Mark.Block (Model -> Element.Element msg)
prayer =
    Mark.block "Prayer"
        (\str model -> 
            let
                lns = str 
                    |> String.split "\n" 
                    |> List.map (\l -> 
                        Element.paragraph [indent "3rem", Element.width (Element.px (model.width - 70))] 
                        [ Element.el [outdent "3rem"] Element.none
                        , Element.text (String.trimRight l)
                        ] 
                    )
            in
            
            Element.column (Palette.prayer model.width) lns
        )
        Mark.string

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


stringToOptions : String -> Options
stringToOptions s =
    let
        splits = s |> String.split "--"
        (t, l) = case (splits |> List.head |> parseOptionsHeader) of
            Ok o -> 
                let
                    thisLabel = if o.label == "BLANK" then "" else o.label
                in
                (o.tag, thisLabel)
            
            _ -> ("", "Error Parsing Options Header")
        
        opts = (splits |> List.tail |> parseTheOptions)
                |> List.map (\okOp -> case okOp of
                    Ok o -> o
                    _ -> initOption 
                )
    in
    { tag = t, label = l, options = opts}


parseOptionsHeader : Maybe String ->  Result (List DeadEnd) OptionsHeader
parseOptionsHeader maybeStr =
    -- should be a string that looks like...
    -- "tag: value\nlabel: value"
    case maybeStr of
        Just s ->   Parser.run optionsHeaderParser s

        Nothing -> Parser.run optionsHeaderParser "" -- should throw the appropriate error

parseTheOptions : Maybe (List String) -> List (Result (List DeadEnd) Option)
parseTheOptions maybeList =
    case maybeList of
        Just l ->
            l 
            |> replaceSplitter
            |> List.map (\o -> Parser.run optionParser o)  
            
        Nothing -> [Parser.run optionParser ""] -- should throw the appropriate error

replaceSplitter : List String -> List String
replaceSplitter list =
    list
    |> List.take ( (list |> List.length) - 1 )
    |> List.map (\o -> o ++ "--")

