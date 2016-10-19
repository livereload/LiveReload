package protocol

type Message struct {
	Command   string   `json:"command"`
	Protocols []string `json:"protocols"`
}

const (
	CmdHello = "hello"
)

const (
	ProtoConnCheck1 = "http://livereload.com/protocols/connection-check-1"
)
