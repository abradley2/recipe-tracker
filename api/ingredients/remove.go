package ingredients

import (
	"log"
	"net/http"
	"os"

	"github.com/abradley2/recipe-tracker/api"
)

func RemoveHandler(id string, w http.ResponseWriter, r *http.Request) {
	l := log.New(os.Stderr, "ingredients.RemoveHandler ", log.LstdFlags)
	resErr := api.NewErrResponseWriter(w, l)

	tx, err := api.DB.Begin()

	if err != nil {
		resErr.HandleErr("Failed to open sql transaction", err)
		return
	}

	_, err = tx.Exec(`
		DELETE FROM recipe_ingredient WHERE ingredient_id = $1;
	`, id)

	if err != nil {
		resErr.HandleErr("Failed to delete recipe_ingredient", err)
		return
	}

	_, err = tx.Exec(`
		DELETE FROM ingredient WHERE id = $1;
	`, id)

	if err != nil {
		resErr.HandleErr("Failed to delete ingredient", err)
		return
	}

	err = tx.Commit()

	if err != nil {
		resErr.HandleErr("Failed to comit sql transaction", err)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}
