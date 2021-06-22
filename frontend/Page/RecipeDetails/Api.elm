module Page.RecipeDetails.Api exposing (..)

import Http exposing (Error)
import Json.Decode as D exposing (Decoder)
import Json.Encode as E
import Shared exposing (Token(..))


type alias RecipeIngredient =
    { id : Int
    , ingredientId : Int
    , name : String
    }


type alias Ingredient =
    { name : String
    }


recipeIngredientDecoder : Decoder RecipeIngredient
recipeIngredientDecoder =
    D.map3
        RecipeIngredient
        (D.at [ "id" ] D.int)
        (D.at [ "ingredientId" ] D.int)
        (D.at [ "name" ] D.string)


fetchRecipeIngredients :
    Token
    -> Int
    -> (Result Error (List RecipeIngredient) -> msg)
    -> Cmd msg
fetchRecipeIngredients (Token token) recipeId toMsg =
    Http.request
        { url = "/api/recipe-details/" ++ String.fromInt recipeId
        , method = "GET"
        , timeout = Just 5000
        , headers =
            [ Http.header "Authorization" token
            ]
        , tracker = Nothing
        , body = Http.emptyBody
        , expect = Http.expectJson toMsg (D.list recipeIngredientDecoder)
        }


addIngredient :
    Token
    -> Ingredient
    -> Int
    -> (Result Error () -> msg)
    -> Cmd msg
addIngredient (Token token) ingredient recipeId toMsg =
    Http.request
        { url = "/api/ingredients"
        , method = "POST"
        , timeout = Just 5000
        , headers =
            [ Http.header "Authorization" token
            ]
        , tracker = Nothing
        , body =
            Http.jsonBody <|
                E.object
                    [ ( "recipeId", E.int recipeId )
                    , ( "name", E.string ingredient.name )
                    ]
        , expect = Http.expectWhatever toMsg
        }
