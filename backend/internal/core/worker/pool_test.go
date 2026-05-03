package worker

import (
	"context"
	"sync"
	"testing"
)

func TestPoolRace(t *testing.T) {
	p := NewPool(5, 10)
	var wg sync.WaitGroup

	// Stress test the pool with concurrent submissions
	for i := 0; i < 20; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			p.Submit(func(ctx context.Context) {
				// Simulate some work
			})
		}(i)
	}

	wg.Wait()
}
