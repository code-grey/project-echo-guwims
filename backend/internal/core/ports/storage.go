package ports

import "context"

type StorageSignature struct {
	Signature string `json:"signature"`
	Timestamp int64  `json:"timestamp"`
	CloudName string `json:"cloud_name"`
	APIKey    string `json:"api_key"`
	Folder    string `json:"folder"`
}

type StorageProvider interface {
	UploadImage(ctx context.Context, file []byte) (string, error)
	DeleteImage(ctx context.Context, url string) error
	GenerateSignature() (*StorageSignature, error)
}
