package worker

import (
	"context"
	"math"
	"time"
)

// Retry with exponential backoff
func Retry(ctx context.Context, attempts int, initialDelay time.Duration, task func() error) error {
	var err error
	for i := 0; i < attempts; i++ {
		if err = task(); err == nil {
			return nil
		}

		// Calculate next delay: initialDelay * 2^i
		delay := initialDelay * time.Duration(math.Pow(2, float64(i)))
		
		select {
		case <-time.After(delay):
		case <-ctx.Done():
			return ctx.Err()
		}
	}
	return err
}
