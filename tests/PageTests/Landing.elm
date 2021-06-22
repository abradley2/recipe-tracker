module PageTests.Landing exposing (..)

import Expect
import Json.Encode as E
import Page.Landing as LandingPage
import ProgramTest
    exposing
        ( SimulatedEffect
        , clickButton
        , expectLastEffect
        , expectModel
        , fillIn
        , start
        , withSimulatedEffects
        )
import Shared
import SimulatedEffect.Cmd as SimulateCmd
import SimulatedEffect.Task as SimulateTask
import Test exposing (..)
import Url exposing (Url)


landingPage : Url -> ProgramTest.ProgramDefinition a LandingPage.Model LandingPage.Msg LandingPage.Effect
landingPage url =
    let
        ( shared, _ ) =
            Shared.init (E.string "") url Shared.FakeKey
    in
    ProgramTest.createElement
        { init =
            \_ ->
                LandingPage.init_ shared
                    |> (\( model, _, effect ) -> ( model, effect ))
        , view = LandingPage.view shared
        , update =
            \msg model ->
                LandingPage.update_ shared msg model
                    |> (\( nextModel, _, effect ) -> ( nextModel, effect ))
        }


suite : Test
suite =
    case Url.fromString "https://test.com" of
        Just url ->
            suite_ url

        Nothing ->
            test "Failure to initialize landing page test" (always <| Expect.fail "Invalid url")


suite_ : Url -> Test
suite_ url =
    describe "Landing Page"
        [ test "The user can focus inputs where there are validation errors by clicking on those errors" <|
            \_ ->
                let
                    simulateEffects : LandingPage.Effect -> SimulatedEffect LandingPage.Msg
                    simulateEffects eff =
                        case eff of
                            LandingPage.FocusElementEffect elementId ->
                                SimulateTask.perform 
                                    LandingPage.ElementFocused 
                                    (SimulateTask.succeed <| Result.Ok elementId)

                            _ ->
                                SimulateCmd.none
                in
                landingPage url
                    |> withSimulatedEffects simulateEffects
                    |> start (E.string "")
                    |> fillIn
                        LandingPage.passwordInputId
                        LandingPage.passwordInputLabel
                        "short"
                    |> fillIn
                        LandingPage.emailInputId
                        LandingPage.emailInputLabel
                        "invalidemail"
                    |> clickButton
                        LandingPage.submitButtonLabel
                    |> Expect.all
                        [ clickButton "Invalid email"
                            >> expectModel
                                (.focusedElementResult >> Expect.equal (Just LandingPage.emailInputId))
                        , clickButton "Invalid password"
                            >> expectModel
                                (.focusedElementResult >> Expect.equal (Just LandingPage.passwordInputId))
                        ]
        ]
