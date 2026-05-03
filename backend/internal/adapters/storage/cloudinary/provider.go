package cloudinary

import (
	"bytes"
	"context"
	"fmt"

	"github.com/cloudinary/cloudinary-go/v2"
	"github.com/cloudinary/cloudinary-go/v2/api/uploader"
)

type Provider struct {
	cld *cloudinary.Cloudinary
}

func NewProvider(url string) (*Provider, error) {
	cld, err := cloudinary.NewFromURL(url)
	if err != nil {
		return nil, err
	}
	return &Provider{cld: cld}, nil
}

func (p *Provider) UploadImage(ctx context.Context, file []byte) (string, error) {
	// The Upload method handles []byte via bytes.NewReader seamlessly.
	resp, err := p.cld.Upload.Upload(ctx, bytes.NewReader(file), uploader.UploadParams{
		Folder: "project-echo-guwims",
	})
	if err != nil {
		return "", fmt.Errorf("failed to upload image: %w", err)
	}

	return resp.SecureURL, nil
}

func (p *Provider) DeleteImage(ctx context.Context, imageURL string) error {
	// Not implementing full URL parsing for simplicity in prototype, 
	// just satisfying the interface. In production, parse public ID from URL.
	return nil
}
