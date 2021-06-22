module MainTests.Main exposing (..)

import Expect exposing (Expectation)
import Json.Decode exposing (Value)
import Json.Encode as E
import Main exposing (Page(..))
import Page.Landing as LandingPage
import Page.NotAllowed as NotAllowedPage
import Page.NotFound as NotFoundPage
import Page.Recipes as RecipesPage
import ProgramTest
    exposing
        ( SimulatedEffect
        , clickButton
        , createApplication
        , expectBrowserUrl
        , expectHttpRequestWasMade
        , expectModel
        , expectViewHas
        , fillIn
        , routeChange
        , simulateHttpOk
        , start
        , update
        , withBaseUrl
        , withSimulatedEffects
        )
import RemoteData exposing (RemoteData(..))
import Shared
import SimulatedEffect.Cmd as SimulateCmd
import SimulatedEffect.Http as SimulateHttp
import SimulatedEffect.Navigation as SimulateNavigation
import Test exposing (..)
import Test.Html.Selector as Selector


mainApp : ProgramTest.ProgramDefinition Value Main.Model Main.Msg (Shared.Effect Main.Msg)
mainApp =
    createApplication
        { init = \flags url () -> Main.init_ flags url Shared.FakeKey
        , view = Main.view
        , update = Main.update_
        , onUrlChange = Main.OnUrlChanged
        , onUrlRequest = Main.OnUrlRequested
        }


suite : Test
suite =
    describe "Main"
        [ landingPageSuite
        , additionalRoutesSuite
        ]


additionalRoutesSuite : Test
additionalRoutesSuite =
    describe "Protected Routes" <|
        [ test "We show the NotAllowed page when a user who is not logged in navigates to /recipes" <|
            \_ ->
                mainApp
                    |> withBaseUrl "https://test.com"
                    |> start (E.string "")
                    |> routeChange "/recipes"
                    |> expectViewHas
                        [ Selector.id NotAllowedPage.pageId
                        ]
        , test "We show the NotFound page when a user navigates to an unknown url" <|
            \_ ->
                mainApp
                    |> withBaseUrl "https://test.com"
                    |> start (E.string "")
                    |> routeChange "/a/fake/url/that/doesnt/exist"
                    |> expectViewHas
                        [ Selector.id NotFoundPage.pageId
                        ]
        ]


recipesPageSuite : Test
recipesPageSuite =
    describe "Recipes Page"
        [ test "When handle Msg's from the recipes page" <|
            \_ ->
                mainApp
                    |> withBaseUrl "https://test.com"
                    |> withSimulatedEffects (always SimulateCmd.none)
                    |> start (E.string "")
                    |> update
                        (Main.SharedMsg <|
                            Shared.LoginUserFinished
                                { email = ""
                                , password = ""
                                }
                                (Result.Ok "fake-token")
                        )
                    |> routeChange "/recipes"
                    |> update (Main.PageMsg <| Main.RecipesMsg <| RecipesPage.ListRecipesRequestFinished <| Result.Ok <| [])
                    |> expectModel
                        (\model ->
                            case model.page of
                                Main.RecipesPage _ page ->
                                    Expect.equal page.recipesList (Success [])

                                _ ->
                                    Expect.fail "Not rendering the proper page"
                        )
        ]


landingPageSuite : Test
landingPageSuite =
    describe "Landing Page"
        [ test "When the user logs in they are redirected to the /recipes page" <|
            \_ ->
                let
                    simulateEffects sharedEffect =
                        case sharedEffect of
                            Shared.LoginUserEffect options ->
                                SimulateHttp.post
                                    { url = "/login"
                                    , body = SimulateHttp.emptyBody
                                    , expect =
                                        SimulateHttp.expectString
                                            (Shared.LoginUserFinished options >> Main.SharedMsg)
                                    }

                            Shared.ReplaceUrlEffect _ url ->
                                SimulateNavigation.replaceUrl url

                            Shared.BatchEffect effects ->
                                SimulateCmd.batch <| List.map simulateEffects effects

                            _ ->
                                SimulateCmd.none
                in
                mainApp
                    |> withBaseUrl "http://test.com"
                    |> withSimulatedEffects simulateEffects
                    |> start (E.string "")
                    |> fillIn
                        LandingPage.emailInputId
                        LandingPage.emailInputLabel
                        "tony@example.com"
                    |> fillIn
                        LandingPage.passwordInputId
                        LandingPage.passwordInputLabel
                        "SecretPassword"
                    |> clickButton
                        LandingPage.submitButtonLabel
                    |> Expect.all
                        [ simulateHttpOk
                            "POST"
                            "/login"
                            """fake-token"""
                            >> expectBrowserUrl
                                (Expect.equal "http://test.com/recipes")
                        , expectHttpRequestWasMade
                            "POST"
                            "/login"
                        ]
        ]
