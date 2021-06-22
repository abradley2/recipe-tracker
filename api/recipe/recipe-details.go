package recipe

import (
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"

	"github.com/abradley2/recipe-tracker/api"
)

func Handler(w http.ResponseWriter, r *http.Request) {
	l := log.New(os.Stderr, "recipe-details.Handler: ", log.LstdFlags)
	errWriter := api.NewErrResponseWriter(w, l)
	url := strings.Split(r.URL.Path, "/")
	ID, err := strconv.Atoi(url[len(url)-1])

	if err != nil {
		errWriter.HandleErr("Bad", err)
		return
	}

	if r.Method == http.MethodGet {
		listRecipeDetails(ID, w, r)
		return
	}
}

func IngredientHandler(w http.ResponseWriter, r *http.Request) {

}

type recipeIngredient struct {
	ID           int    `json:"id"`
	IngredientID int    `json:"ingredientId"`
	Name         string `json:"name"`
}

func listRecipeDetails(ID int, w http.ResponseWriter, r *http.Request) {
	l := log.New(os.Stderr, fmt.Sprintf("recipe-details.listRecipeDetails: %d :", ID), log.LstdFlags)
	errWriter := api.NewErrResponseWriter(w, l)

	rows, err := api.DB.Query(`
		SELECT recipe_ingredient.id, ingredient_id, ingredient.name FROM recipe_ingredient
		LEFT JOIN ingredient ON ingredient.id = ingredient_id
		WHERE recipe_id = $1;
	`, ID)

	if err != nil {
		errWriter.HandleErr("Failed to execute db query when listing recipe ingredients", err)
		return
	}

	defer rows.Close()

	ingredients := make([]recipeIngredient, 0)

	for rows.Next() {
		rowID := new(int)
		ingredientID := new(int)
		var ingredientName string
		err := rows.Scan(rowID, ingredientID, &ingredientName)
		if err != nil {
			errWriter.HandleErr("Error while scanning recipe ingredient row", err)
			break
		}
		if rowID == nil || ingredientID == nil {
			errWriter.HandleErr("", errors.New("unexpected nil field"))
			break
		}

		ingredients = append(ingredients, recipeIngredient{
			ID:           *rowID,
			IngredientID: *ingredientID,
			Name:         ingredientName,
		})
	}

	jsRes, err := json.Marshal(ingredients)

	if err != nil {
		errWriter.HandleErr("Failed to marshal ingredients to json response", err)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write(jsRes)
}
