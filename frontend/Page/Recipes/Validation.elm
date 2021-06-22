module Page.Recipes.Validation exposing (..)

import Parser exposing ((|.), (|=), DeadEnd, Parser, Problem(..), deadEndsToString, end, run, succeed, symbol, variable)
import Set


emailParser : Parser String
emailParser =
    succeed
        (\name domain -> name ++ "@" ++ domain)
        |= variable
            { start = Char.isAlphaNum
            , inner = \c -> c /= ' ' && c /= '@'
            , reserved = Set.fromList []
            }
        |. symbol "@"
        |= variable
            { start = Char.isAlphaNum
            , inner = \c -> c /= ' ' && c /= '@'
            , reserved = Set.fromList []
            }
        |. end


validEmail : String -> Result String ()
validEmail input =
    run
        emailParser
        input
        |> Result.mapError deadEndsToString
        |> Result.map (\_ -> ())
