package api

import (
	"bytes"
	"fmt"
	"io"
	"net/http"

	"github.com/pkg/errors"
)

// set max to 64kb
const max = 1024 * 64

func ReadBody(r *http.Request) ([]byte, error) {
	b := r.Body
	defer b.Close()

	var buf []byte
	var nextLen int

	for {
		nextBuf := make([]byte, 1)

		byteLen, err := b.Read(nextBuf)
		nextLen = nextLen + byteLen
		buf = append(buf, nextBuf...)

		if err == io.EOF {
			return bytes.TrimRight(buf, "\x00"), nil
		}
		if err != nil {
			return buf, errors.Wrap(err, "error reading from buffer")
		}
		if len(buf) > max {
			return buf, fmt.Errorf("exceeded read limit")
		}
	}
}
