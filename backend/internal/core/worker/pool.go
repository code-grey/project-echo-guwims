package worker

import (
	"context"
	"log"
)

type Task func(ctx context.Context)

type Pool struct {
	taskQueue chan Task
}

func NewPool(size int, buffer int) *Pool {
	p := &Pool{
		taskQueue: make(chan Task, buffer),
	}

	for i := 0; i < size; i++ {
		go p.worker()
	}

	return p
}

func (p *Pool) worker() {
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
