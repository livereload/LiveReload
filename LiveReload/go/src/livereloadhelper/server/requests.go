package server

import (
	"livereloadhelper/protocol"
	"log"
)

type ReloadRequest struct {
	Path        string
	OrigPath    string
	OverrideURL string
	LiveCSS     bool
}

func (s *Server) SendReloadRequest(r ReloadRequest) {
	log.Printf("Sending reload request: %#v", r)
	msg := protocol.Message{
		Command:     protocol.CmdReload,
		Path:        r.Path,
		OrigPath:    r.OrigPath,
		OverrideURL: r.OverrideURL,
		LiveCSS:     &r.LiveCSS,
	}
	s.broadcast(func(c *Conn) {
		if c.protocols.Monitoring >= protocol.MonitoringV7 {
			c.MustSend(msg)
		}
	})
}
