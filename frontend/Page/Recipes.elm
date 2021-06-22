module Page.Recipes exposing (..)

import Accessibility as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Html.Lazy exposing (lazy)
import Http
import Page.Recipes.Api as Api exposing (listAllRecipesRequest)
import RemoteData exposing (RemoteData(..), WebData)
import Shared
import Tuple3
import Url.Builder exposing (absolute)


type Msg
    = ListRecipesRequestFinished (Result Http.Error (List Api.RecipeListResult))


type Effect
    = CmdEffect (Cmd Msg)
    | ListAllRecipesEffect Shared.User


noEffect =
    CmdEffect Cmd.none


effectToCmd : Effect -> Cmd Msg
effectToCmd eff =
    case eff of
        CmdEffect cmd ->
            cmd

        ListAllRecipesEffect user ->
            Api.listAllRecipesRequest user ListRecipesRequestFinished


type alias Model =
    { recipesList : WebData (List Api.RecipeListResult)
    }


init_ : Shared.Model -> Shared.User -> ( Model, Maybe Shared.Msg, Effect )
init_ shared user =
    ( { recipesList = Loading
      }
    , Nothing
    , ListAllRecipesEffect user
    )


init : Shared.Model -> Shared.User -> ( Model, Maybe Shared.Msg, Cmd Msg )
init shared =
    init_ shared >> Tuple3.mapThird effectToCmd


update_ : Shared.Model -> Shared.User -> Msg -> Model -> ( Model, Maybe Shared.Msg, Effect )
update_ shared user msg model =
    case msg of
        ListRecipesRequestFinished (Result.Ok recipes) ->
            ( { model | recipesList = Success recipes }
            , Nothing
            , noEffect
            )

        ListRecipesRequestFinished (Result.Err httpErr) ->
            ( { model | recipesList = Failure httpErr }
            , Just <| Shared.ReportError "Error fetching recipes list"
            , noEffect
            )


update : Shared.Model -> Shared.User -> Msg -> Model -> ( Model, Maybe Shared.Msg, Cmd Msg )
update shared user msg =
    update_ shared user msg >> Tuple3.mapThird effectToCmd


view : Shared.Model -> Shared.User -> Model -> Html Msg
view shared user model =
    H.div
        [ A.class "mx-auto p2 max-width-3"
        ]
        [ case model.recipesList of
            Success recipes ->
                lazy recipesList recipes

            Loading ->
                H.div
                    [ A.id loadingRegionId
                    ]
                    [ H.text "Loading" ]

            Failure _ ->
                H.div
                    [ A.id failureRegionId ]
                    [ H.text "Failed to get the stuff" ]

            NotAsked ->
                H.text ""
        ]


recipesList : List Api.RecipeListResult -> Html Msg
recipesList recipes =
    H.ul
        [ A.id successRegionId
        , A.class "menu-list mx-auto max-width-2"
        ]
        (List.map recipeItem recipes)


recipeItem : Api.RecipeListResult -> Html Msg
recipeItem item =
    H.li
        []
        [ H.a
            [ A.href <| absolute [ "recipes", String.fromInt item.id ] []
            ]
            [ H.text item.name
            ]
        ]


successRegionId =
    "success-region"


loadingRegionId =
    "loading-region"


failureRegionId =
    "failure-region"
