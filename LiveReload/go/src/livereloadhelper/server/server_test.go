package server

import (
	"context"
	"testing"
)

func TestSomething(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	s := &Server{Context: ctx}
	s.Start()

	err := s.Wait()
	if err != nil {
		t.Fatalf("HTTP server error: %v", err)
	}
}
