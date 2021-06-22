package api

import (
	"log"
	"net/http"
)

type ErrResponseWriter struct {
	w http.ResponseWriter
	l *log.Logger
}

func NewErrResponseWriter(w http.ResponseWriter, l *log.Logger) ErrResponseWriter {
	return ErrResponseWriter{w, l}
}

func (writer ErrResponseWriter) HandleErr(msg string, err error) {
	writer.l.Printf("%s: %v", msg, err)
	writer.w.WriteHeader(http.StatusInternalServerError)
	writer.w.Write([]byte("Internal server error"))
}
