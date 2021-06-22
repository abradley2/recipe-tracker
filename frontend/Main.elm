module Main exposing (..)

import Accessibility as H
import Browser exposing (Document, UrlRequest(..), application)
import Browser.Dom exposing (Error(..))
import Json.Decode exposing (Value)
import Layout exposing (layout)
import Page.Landing as LandingPage
import Page.NotAllowed as NotAllowedPage
import Page.NotFound as NotFoundPage
import Page.RecipeDetails as RecipeDetailsPage
import Page.Recipes as RecipesPage
import RemoteData exposing (RemoteData(..))
import Shared exposing (Effect)
import Url exposing (Url)
import Url.Parser exposing ((</>), int, map, oneOf, parse, s, string, top)


withUrl : Url -> Model -> ( Model, Effect Msg )
withUrl url model =
    parse
        (oneOf
            [ map
                (case RemoteData.toMaybe model.shared.user of
                    Just _ ->
                        ( model, Shared.ReplaceUrlEffect model.shared.key "/recipes" )

                    Nothing ->
                        LandingPage.init model.shared
                            |> withPageUpdate LandingPage LandingMsg model
                            |> withSharedMsg
                )
                top
            , map
                (case RemoteData.toMaybe model.shared.user of
                    Just user ->
                        RecipesPage.init model.shared user
                            |> withPageUpdate (RecipesPage user) RecipesMsg model
                            |> withSharedMsg

                    Nothing ->
                        ( { model | page = NotAllowedPage }, Shared.noEffect )
                )
                (s "recipes")
            , map
                (\recipeId ->
                    case RemoteData.toMaybe model.shared.user of
                        Just user ->
                            RecipeDetailsPage.init model.shared user recipeId
                                |> withPageUpdate (RecipeDetailsPage user) RecipeDetailsMsg model
                                |> withSharedMsg

                        Nothing ->
                            ( { model | page = NotAllowedPage }, Shared.noEffect )
                )
                (s "recipes" </> int)
            ]
        )
        url
        |> Maybe.withDefault
            ( { model | page = NotFoundPage }
            , Shared.noEffect
            )


withPageUpdate : (a -> Page) -> (msg -> PageMsg) -> Model -> ( a, b, Cmd msg ) -> ( Model, b, Effect Msg )
withPageUpdate mapPage mapMsg model ( pageModel, maybeSharedMsg, pageCmd ) =
    ( { model | page = mapPage pageModel }
    , maybeSharedMsg
    , Shared.CmdEffect <| Cmd.map (mapMsg >> PageMsg) pageCmd
    )


withSharedMsg : ( Model, Maybe Shared.Msg, Effect Msg ) -> ( Model, Effect Msg )
withSharedMsg ( model, maybeSharedMsg, effect ) =
    case maybeSharedMsg of
        Just sharedMsg ->
            let
                ( shared, sharedEffect ) =
                    Shared.update sharedMsg model.shared
            in
            ( { model | shared = shared }
            , Shared.BatchEffect [ sharedEffect, effect ]
            )

        Nothing ->
            ( model, effect )


type Msg
    = OnUrlRequested UrlRequest
    | OnUrlChanged Url
    | PageMsg PageMsg
    | SharedMsg Shared.Msg


type PageMsg
    = LandingMsg LandingPage.Msg
    | RecipesMsg RecipesPage.Msg
    | RecipeDetailsMsg RecipeDetailsPage.Msg


type Page
    = NotFoundPage
    | NotAllowedPage
    | LandingPage LandingPage.Model
    | RecipesPage Shared.User RecipesPage.Model
    | RecipeDetailsPage Shared.User RecipeDetailsPage.Model


type alias Model =
    { shared : Shared.Model
    , page : Page
    }


init_ : Value -> Url -> Shared.NavKey -> ( Model, Effect Msg )
init_ jsFlags url key =
    let
        ( shared, sharedCmd ) =
            Shared.init jsFlags url key

        ( model, pageCmd ) =
            withUrl url { shared = shared, page = NotFoundPage }
    in
    ( model
    , Shared.BatchEffect [ pageCmd, sharedCmd ]
    )


init : Value -> Url -> Shared.NavKey -> ( Model, Cmd Msg )
init jsFlags url =
    init_ jsFlags url >> Tuple.mapSecond (Shared.effectToCmd SharedMsg)


withPageMsg : PageMsg -> Model -> ( Model, Effect Msg )
withPageMsg pageMsg model =
    case ( pageMsg, model.page ) of
        ( LandingMsg landingMsg, LandingPage landingPage ) ->
            LandingPage.update model.shared landingMsg landingPage
                |> withPageUpdate LandingPage LandingMsg model
                |> withSharedMsg

        ( RecipesMsg recipesMsg, RecipesPage user recipesPage ) ->
            RecipesPage.update model.shared user recipesMsg recipesPage
                |> withPageUpdate (RecipesPage user) RecipesMsg model
                |> withSharedMsg

        ( RecipeDetailsMsg recipeDetailsMsg, RecipeDetailsPage user recipeDetailsPage ) ->
            RecipeDetailsPage.update model.shared user recipeDetailsMsg recipeDetailsPage
                |> withPageUpdate (RecipeDetailsPage user) RecipeDetailsMsg model
                |> withSharedMsg

        _ ->
            ( model, Shared.noEffect )


update_ : Msg -> Model -> ( Model, Effect Msg )
update_ msg model =
    case msg of
        OnUrlRequested (Internal url) ->
            withSharedMsg ( model, Just <| Shared.PushUrl url, Shared.noEffect )

        OnUrlRequested (External url) ->
            ( model
            , Shared.LoadUrlEffect url
            )

        OnUrlChanged url ->
            withUrl url model

        SharedMsg sharedMsg ->
            withSharedMsg ( model, Just sharedMsg, Shared.noEffect )

        PageMsg pageMsg ->
            withPageMsg pageMsg model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg =
    update_ msg >> Tuple.mapSecond (Shared.effectToCmd SharedMsg)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> Document Msg
view model =
    { title = ""
    , body =
        [ layout SharedMsg model.shared <|
            case model.page of
                LandingPage landingPage ->
                    LandingPage.view model.shared landingPage
                        |> H.map (LandingMsg >> PageMsg)

                RecipesPage user recipesPage ->
                    RecipesPage.view model.shared user recipesPage
                        |> H.map (RecipesMsg >> PageMsg)

                RecipeDetailsPage user recipeDetailsPage ->
                    RecipeDetailsPage.view model.shared user recipeDetailsPage
                        |> H.map (RecipeDetailsMsg >> PageMsg)

                NotFoundPage ->
                    NotFoundPage.view

                NotAllowedPage ->
                    NotAllowedPage.view
        ]
    }


main : Program Value Model Msg
main =
    application
        { init = \jsFlags url key -> init jsFlags url (Shared.RealKey key)
        , onUrlChange = OnUrlChanged
        , onUrlRequest = OnUrlRequested
        , subscriptions = subscriptions
        , update = update
        , view = view
        }
