package worker

import (
	"context"
	"log"
	"sync"
)

type Task func(ctx context.Context)

type Pool struct {
	taskQueue chan Task
	wg        sync.WaitGroup
}

func NewPool(size int, buffer int) *Pool {
	p := &Pool{
		taskQueue: make(chan Task, buffer),
	}

	p.wg.Add(size)
	for i := 0; i < size; i++ {
		go p.worker()
	}

	return p
}

func (p *Pool) worker() {
	defer p.wg.Done()
	for task := range p.taskQueue {
		// Use a background context for each task to ensure it outlives the request
		task(context.Background())
	}
}

func (p *Pool) Submit(task Task) {
	select {
	case p.taskQueue <- task:
	default:
		log.Println("Worker pool buffer full, dropping task")
	}
}

// Stop closes the task queue and waits for all active workers to finish
func (p *Pool) Stop() {
	close(p.taskQueue)
	p.wg.Wait()
}
