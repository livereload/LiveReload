package wsconn

import (
	"github.com/fluxio/multierror"
	"github.com/pkg/errors"
	"golang.org/x/net/websocket"
	"io"
	"log"
	"sync"
)

type Conn struct {
	// WSConn is the underlying web socket connection.
	WSConn *websocket.Conn

	// ID is an optional arbitrary identifier for this connection. Will be used for logging.
	ID int

	// Done is an optional channel that, when closed, will terminate the connection.
	Done <-chan struct{}

	// Send is a channel to send outgoing messages on. Can be customized by the caller before calling Start. If not initialized, will be set to a new buffered channel by Start.
	Send chan interface{}

	// Recv is a channel to receive incoming messages on. If not initialized, will be set to a new buffered channel by Start.
	Recv chan interface{}

	// shutdown is an internal channel used to initiate closing of the connections.
	shutdown chan struct{}

	wg sync.WaitGroup

	// errors is an error accumulator
	errors multierror.ConcurrentAccumulator
}

func (c *Conn) Start() {
	if c.Send == nil {
		c.Send = make(chan interface{}, 100)
	}
	if c.Recv == nil {
		c.Recv = make(chan interface{}, 1)
	}

	c.shutdown = make(chan struct{})

	log.Printf("ws-conn-%04d: started", c.ID)

	c.wg.Add(2)
	go c.receiveLoop()
	go c.sendLoop()
}

func (c *Conn) Close() {
	close(c.shutdown)
}

// Wait sleeps until the connection has been teared down. Returns the error(s) encountered during the lifecycle of the connection. (May be a multierror if multiple simultaneous errors were encountered before the connection had been teared down completely.)
func (c *Conn) Wait() error {
	c.wg.Wait()
	return c.errors.Error()
}

func (c *Conn) receiveLoop() {
	defer c.wg.Done()
	for {
		var msg interface{}
		err := websocket.JSON.Receive(c.WSConn, &msg)
		if err == io.EOF {
			log.Printf("ws-conn-%04d: received EOF", c.ID)
			close(c.shutdown)
			break
		} else if err != nil {
			log.Printf("ws-conn-%04d: receive error: %v", c.ID, err)
			c.errors.Push(errors.Wrap(err, "receive error"))
			close(c.shutdown)
			break
		}
		c.Recv <- msg
	}
	close(c.Recv)
}

func (c *Conn) sendLoop() {
	defer c.wg.Done()

	sendc := c.Send

	for {
		select {
		case msg := <-sendc:
			err := websocket.JSON.Send(c.WSConn, msg)
			if err != nil {
				log.Printf("ws-conn-%04d: send error: %v", c.ID, err)
				c.errors.Push(errors.Wrap(err, "send error"))
				close(c.shutdown)
				sendc = nil // stop sending messages after an error
			}
			log.Printf("ws-conn-%04d: sent: %#v", c.ID, msg)

		case <-c.shutdown:
			err := c.WSConn.Close()
			if err != nil {
				log.Printf("ws-conn-%04d: close error: %v", c.ID, err)
				c.errors.Push(errors.Wrap(err, "close error"))
			}
			log.Printf("ws-conn-%04d: closed", c.ID)
			return

		case <-c.Done:
			close(c.shutdown)
		}
	}
}
