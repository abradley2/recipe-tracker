module Shared.Errors exposing (..)

import Fifo exposing (Fifo)


init : Fifo String
init =
    Fifo.empty


showError : String -> Fifo String -> Fifo String
showError newError queue =
    let
        nextQueue =
            Fifo.insert newError queue
    in
    if List.length (Fifo.toList nextQueue) > 3 then
        nextQueue
            |> Fifo.remove
            |> Tuple.second

    else
        nextQueue


removeError : String -> Fifo String -> Fifo String
removeError errorText =
    Fifo.toList >> List.filter ((/=) errorText) >> Fifo.fromList
