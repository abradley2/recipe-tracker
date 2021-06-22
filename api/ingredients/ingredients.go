package ingredients

import (
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

type Ingredient struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"createdAt"`
}

func Handler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodGet {
		ListAllHandler(w, r)
		return
	}

	if r.Method == http.MethodPost {
		CreateIngredientHandler(w, r)
		return
	}

	w.WriteHeader(http.StatusMethodNotAllowed)
	w.Write([]byte("Method not allowed"))
}

func ItemHandler(w http.ResponseWriter, r *http.Request) {
	l := log.New(os.Stderr, "ingredients.ItemHandler", log.LstdFlags)
	path := strings.Split(r.URL.Path, "/")
	id, err := strconv.Atoi(path[len(path)-1])

	if err != nil {
		l.Printf("Error retrieving itemId from path: %v", err)
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("Missing itemId in request path"))
		return
	}

	if r.Method == http.MethodDelete {
		RemoveHandler(strconv.Itoa(id), w, r)
		return
	}

	w.WriteHeader(http.StatusMethodNotAllowed)
	w.Write([]byte("Method not allowed"))
}
