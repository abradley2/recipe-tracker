package main

import (
	"net/http"
	"strings"

	"github.com/abradley2/recipe-tracker/api"
	"github.com/abradley2/recipe-tracker/api/ingredients"
	"github.com/abradley2/recipe-tracker/api/recipe"
	"github.com/abradley2/recipe-tracker/api/recipes"
	"github.com/spf13/viper"
)

var config api.Config

func readConfig() {
	var err error

	viper.SetConfigFile("config.toml")
	err = viper.ReadInConfig()

	if err != nil {
		panic(err)
	}
	config = api.Config{
		PostgresURL: viper.GetString("POSTGRES_URL"),
	}
	err = config.Validate()
	if err != nil {
		panic(err)
	}
}

type spaWriter struct {
	notFound bool
	w        http.ResponseWriter
	r        *http.Request
}

func (sw *spaWriter) Header() http.Header {
	return sw.w.Header()
}

func (sw *spaWriter) WriteHeader(code int) {
	if code == http.StatusNotFound {
		sw.notFound = true
		sw.w.Header().Set("Content-Type", "text/html")
		http.ServeFile(sw.w, sw.r, "public/index.html")
		return
	}
	sw.w.WriteHeader(code)
}

func (sw *spaWriter) Write(b []byte) (int, error) {
	if !sw.notFound {
		return sw.w.Write(b)
	}
	return len(b), nil
}

type spaServer struct {
	fs  http.Handler
	api http.Handler
}

func (s *spaServer) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if strings.Contains(r.URL.Path, "/api") {
		s.api.ServeHTTP(w, r)
		return
	}
	px := spaWriter{false, w, r}

	s.fs.ServeHTTP(&px, r)
}

func main() {
	readConfig()
	api.OpenDB(config)

	server := http.NewServeMux()

	fs := http.FileServer(http.Dir("public"))
	api := http.NewServeMux()

	api.HandleFunc("/api/recipes", recipes.Handler)
	api.HandleFunc("/api/recipes/", recipes.ItemHandler)

	api.HandleFunc("/api/ingredients", ingredients.Handler)
	api.HandleFunc("/api/ingredients/", ingredients.ItemHandler)

	api.HandleFunc("/api/recipe-details/", recipe.Handler)

	spa := spaServer{fs, api}

	server.Handle("/", &spa)

	http.ListenAndServe(":8080", server)
}
