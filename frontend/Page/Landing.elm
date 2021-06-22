module Page.Landing exposing (..)

import Accessibility as H exposing (Html)
import Accessibility.Aria exposing (errorMessage)
import Accessibility.Widget exposing (hidden, invalid)
import Browser.Dom
import Html.Attributes as A
import Html.Events as E
import Http exposing (Error)
import Maybe.Extra as MaybeX
import Page.Recipes.Validation as Validation
import RemoteData exposing (RemoteData(..), isLoading)
import Result.Extra as ResultX
import Shared
import Shared.Login exposing (LoginOptions)
import Task
import Tuple3
import View.Icons as Icons


type Effect
    = CmdEffect (Cmd Msg)
    | FocusElementEffect String


noEffect =
    CmdEffect Cmd.none


effectToCmd : Effect -> Cmd Msg
effectToCmd eff =
    case eff of
        CmdEffect cmd ->
            cmd

        FocusElementEffect id ->
            Task.attempt ElementFocused <| (Task.map (always id) <| Browser.Dom.focus id)


type Msg
    = EmailChanged String
    | PasswordChanged String
    | ErrorItemClicked String
    | SubmitClicked
    | ElementFocused (Result Browser.Dom.Error String)


type alias Model =
    { email : String
    , emailError : Maybe String
    , password : String
    , passwordError : Maybe String
    , focusedElementResult : Maybe String
    }


init_ : Shared.Model -> ( Model, Maybe Shared.Msg, Effect )
init_ shared =
    ( { email = ""
      , emailError = Nothing
      , password = ""
      , passwordError = Nothing
      , focusedElementResult = Nothing
      }
    , Nothing
    , noEffect
    )


init : Shared.Model -> ( Model, Maybe Shared.Msg, Cmd Msg )
init shared =
    init_ shared |> Tuple3.mapThird effectToCmd


update_ : Shared.Model -> Msg -> Model -> ( Model, Maybe Shared.Msg, Effect )
update_ shared msg model =
    case msg of
        EmailChanged email ->
            ( { model
                | email = email
              }
            , Nothing
            , noEffect
            )

        PasswordChanged password ->
            ( { model
                | password = password
              }
            , Nothing
            , noEffect
            )

        SubmitClicked ->
            let
                ( maybeLoginOptions, nextModel ) =
                    validateLogin model
            in
            ( nextModel
            , Maybe.map Shared.LoginUser maybeLoginOptions
            , noEffect
            )

        ErrorItemClicked id ->
            ( model
            , Nothing
            , FocusElementEffect id
            )

        ElementFocused result ->
            ( { model | focusedElementResult = Result.toMaybe result }
            , Nothing
            , noEffect
            )


validateLogin : Model -> ( Maybe LoginOptions, Model )
validateLogin model =
    let
        validEmail =
            Validation.validEmail model.email
                |> Result.map (always model.email)
                |> Result.mapError (always "Invalid email")

        validPassword =
            if String.length model.password > 5 then
                Result.Ok model.password

            else
                Result.Err "Invalid password"
    in
    ( Maybe.map2
        LoginOptions
        (Result.toMaybe validEmail)
        (Result.toMaybe validPassword)
    , { model
        | emailError = ResultX.error validEmail
        , passwordError = ResultX.error validPassword
      }
    )


update : Shared.Model -> Msg -> Model -> ( Model, Maybe Shared.Msg, Cmd Msg )
update shared msg =
    update_ shared msg >> Tuple3.mapThird effectToCmd


view : Shared.Model -> Model -> Html Msg
view shared model =
    H.div
        [ A.class "p2"
        ]
        [ H.div
            [ A.class "max-width-1 mx-auto"
            ]
            [ H.div
                [ A.class "field px2"
                ]
                [ H.label
                    [ A.class "label"
                    , A.for emailInputId
                    ]
                    [ H.text emailInputLabel
                    ]
                , H.div
                    [ A.class "control has-icons-left" ]
                    [ H.inputText model.email
                        (withErrorAttribute model.emailError
                            [ A.class "input"
                            , A.id emailInputId
                            , A.placeholder "username@example.com"
                            , A.type_ "email"
                            , E.onInput EmailChanged
                            ]
                        )
                    , H.i
                        [ A.class "icon is-left has-text-grey" ]
                        [ Icons.email
                            { width = "1.5rem"
                            , height = "1.5rem"
                            }
                        ]
                    ]
                ]
            , H.div
                [ A.class "field px2"
                ]
                [ H.label
                    [ A.class "label"
                    , A.for passwordInputId
                    ]
                    [ H.text passwordInputLabel
                    ]
                , H.div
                    [ A.class "control" ]
                    [ H.inputText model.password
                        (withErrorAttribute model.passwordError
                            [ A.class "input"
                            , A.type_ "password"
                            , A.id passwordInputId
                            , E.onInput PasswordChanged
                            ]
                        )
                    ]
                ]
            , errorDisplay model
            , H.div
                [ A.class "center px2" ]
                [ H.button
                    [ A.class "button"
                    , A.id submitButtonId
                    , E.onClick SubmitClicked
                    ]
                    [ if isLoading shared.user then
                        Icons.syncing { width = "1.5rem", height = "1.5rem" }

                      else
                        H.text ""
                    , H.text submitButtonLabel
                    ]
                ]
            ]
        ]


withErrorAttribute : Maybe a -> List (H.Attribute msg) -> List (H.Attribute msg)
withErrorAttribute err attrs =
    case err of
        Just _ ->
            attrs
                ++ [ invalid True
                   , errorMessage errorDisplayId
                   ]

        Nothing ->
            attrs
                ++ [ invalid False
                   ]


errorDisplay : Model -> Html Msg
errorDisplay model =
    let
        errorFields =
            [ ( model.emailError, emailInputId )
            , ( model.passwordError, passwordInputId )
            ]
                |> List.foldr
                    (\( maybeError, inputId ) acc ->
                        case maybeError of
                            Just err ->
                                ( err, inputId ) :: acc

                            Nothing ->
                                acc
                    )
                    []

        hasErrors =
            List.length errorFields /= 0
    in
    H.div
        [ A.id errorDisplayId
        , hidden (not hasErrors)
        , A.classList
            [ ( "notification is-warning", hasErrors )
            , ( "hidden", not hasErrors )
            ]
        ]
        [ List.intersperse
            (H.br [])
            (List.map
                (\( text, inputId ) ->
                    H.button
                        [ E.onClick <| ErrorItemClicked inputId
                        , A.class "button is-text"
                        ]
                        [ H.text text ]
                )
                errorFields
            )
            |> H.p []
        ]


subscriptions : Shared.Model -> Model -> Sub Msg
subscriptions shared model =
    Sub.none


emailInputId =
    "email"


emailInputLabel =
    "Email"


passwordInputId =
    "password"


passwordInputLabel =
    "Password"


submitButtonId =
    "submit"


submitButtonLabel =
    "Submit"


errorDisplayId =
    "form-errors"


errorButtonId : String -> String
errorButtonId inputId =
    "error-button-" ++ inputId
