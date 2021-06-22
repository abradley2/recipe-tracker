package ingredients

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/abradley2/recipe-tracker/api"
)

func ListAllHandler(w http.ResponseWriter, r *http.Request) {
	l := log.New(os.Stderr, "ingredients.ListAllHandler ", log.LstdFlags)
	errRes := api.NewErrResponseWriter(w, l)

	l.Printf("Recieved list all ingredients request")

	rows, err := api.DB.Query(`
		SELECT id, name, created_at FROM ingredient;
	`)

	if err != nil {
		errRes.HandleErr("failed to open list all ingredients query", err)
		return
	}

	defer rows.Close()

	results := make([]Ingredient, 0)

	for rows.Next() {
		id := new(string)
		name := new(string)
		createdAt := new(time.Time)
		rows.Scan(id, name, createdAt)
		if id != nil && name != nil && createdAt != nil {
			results = append(results, Ingredient{
				*id,
				*name,
				*createdAt,
			})
		}
	}

	resJson, err := json.Marshal(results)

	if err != nil {
		errRes.HandleErr("Failed to marshal json results", err)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write(resJson)
}
