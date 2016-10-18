package syncqueue

import (
	"sync"
)

type Queue struct {
	max    int
	queue  []interface{}
	closed bool
	lock   sync.Mutex
	cond   *sync.Cond
}

func New(max int) *Queue {
	q := &Queue{max, nil, false, sync.Mutex{}, nil}
	q.cond = sync.NewCond(&q.lock)
	return q
}

func (q *Queue) Close(v interface{}) {
	q.lock.Lock()
	defer q.lock.Unlock()

	q.closed = true
	q.cond.Signal()
}

func (q *Queue) Add(v interface{}) bool {
	q.lock.Lock()
	defer q.lock.Unlock()

	if q.max > 0 && len(q.queue) >= q.max {
		return false
	}
	q.queue = append(q.queue, v)
	q.cond.Signal()
	return true
}

func (q *Queue) Pop() interface{} {
	q.lock.Lock()
	defer q.lock.Unlock()

	for len(q.queue) == 0 && !q.closed {
		q.cond.Wait()
	}

	if len(q.queue) == 0 {
		return nil
	} else {
		rv := q.queue[0]
		q.queue = q.queue[1:]
		return rv
	}
}
