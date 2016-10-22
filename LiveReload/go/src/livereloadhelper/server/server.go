package server

import (
	"context"
	"errors"
	"log"
	"net/http"
	"strconv"
	"sync"
	"time"

	"github.com/facebookgo/httpdown"
	"golang.org/x/net/websocket"

	pr "livereloadhelper/protocol"
	"livereloadhelper/wsconn"
)

const DefaultPort = 35729

var supportedProtocols = []string{pr.ConnCheckV1String, pr.MonitoringV7String}

var ErrProtocolViolation = errors.New("protocol violation")
var ErrNoCommonProtocols = errors.New("no common protocols supported")

type Server struct {
	Context      context.Context
	Port         int
	LiveReloadJS []byte

	hs httpdown.Server

	mut    sync.Mutex
	previd int
	conns  map[int]*Conn

	v    uint64
	cond *sync.Cond
}

type Status struct {
	Conns int
	V     uint64
}

type Conn struct {
	wsconn.Conn
	protocols pr.Protocols
}

func (s *Server) Start() {
	if s.Context == nil {
		s.Context = context.Background()
	}
	if s.Port == 0 {
		s.Port = DefaultPort
	}
	if s.v == 0 {
		s.v = 1
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/livereload.js", s.serveLiveReloadJS)
	mux.HandleFunc("/xlivereload.js", s.serveLiveReloadJS)
	mux.Handle("/livereload", websocket.Handler(s.handleConnection))

	s.conns = make(map[int]*Conn)
	s.cond = sync.NewCond(&s.mut)

	hd := &httpdown.HTTP{
		StopTimeout: 5 * time.Second,
		KillTimeout: 5 * time.Second,
	}

	server := &http.Server{Addr: ":" + strconv.Itoa(s.Port), Handler: mux}

	hs, err := hd.ListenAndServe(server)
	if err != nil {
		panic("ListenAndServe: " + err.Error())
	}
	s.hs = hs
	log.Printf("Listening on port %v", s.Port)

	go s.shutdownOn(s.Context.Done())
}

func (s *Server) Wait() error {
	return s.hs.Wait()
}

func (s *Server) Stop() {
	err := s.hs.Stop()
	if err != nil {
		log.Printf("ERROR: Failed to gracefully stop the HTTP server: %v", err)
	}
}

func (s *Server) shutdownOn(done <-chan struct{}) {
	if done == nil {
		return
	}

	<-done
	s.Stop()
}

func (s *Server) handleConnection(ws *websocket.Conn) {
	log.Printf("handleConnection")

	c := s.setupConnection(ws)

	var handshaked bool

loop:
	for {
		select {
		case msg_, ok := <-c.Recv:
			if !ok {
				break loop
			}
			msg := msg_.(pr.Message)

			if !handshaked {
				if msg.Command == pr.CmdHello {
					c.protocols = pr.Negotiate(msg.Protocols, supportedProtocols)
					if c.protocols.ConnCheck == 0 && c.protocols.Monitoring == 0 {
						c.Fail(ErrNoCommonProtocols)
						break
					}
					c.MustSend(pr.Message{
						Command:   pr.CmdHello,
						Protocols: supportedProtocols,
					})
					handshaked = true
				} else {
					c.Fail(ErrProtocolViolation)
				}
				continue
			}

			if msg.Command == "stop" {
				s.Stop()
			}
		}
	}

	err := c.Wait()
	if err != nil {
		log.Printf("Web socket connection ended with an error: %v", err)
	}

	s.tearDownConnection(c)
}

func (s *Server) setupConnection(ws *websocket.Conn) *Conn {
	s.mut.Lock()
	defer s.mut.Unlock()

	s.previd++
	id := s.previd

	c := &Conn{
		Conn: wsconn.Conn{
			WSConn: ws,
			ID:     id,
			Done:   s.Context.Done(),
			Receive: func(ws *websocket.Conn) (interface{}, error) {
				var msg pr.Message
				err := websocket.JSON.Receive(ws, &msg)
				return msg, err
			},
		},
	}
	s.conns[id] = c
	s.notifyChange()

	c.Start()
	return c
}

func (s *Server) tearDownConnection(c *Conn) {
	s.mut.Lock()
	defer s.mut.Unlock()

	delete(s.conns, c.ID)
	s.notifyChange()
}

func (s *Server) broadcast(f func(c *Conn)) {
	s.mut.Lock()
	defer s.mut.Unlock()

	for _, c := range s.conns {
		f(c)
	}
}

func (s *Server) notifyChange() {
	s.v++
	s.cond.Signal()
}

func (s *Server) status() Status {
	return Status{
		Conns: len(s.conns),
		V:     s.v,
	}
}

func (s *Server) Status() Status {
	s.mut.Lock()
	defer s.mut.Unlock()

	return s.status()
}

func (s *Server) AwaitStatusChange(lastv uint64) Status {
	s.mut.Lock()
	defer s.mut.Unlock()

	for s.v <= lastv {
		s.cond.Wait()
	}

	return s.status()
}

func (s *Server) serveLiveReloadJS(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/javascript")
	w.Write(s.LiveReloadJS)
}
