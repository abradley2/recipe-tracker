module Page.RecipeDetails exposing (..)

import Accessibility as H
import Html exposing (Html)
import Html.Lazy exposing (lazy)
import Html.Attributes as A
import Html.Events as E
import Http
import Page.RecipeDetails.Api as Api exposing (Ingredient, RecipeIngredient)
import RemoteData exposing (RemoteData(..), WebData)
import Shared exposing (Token)
import Tuple3


type Msg
    = RequestRecipeIngredientsFinished (Result Http.Error (List RecipeIngredient))
    | CreateIngredientFinished (Result Http.Error ())
    | AddIngredientClicked


type Effect
    = CmdEffect (Cmd Msg)
    | RequestRecipeIngredientsEffect Token Int
    | CreateRecipeIngredientEffect Token Ingredient Int


noEffect =
    CmdEffect Cmd.none


effectToCmd : Effect -> Cmd Msg
effectToCmd eff =
    case eff of
        CmdEffect cmd ->
            cmd

        RequestRecipeIngredientsEffect token recipeId ->
            Api.fetchRecipeIngredients
                token
                recipeId
                RequestRecipeIngredientsFinished

        CreateRecipeIngredientEffect token ingredient recipeId ->
            Api.addIngredient
                token
                ingredient
                recipeId
                CreateIngredientFinished


type alias Model =
    { recipeId : Int
    , recipeIngredients : WebData (List RecipeIngredient)
    }


init_ : Shared.Model -> Shared.User -> Int -> ( Model, Maybe Shared.Msg, Effect )
init_ shared user recipeId =
    ( { recipeId = recipeId
      , recipeIngredients = Loading
      }
    , Nothing
    , RequestRecipeIngredientsEffect user.token recipeId
    )


init : Shared.Model -> Shared.User -> Int -> ( Model, Maybe Shared.Msg, Cmd Msg )
init shared user =
    init_ shared user >> Tuple3.mapThird effectToCmd


update_ : Shared.Model -> Shared.User -> Msg -> Model -> ( Model, Maybe Shared.Msg, Effect )
update_ shared user msg model =
    case msg of
        RequestRecipeIngredientsFinished (Ok recipeIngredients) ->
            ( { model | recipeIngredients = Success recipeIngredients }
            , Nothing
            , noEffect
            )

        RequestRecipeIngredientsFinished (Err httpErr) ->
            ( { model | recipeIngredients = Failure httpErr }
            , Nothing
            , noEffect
            )

        AddIngredientClicked ->
            ( { model
                | recipeIngredients = Loading
              }
            , Nothing
            , CreateRecipeIngredientEffect user.token { name = "New Ingredient" } model.recipeId
            )

        CreateIngredientFinished (Ok _) ->
            ( model
            , Nothing
            , RequestRecipeIngredientsEffect user.token model.recipeId
            )

        CreateIngredientFinished (Err _) ->
            ( model
            , Just <| Shared.ReportError "Failed to create ingredient for recipe"
            , noEffect
            )


update : Shared.Model -> Shared.User -> Msg -> Model -> ( Model, Maybe Shared.Msg, Cmd Msg )
update shared user msg =
    update_ shared user msg >> Tuple3.mapThird effectToCmd


view : Shared.Model -> Shared.User -> Model -> Html Msg
view shared user model =
    H.div
        [ A.class "max-width-3 mx-auto p2"
        ]
        [ case model.recipeIngredients of
            Success recipeIngredients ->
                lazy ingredientListDisplay recipeIngredients

            Loading ->
                H.div [] [ H.text "Loading" ]

            Failure _ ->
                H.div
                    [ A.class "notification is-error"
                    , A.id ingredientLoadingErrorId
                    ]
                    []

            NotAsked ->
                H.text ""
        , H.button
            [ E.onClick AddIngredientClicked
            ]
            [ H.text "Add ingredient"
            ]
        ]


ingredientListDisplay : List RecipeIngredient -> Html Msg
ingredientListDisplay ingredients =
    H.ul
        [ A.id ingredientListDisplayId
        ]
        (List.map
            (.name >> H.text >> List.singleton >> H.li [])
            ingredients
        )


ingredientLoadingErrorId =
    "ingredient-loading-error"


ingredientListDisplayId =
    "ingredientListDisplayId"
