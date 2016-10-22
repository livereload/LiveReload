package protocol

type Message struct {
	Command string `json:"command"`

	// for CmdHello
	Protocols []string `json:"protocols,omitempty"`
	Ver       string   `json:"ver,omitempty"`
	Ext       string   `json:"ext,omitempty"`
	ExtVer    string   `json:"extver,omitempty"`
	SnipVer   string   `json:"snipver,omitempty"`

	// for CmdReload
	Path        string `json:"path,omitempty"`
	OrigPath    string `json:"originalPath,omitempty"`
	OverrideURL string `json:"overrideURL,omitempty"`
	LiveCSS     *bool  `json:"liveCSS,omitempty"`

	// for CmdInfo
	URL     string                            `json:"url,omitempty"`
	Plugins map[string]map[string]interface{} `json:"plugins,omitempty"`
}

const (
	CmdHello = "hello"

	// incoming
	CmdInfo = "info"

	// outgoing
	CmdReload = "reload"
)

type Protocols struct {
	ConnCheck  int
	Monitoring int
}

const (
	ConnCheckV1String  = "http://livereload.com/protocols/connection-check-1"
	MonitoringV7String = "http://livereload.com/protocols/official-7"
)

const (
	ConnCheckV1  = 1
	MonitoringV7 = 7
)

func Negotiate(remote, local []string) Protocols {
	var p Protocols
	if try(remote, local, ConnCheckV1String) {
		p.ConnCheck = ConnCheckV1
	}
	if try(remote, local, MonitoringV7String) {
		p.Monitoring = MonitoringV7
	}
	return p
}

func try(remote, local []string, proto string) bool {
	return contains(remote, proto) && contains(local, proto)
}

func contains(list []string, v string) bool {
	for _, item := range list {
		if item == v {
			return true
		}
	}
	return false
}
