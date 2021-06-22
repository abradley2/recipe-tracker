package api

import "fmt"

type Config struct {
	PostgresURL string
}

func (c Config) Validate() error {
	if c.PostgresURL == "" {
		return fmt.Errorf("Missing PostgresURL")
	}

	return nil
}
