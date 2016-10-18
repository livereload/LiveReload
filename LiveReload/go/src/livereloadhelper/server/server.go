package server

import (
	"context"
	"github.com/facebookgo/httpdown"
	"golang.org/x/net/websocket"
	"livereloadhelper/wsconn"
	"log"
	"net/http"
	"sync"
	"time"
)

type Server struct {
	Context context.Context

	hs httpdown.Server

	mut    sync.Mutex
	previd int
	conns  map[int]*Conn
}

type Conn struct {
	wsconn.Conn
}

func (s *Server) Start() {
	if s.Context == nil {
		s.Context = context.Background()
	}

	mux := http.NewServeMux()
	mux.Handle("/livereload", websocket.Handler(s.handleConnection))

	s.conns = make(map[int]*Conn)

	hd := &httpdown.HTTP{
		StopTimeout: 5 * time.Second,
		KillTimeout: 5 * time.Second,
	}

	server := &http.Server{Addr: ":12345", Handler: mux}

	hs, err := hd.ListenAndServe(server)
	if err != nil {
		panic("ListenAndServe: " + err.Error())
	}
	s.hs = hs
	log.Printf("Listening on %v", server.Addr)

	go s.shutdownOn(s.Context.Done())
}

func (s *Server) Wait() error {
	return s.hs.Wait()
}

func (s *Server) shutdownOn(done <-chan struct{}) {
	if done == nil {
		return
	}

	<-done
	err := s.hs.Stop()
	if err != nil {
		log.Printf("ERROR: Failed to gracefully stop the HTTP server: %v", err)
	}
}

func (s *Server) handleConnection(ws *websocket.Conn) {
	log.Printf("handleConnection")

	s.mut.Lock()
	defer s.mut.Unlock()

	s.previd++
	id := s.previd

	c := &Conn{
		Conn: wsconn.Conn{
			WSConn: ws,
			ID:     id,
			Done:   s.Context.Done(),
		},
	}
	s.conns[id] = c

	c.Start()
	go s.handleMessages(c)

	err := c.Wait()
	if err != nil {
		log.Printf("Web socket connection ended with an error: %v", err)
	}
}

func (s *Server) handleMessages(c *Conn) {
	for msg := range c.Recv {
		log.Printf("TODO: handle message: %+v", msg)
	}

	c.Wait()

	s.mut.Lock()
	defer s.mut.Unlock()
	s.conns[c.ID] = nil
}

func (s *Server) broadcast(msg interface{}) {
	s.mut.Lock()
	defer s.mut.Unlock()

	for _, c := range s.conns {
		select {
		case c.Send <- msg:
			// ok
		default:
			// cannot send message, tear down
			c.Close()
		}
	}
}
