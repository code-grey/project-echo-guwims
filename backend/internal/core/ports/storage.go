package ports

import "context"

type StorageProvider interface {
	UploadImage(ctx context.Context, file []byte) (string, error)
	DeleteImage(ctx context.Context, url string) error
}
