package recipes

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/abradley2/recipe-tracker/api"
)

type ListAllResult struct {
	ID        int64     `json:"id"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"createdAt"`
}

func ListAllHandler(w http.ResponseWriter, r *http.Request) {
	l := log.New(os.Stderr, "recipes.ListAllHandler ", log.LstdFlags)

	l.Printf("Received get all recipes request")

	rows, err := api.DB.Query(`
		SELECT id, name, created_at FROM recipe;
	`)

	if err != nil {
		l.Printf("Failed to execute query: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	defer rows.Close()

	results := make([]ListAllResult, 0)

	for rows.Next() {
		var id int64
		var name string
		var createdAt time.Time
		err = rows.Scan(&id, &name, &createdAt)
		if err != nil {
			break
		}
		results = append(results, ListAllResult{
			ID:        id,
			Name:      name,
			CreatedAt: createdAt,
		})
	}

	if err != nil {
		l.Printf("Error while reading rows: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	resJson, err := json.Marshal(results)

	if err != nil {
		l.Printf("Error while marshalling response json: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write(resJson)
}
