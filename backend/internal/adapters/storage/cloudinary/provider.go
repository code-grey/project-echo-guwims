package cloudinary

import (
	"bytes"
	"context"
	"fmt"
	"net/url"
	"strconv"
	"time"

	"github.com/cloudinary/cloudinary-go/v2"
	"github.com/cloudinary/cloudinary-go/v2/api"
	"github.com/cloudinary/cloudinary-go/v2/api/uploader"
	"github.com/code-grey/project-echo-guwims/backend/internal/core/ports"
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

func (p *Provider) GenerateSignature() (*ports.StorageSignature, error) {
	timestamp := time.Now().Unix()
	folder := "project-echo-guwims"

	params := url.Values{}
	params.Add("folder", folder)
	params.Add("timestamp", strconv.FormatInt(timestamp, 10))

	// The SDK parses the secret into Config.Cloud.APISecret
	secret := p.cld.Config.Cloud.APISecret
	if secret == "" {
		return nil, fmt.Errorf("cloudinary secret not configured")
	}

	sign, err := api.SignParameters(params, secret)
	if err != nil {
		return nil, fmt.Errorf("failed to sign parameters: %w", err)
	}

	return &ports.StorageSignature{
		Signature: sign,
		Timestamp: timestamp,
		CloudName: p.cld.Config.Cloud.CloudName,
		APIKey:    p.cld.Config.Cloud.APIKey,
		Folder:    folder,
	}, nil
}
