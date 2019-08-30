module MyParsers exposing (..)

import Html
import Html.Attributes
import Element exposing (..)
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
import Candy exposing (..)

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

parserText : Parser String
parserText =
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
    |= parserText
    |. spaces

seasonalOpeningSentenceParser : Parser OpeningSentence
seasonalOpeningSentenceParser =
    succeed OpeningSentence
    |. spaces
    |= tag
    |= label
    |= ref
    |= parserText
    |. spaces

antiphonParser : Parser Antiphon
antiphonParser =
    succeed Antiphon
    |. spaces
    |= tag
    |= label
    |. spaces
    |= parserText

optionParser : Parser Models.Option
optionParser =
    succeed Option
    |. spaces
    |= selected
    |= tag
    |= label
    |= parserText

optionsHeaderParser : Parser OptionsHeader
optionsHeaderParser =
    succeed OptionsHeader
    |. spaces
    |= tag
    |. spaces
    |= label
    |. spaces


antiphon : Mark.Block (Model -> Element msg)
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
                                then none 
                                else 
                                    paragraph 
                                    [ indent "3rem"] 
                                    [ el 
                                        [ outdent "3rem"]
                                        none
                                    , el [] (text h)
                                    ]
                        t = lns 
                            |> List.tail 
                            |> Maybe.withDefault [""]
                            |> List.map (\l ->
                                if String.length l == 0 
                                then none
                                else el [spacing 10] (text l)

                            )
                    in
                    
                    textColumn 
                    ( Palette.antiphon model.width )
                    ([ el (Palette.antiphonTitle model.width)
                        ( text (if a.label == "BLANK" then "" else a.label |> toTitleCase) )
                    , line1
                    ] ++ t)
                    

                _  ->
                    paragraph [] [text "Antiphon Error"]

        )
        Mark.string

title : Mark.Block (Model -> Element msg)
title =
    Mark.block "Title"
        (\str model ->
            paragraph 
            [ Font.center
            , scaleFont model.width 32
            ]
            [ text str ]
        )
        Mark.string


season : Mark.Block (model -> Element msg)
season =
    Mark.block "Season"
        (\str model ->
            el [] (text ("season:" ++ str))
        )
        Mark.string
        
seasonTitle : Mark.Block (model -> Element msg)
seasonTitle =
    Mark.block "SeasonTitle"
        (\str model ->
            el [] (text ("seasonTitle:" ++ str))
        )
        Mark.string
        
pageNumber : Mark.Block (Model -> Element msg)
pageNumber =
    Mark.block "PageNumber"
        (\str model -> el (Palette.pageNumber model.width)
            (text str)
        )
        Mark.string

collectTitle : Mark.Block (Model -> Element msg)
collectTitle =
    Mark.block "CollectTitle"
        (\str model -> renderCollectTitle model.width str )
        Mark.string

section : Mark.Block (Model -> Element msg)
section =
    Mark.block "Section"
        (\str model -> renderSectionTitle model.width str )
        Mark.string

psalmTitle :Mark.Block (Model -> Element msg)
psalmTitle = 
    Mark.block "PsalmTitle"
        (\str model ->
            let
                lines = str |> String.lines
                line1 = lines |> List.head |> Maybe.withDefault "" |> toTitleCase
                line2 = lines |> getAt 1 |> Maybe.withDefault "" |> toTitleCase
            in
            paragraph
            ( Palette.psalmTitle model.width )
            [ el [] (text line1)
            , el [ Font.italic, paddingXY 20 0 ] (text line2)
            ]
        )
        Mark.string

reference : Mark.Block (Model -> Element msg)
reference =
    Mark.block "Ref"
        (\str model ->
            el
            (Palette.reference model.width)
            (text str)
        )
        Mark.string

plain : Mark.Block (Model -> Element msg)
plain =
    Mark.block "Plain"
        (\str model -> renderPlainText model.width str )
        Mark.string


versicals : Mark.Block (Model -> Element msg)
versicals =
    Mark.block "Versicals"
        (\str model ->
            column ( Palette.versicals model.width ) (listOfVersicals model str)
        )
        Mark.string

listOfVersicals : Model -> String -> List (Element msg)
listOfVersicals model str =
    str |> String.lines |> List.map (makeVersical model)

makeVersical : Model -> String -> Element msg
makeVersical model str =
    let
        word1 = str |> String.words |> List.head |> Maybe.withDefault ""
        (speaker, wordLen) = if word1 == "BLANK"
            then ("", (word1 |> String.length) + 1)
            else (word1, (word1 |> String.length) + 1)
        -- get the length of the first word plus it's trailing space
        says = str |> String.dropLeft wordLen
        el1 = column [scaleWidth model.width 90] [ text speaker ]
        el2 = column []
            [ paragraph [scaleWidth model.width 250] [text says ]
            ]
    in
        paragraph
        [ ]
        [ el1
        , el2
        ]
    

quote : Mark.Block (Model -> Element msg)
quote =
    Mark.block "Quote"
        (\str model ->
            paragraph
            ( Palette.quote model.width )
            [ text (str |> collapseWhiteSpace)]
        )
        Mark.string


rubric : Mark.Block (Model -> Element msg)
rubric = 
    Mark.block "Rubric"
        (\str model ->
            paragraph
            (Palette.rubric model.width)
            [ text (str |> collapseWhiteSpace) ]
        )
        Mark.string

prayer : Mark.Block (Model -> Element msg)
prayer =
    Mark.block "Prayer"
        (\str model -> renderPrayer model.width str )
        Mark.string


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

parseTheOptions : Maybe (List String) -> List (Result (List DeadEnd) Models.Option)
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

