module MyParsers exposing (..)

import Html exposing (..)
import Html.Attributes
import Element
import Element.Background as Background
import Element.Border as Border
import Element.Input as Input
import Element.Font as Font
import Mark
import Mark.Default
import Parser exposing ( .. )
import Regex exposing(replace, Regex)
import List.Extra exposing (getAt)
import String.Extra exposing (toTitleCase)
import Palette exposing(scaleFont, pageWidth, scale)
import Models exposing (..)

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
                                    [ Element.htmlAttribute <| Html.Attributes.style "margin-left" "3rem"] 
                                    [ Element.el 
                                        [ Element.htmlAttribute <| Html.Attributes.style "margin-left" "-3rem"]
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
                    [ pageWidth model ]
                    ([ Element.el (Palette.antiphonTitle model)
                        ( Element.text (if a.label == "BLANK" then "" else a.label |> toTitleCase) )
                    , line1
                    ] ++ t)
                    

                _  ->
                    Element.paragraph [] [Element.text "Antiphon Error"]

        )
        Mark.multiline


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
            Element.el (Palette.pageNumber model)
            (Element.text str)
        )
        Mark.string

collectTitle : Mark.Block (Model -> List (Element.Element msg))
            -> Mark.Block (Model -> Element.Element msg)
collectTitle thisText =
    Mark.block "CollectTitle"
        (\x model ->
            Element.paragraph (Palette.collectTitle model) (x model)
        )
        thisText

section : Mark.Block (model -> Element.Element msg)
section =
    Mark.block "Section"
        (\str model -> 
            Element.paragraph
            [ Font.alignLeft
            , Font.variant Font.smallCaps
            ]
            [ Element.text (str |> toTitleCase) ]
        )
        Mark.string

psalmTitle :Mark.Block (model -> Element.Element msg)
psalmTitle = 
    Mark.block "PsalmTitle"
        (\str model ->
            let
                lines = str |> String.lines
                line1 = lines |> List.head |> Maybe.withDefault "" |> toTitleCase
                line2 = lines |> getAt 1 |> Maybe.withDefault "" |> toTitleCase
            in
            Element.column
            [ Element.centerX
            ]
            [ Element.el [] (Element.text line1)
            , Element.el [ Font.italic ] (Element.text line2)
            ]
        )
        Mark.multiline

reference : Mark.Block (Model -> Element.Element msg)
reference =
    Mark.block "Ref"
        (\str model ->
            Element.el
            (Palette.reference model)
            (Element.text str)
        )
        Mark.string

plain : Mark.Block (model -> Element.Element msg)
plain =
    Mark.block "Plain"
        (\str model ->
            Element.paragraph
            [ Font.alignLeft
            , Element.paddingEach { top= 0, right = 10, bottom = 0, left= 0}
            ]
            [ Element.text (str |> collapseWhiteSpace)]
        )
        Mark.multiline


versicals : Mark.Block (Model -> Element.Element msg)
versicals =
    Mark.block "Versicals"
        (\str model ->
            Element.column [] (listOfVersicals model str)
        )
        Mark.multiline

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
        el1 = Element.el (Palette.versicalSpeaker model) ( Element.text speaker )
        el2 = Element.paragraph (Palette.versicalSays model)
            [ Element.text says ]
    in
    Element.wrappedRow 
        [ Element.width Element.fill
        , Element.spacing 10 
        , Element.paddingXY 0 2
        ] 
        [ el1, el2 ]
    

quote : Mark.Block (model -> Element.Element msg)
quote =
    Mark.block "Quote"
        (\str model ->
            Element.paragraph
            [ Font.alignLeft
            , Element.paddingEach { top= 0, right = 10, bottom = 0, left= 0}
            ]
            [ Element.text (str |> collapseWhiteSpace)]
        )
        Mark.multiline


rubric : Mark.Block (Model -> Element.Element msg)
rubric = 
    Mark.block "Rubric"
        (\str model ->
            Element.paragraph
            (Palette.rubric model)
            [ Element.text (str |> collapseWhiteSpace) ]
        )
        Mark.multiline

mLeft : Element.Attribute msg
mLeft = 
    Html.Attributes.style "margin-left" "3rem" |> Element.htmlAttribute

minusLeft : Element.Attribute msg
minusLeft =
    Html.Attributes.style "margin-left" "-3rem" |> Element.htmlAttribute

prayer : Mark.Block (Model -> Element.Element msg)
prayer =
    Mark.block "Prayer"
        (\str model -> 
            let
                lns = str 
                    |> String.split "\n" 
                    |> List.map (\l -> 
                        Element.paragraph [mLeft, Element.width (Element.px (model.width - 50))] 
                        [ Element.el [minusLeft] Element.none
                        , Element.text (String.trimRight l)
                        ] 
                    )
            in
            
            Element.column
            [ Font.alignLeft
            , Element.paddingEach { top = 0, right = 0, bottom = 0, left = 0} 
            ]
            lns
        )
        Mark.multiline

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

