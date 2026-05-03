package ports

import "context"

type VisionAnalysis struct {
	Description string   `json:"description"`
	Department  string   `json:"department"`
	Tags        []string `json:"tags"`
	Confidence  float64  `json:"confidence"`
}

type VisionProvider interface {
	AnalyzeImage(ctx context.Context, image []byte) (*VisionAnalysis, error)
}
