module Page.Recipes.Api exposing (..)

import Http exposing (Error(..))
import Json.Decode as D
import Shared


type alias RecipeListResult =
    { id : Int
    , name : String
    }


decodeRecipeListResult : D.Decoder RecipeListResult
decodeRecipeListResult =
    D.map2
        RecipeListResult
        (D.at [ "id" ] D.int)
        (D.at [ "name" ] D.string)


listAllRecipesRequest : Shared.User -> (Result Error (List RecipeListResult) -> msg) -> Cmd msg
listAllRecipesRequest user toMsg =
    let
        token =
            case user.token of
                Shared.Token val ->
                    val
    in
    Http.request
        { url = "/api/recipes"
        , method = "GET"
        , expect =
            Http.expectJson
                toMsg
                (D.list decodeRecipeListResult)
        , headers =
            [ Http.header "Authorization" token
            ]
        , timeout = Nothing
        , body = Http.emptyBody
        , tracker = Nothing
        }
