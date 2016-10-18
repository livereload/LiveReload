package wsconn

import (
	"net"
)

func isUseOfClosed(err error) bool {
	if operr, ok := err.(*net.OpError); ok {
		// unfortunately, net.errClosing is not public
		if operr.Err.Error() == "use of closed network connection" {
			return true
		}
	}
	return false
}
