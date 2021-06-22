package recipes

import (
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
)

func Handler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodPost {
		CreateHandler(w, r)
		return
	}
	if r.Method == http.MethodGet {
		ListAllHandler(w, r)
		return
	}

	w.WriteHeader(http.StatusMethodNotAllowed)
	w.Write([]byte("Method not supported"))
}

func ItemHandler(w http.ResponseWriter, r *http.Request) {
	l := log.New(os.Stderr, "recipes.ItemHandler ", log.LstdFlags)

	path := strings.Split(r.URL.Path, "/")
	itemId, err := strconv.Atoi(path[len(path)-1])

	if err != nil {
		l.Printf("Could not get itemId from path: %v", err)
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("Could not find itemId in request path"))
		return
	}

	if r.Method == http.MethodDelete {
		RemoveHandler(strconv.Itoa(itemId), w, r)
		return
	}

	w.WriteHeader(http.StatusMethodNotAllowed)
	w.Write([]byte("Method not supported"))
}
