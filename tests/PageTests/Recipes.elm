module PageTests.Recipes exposing (..)

import Expect exposing (Expectation)
import Json.Decode as D
import Json.Encode as E
import Main exposing (Page(..))
import Page.Recipes as RecipesPage
import Page.Recipes.Api as Api
import ProgramTest
    exposing
        ( ProgramDefinition
        , SimulatedEffect
        , expectViewHas
        , simulateHttpOk
        , simulateHttpResponse
        , start
        , withSimulatedEffects
        )
import RemoteData exposing (RemoteData(..))
import Shared
import SimulatedEffect.Cmd as SimulatedCmd
import SimulatedEffect.Http as SimulatedHttp
import Test exposing (..)
import Test.Html.Selector as Selector
import Test.Http exposing (networkError)
import Url exposing (Url)
import Url.Builder exposing (crossOrigin)


baseUrl : String
baseUrl =
    "http://test.com"


suite : Test
suite =
    let
        maybeUrl =
            crossOrigin baseUrl [ "recipes" ] []
                |> Url.fromString
    in
    case Maybe.andThen recipesPage maybeUrl of
        Just programDef ->
            suite_ programDef

        Nothing ->
            test "Test suite failure" <| always (Expect.fail "Could not initialize program definition")


recipesPage : Url -> Maybe (ProgramDefinition () RecipesPage.Model RecipesPage.Msg RecipesPage.Effect)
recipesPage url =
    let
        ( shared, _ ) =
            Shared.init (E.object []) url Shared.FakeKey
                |> Tuple.first
                |> Shared.update
                    (Shared.LoginUserFinished
                        { email = "tony@example.com"
                        , password = "somepassword"
                        }
                     <|
                        Result.Ok "fake-token"
                    )
    in
    Maybe.map
        (\user ->
            ProgramTest.createElement
                { init =
                    \_ ->
                        RecipesPage.init_ shared user
                            |> (\( model, _, effect ) -> ( model, effect ))
                , update =
                    \msg model ->
                        RecipesPage.update_ shared user msg model
                            |> (\( nextModel, _, effect ) -> ( nextModel, effect ))
                , view = RecipesPage.view shared user
                }
        )
        (RemoteData.toMaybe shared.user)


suite_ : ProgramDefinition () RecipesPage.Model RecipesPage.Msg RecipesPage.Effect -> Test
suite_ programDef =
    describe "Recipes page tests"
        [ test "When the recipe page initializes it sends a request for all recipes" <|
            \_ ->
                let
                    simulateEffects : RecipesPage.Effect -> SimulatedEffect RecipesPage.Msg
                    simulateEffects eff =
                        case eff of
                            RecipesPage.ListAllRecipesEffect user ->
                                SimulatedHttp.get
                                    { url = "/api/recipes"
                                    , expect =
                                        SimulatedHttp.expectJson
                                            RecipesPage.ListRecipesRequestFinished
                                            (D.list Api.decodeRecipeListResult)
                                    }

                            RecipesPage.CmdEffect _ ->
                                SimulatedCmd.none
                in
                programDef
                    |> withSimulatedEffects simulateEffects
                    |> start ()
                    |> Expect.all
                        [ simulateHttpResponse
                            "GET"
                            "/api/recipes"
                            networkError
                            >> expectViewHas
                                [ Selector.id RecipesPage.failureRegionId
                                ]
                        , simulateHttpOk
                            "GET"
                            "/api/recipes"
                            recipesResponse
                            >> expectViewHas
                                [ Selector.id RecipesPage.successRegionId
                                ]
                        ]
        ]


recipesResponse =
    """[{"id":230,"name":"large eggs","createdAt":"2021-05-29T08:17:35.450737-04:00"},{"id":231,"name":"eggs","createdAt":"2021-05-29T08:17:45.821559-04:00"},{"id":232,"name":"another one","createdAt":"2021-05-29T17:54:54.674726-04:00"},{"id":233,"name":"I am a new recipe","createdAt":"2021-05-30T07:46:26.924492-04:00"}]"""
