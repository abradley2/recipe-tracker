package recipes

import (
	"encoding/json"
	"log"
	"net/http"
	"os"

	"github.com/abradley2/recipe-tracker/api"
)

type CreateRequestBody struct {
	Name string `json:"name"`
}

type CreateRequestResponse struct {
	ID   int64  `json:"id"`
	Name string `json:"name"`
}

func CreateHandler(w http.ResponseWriter, r *http.Request) {
	l := log.New(os.Stderr, "recipes.CreateHandler", log.LstdFlags)

	l.Print("Received create recipe request")

	b, err := api.ReadBody(r)

	if err != nil {
		l.Printf("Failed to read request body: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Failed to read request body"))
		return
	}

	jsReq := new(CreateRequestBody)
	err = json.Unmarshal(b, jsReq)

	if err != nil {
		l.Printf("Failed to unmarshal request body json: %s", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Failed to unmarshal request json"))
		return
	}

	sqlRes := api.DB.QueryRow(
		`INSERT INTO recipe (name) VALUES ($1) RETURNING id;`,
		jsReq.Name,
	)

	if err != nil {
		l.Printf("Error while performing insert: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	var id int64
	err = sqlRes.Scan(&id)

	if err != nil {
		l.Printf("Error retrieving last inserted id: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	jsRes, err := json.Marshal(CreateRequestResponse{
		ID:   id,
		Name: jsReq.Name,
	})

	if err != nil {
		l.Printf("Failed to marshal response json: %s", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Failed to marshal response json"))
		return
	}

	w.WriteHeader(http.StatusCreated)
	w.Write(jsRes)
}
