module Shared.Login exposing (..)

import Http exposing (Error(..))
import Process
import Task


type alias LoginOptions =
    { email : String
    , password : String
    }


loginRequest : LoginOptions -> (Result Error String -> msg) -> Cmd msg
loginRequest options toMsg =
    Process.sleep 200
        |> Task.andThen (\_ -> Task.succeed <| Result.Ok "fake-token")
        |> Task.perform toMsg
