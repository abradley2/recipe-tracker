module Shared exposing (..)

import Browser.Navigation exposing (Key, load, pushUrl, replaceUrl)
import Fifo exposing (Fifo)
import Http
import Json.Decode as D exposing (Value)
import RemoteData exposing (RemoteData(..), WebData)
import Result.Extra as ResultX
import Shared.Errors as Errors
import Shared.Login as Login
import Url exposing (Url)


type Effect msg
    = BatchEffect (List (Effect msg))
    | CmdEffect (Cmd msg)
    | PushUrlEffect NavKey String
    | ReplaceUrlEffect NavKey String
    | LoadUrlEffect String
    | LoginUserEffect Login.LoginOptions


noEffect =
    CmdEffect Cmd.none


effectToCmd : (Msg -> msg) -> Effect msg -> Cmd msg
effectToCmd toMsg eff =
    case eff of
        BatchEffect effs ->
            Cmd.batch (List.map (effectToCmd toMsg) effs)

        CmdEffect cmd ->
            cmd

        LoadUrlEffect url ->
            load url

        PushUrlEffect (RealKey key) newUrl ->
            pushUrl key newUrl

        PushUrlEffect FakeKey _ ->
            Cmd.none

        ReplaceUrlEffect (RealKey key) newUrl ->
            replaceUrl key newUrl

        ReplaceUrlEffect FakeKey _ ->
            Cmd.none

        LoginUserEffect options ->
            Login.loginRequest options (LoginUserFinished options)
                |> Cmd.map toMsg


type Msg
    = LoginUser Login.LoginOptions
    | LoginUserFinished Login.LoginOptions (Result Http.Error String)
    | LogoutUser
    | ReportError String
    | HideError String
    | PushUrl Url
    | ReplaceUrl Url


type alias User =
    { token : Token
    , email : Email
    }


type alias Flags =
    { error : Maybe String }


decodeFlags : D.Decoder Flags
decodeFlags =
    D.map Flags
        (D.succeed Nothing)


type alias Model =
    { url : Url
    , key : NavKey
    , user : WebData User
    , flags : Flags
    , errors : Fifo String
    }


withUrl : Url -> Model -> Model
withUrl url model =
    { model | url = url }


init : Value -> Url -> NavKey -> ( Model, Effect msg )
init jsFlags url key =
    let
        flags =
            D.decodeValue decodeFlags jsFlags
                |> Result.mapError
                    (\err ->
                        { error = Just <| D.errorToString err
                        }
                    )
                |> ResultX.merge
    in
    ( { url = url
      , key = key
      , user = NotAsked
      , flags = flags
      , errors = Errors.init
      }
    , noEffect
    )


update : Msg -> Model -> ( Model, Effect msg )
update msg model =
    case msg of
        LoginUser options ->
            case model.user of
                Loading ->
                    ( model, noEffect )

                _ ->
                    ( { model | user = Loading }
                    , LoginUserEffect options
                    )

        LoginUserFinished options result ->
            case result of
                Result.Ok tokenString ->
                    ( { model
                        | user =
                            Success
                                { email = Email options.email
                                , token = Token tokenString
                                }
                      }
                    , ReplaceUrlEffect model.key "/recipes"
                    )

                Result.Err httpErr ->
                    ( { model
                        | errors = Errors.showError "Failed to login due to http error" model.errors
                        , user = Failure httpErr
                      }
                    , noEffect
                    )

        LogoutUser ->
            ( { model
                | user = NotAsked
              }
            , ReplaceUrlEffect model.key "/"
            )

        PushUrl url ->
            ( model
            , PushUrlEffect model.key (Url.toString url)
            )

        ReplaceUrl url ->
            ( model
            , ReplaceUrlEffect model.key (Url.toString url)
            )

        ReportError errText ->
            ( { model
                | errors = Errors.showError errText model.errors
              }
            , noEffect
            )

        HideError errText ->
            ( { model
                | errors = Errors.removeError errText model.errors
              }
            , noEffect
            )


type Email
    = Email String


type Token
    = Token String


type NavKey
    = RealKey Key
    | FakeKey
