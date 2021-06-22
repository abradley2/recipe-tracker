package api

import (
	"database/sql"

	_ "github.com/lib/pq"
)

var DB *sql.DB

func OpenDB(cfg Config) {
	var err error
	DB, err = sql.Open("postgres", cfg.PostgresURL)
	if err != nil {
		panic(err)
	}
}
