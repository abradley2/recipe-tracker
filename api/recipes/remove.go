package recipes

import (
	"log"
	"net/http"
	"os"

	"github.com/abradley2/recipe-tracker/api"
)

func RemoveHandler(id string, w http.ResponseWriter, r *http.Request) {
	l := log.New(os.Stderr, "recipes.RemoveHandler ", log.Ltime)

	l.Printf("Received remove recipe request")

	tx, err := api.DB.Begin()

	if err != nil {
		l.Printf("Failed to start transation: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	_, err = tx.Exec(`
		DELETE FROM recipe_ingredient WHERE recipe_id = $1;
	`, id)

	if err != nil {
		l.Printf("Failed to delete recipe_ingredient: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	_, err = tx.Exec(`
		DELETE FROM recipe WHERE id = $1;
	`, id)

	if err != nil {
		l.Printf("Failed to delete recipe: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	err = tx.Commit()

	if err != nil {
		l.Printf("Transaction failed while deleting recipe: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte("Deleted"))
}
