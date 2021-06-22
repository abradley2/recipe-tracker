package ingredients

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/abradley2/recipe-tracker/api"
	"github.com/pkg/errors"
)

type createIngredientRequestBody struct {
	RecipeID *int    `json:"recipeId"`
	Quantity *string `json:"quantity"`
	Name     *string `json:"name"`
}

func (req *createIngredientRequestBody) FromRequest(r *http.Request) error {
	b, err := api.ReadBody(r)

	if err != nil {
		return errors.Wrap(
			err,
			"Failed to read requst body",
		)
	}

	err = json.Unmarshal(b, req)

	if err != nil {
		err = errors.Wrap(err, "Failed to unmarshal json in FromRequest")
	}

	return err
}

func CreateIngredientHandler(w http.ResponseWriter, r *http.Request) {
	l := log.New(os.Stderr, "ingrdients.CreateIngredientHandler ", log.LstdFlags)
	errRes := api.NewErrResponseWriter(w, l)

	l.Printf("Received create ingredient request")

	req := createIngredientRequestBody{}

	err := req.FromRequest(r)
	if err != nil {
		errRes.HandleErr("Failed to read request body", err)
		return
	}

	if req.Name == nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("Invalid request, missing 'name' in payload"))
		return
	}

	tx, err := api.DB.Begin()

	if err != nil {
		errRes.HandleErr("Failed to initialize create ingredient transaction", err)
		return
	}

	sqlRes := tx.QueryRow(`
		INSERT INTO ingredient (name) VALUES ($1) RETURNING id, created_at;
	`, *req.Name)

	var createdAt time.Time
	var createdId int

	err = sqlRes.Scan(&createdId, &createdAt)

	if err != nil {
		errRes.HandleErr("Failed to get created id from sql response", err)
		return
	}

	if req.RecipeID != nil {
		fmt.Printf("created: %d , recipeId: %d\n", createdId, *req.RecipeID)
		_, err = tx.Exec(`
			INSERT INTO recipe_ingredient (ingredient_id, recipe_id) VALUES ($1, $2);
		`, createdId, *req.RecipeID)

		if err != nil {
			errRes.HandleErr("Failed to insert recipe_ingredient when creating ingredient", err)
			return
		}
	}

	err = tx.Commit()

	if err != nil {
		errRes.HandleErr("Failed to commit create ingredient transaction", err)
		return
	}

	jsRes, err := json.Marshal(Ingredient{
		ID:        strconv.Itoa(createdId),
		Name:      *req.Name,
		CreatedAt: createdAt,
	})

	if err != nil {
		errRes.HandleErr("Failed to marshal json response", err)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write(jsRes)
}
