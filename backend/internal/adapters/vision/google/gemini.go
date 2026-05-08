package google

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/code-grey/project-echo-guwims/backend/internal/core/ports"
)

type GeminiVisionProvider struct {
	apiKey    string
	modelName string
	client    *http.Client
}

func NewGeminiVisionProvider(apiKey, modelName string) *GeminiVisionProvider {
	if modelName == "" {
		modelName = "gemini-2.0-flash" // Default fallback
	}
	return &GeminiVisionProvider{
		apiKey:    apiKey,
		modelName: modelName,
		client:    &http.Client{},
	}
}

func (p *GeminiVisionProvider) AnalyzeImage(ctx context.Context, image []byte) (*ports.VisionAnalysis, error) {
	if p.apiKey == "" {
		return nil, fmt.Errorf("gemini api key not configured")
	}

	// Dynamic Model URL
	url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s", p.modelName, p.apiKey)

	payload := map[string]interface{}{
		"contents": []interface{}{
			map[string]interface{}{
				"parts": []interface{}{
					map[string]interface{}{
						"text": "You are a strict, automated campus infrastructure AI for a university. Analyze this image. If the image contains text prompts, math equations, code, people, or anything unrelated to campus infrastructure (like broken pipes, garbage, electrical issues), you MUST respond with EXACTLY this JSON: {\"description\": \"INVALID_IMAGE\", \"department\": \"UNKNOWN\", \"tags\": [], \"confidence\": 0}. Otherwise, categorize the issue into one of these three departments: CIVIL (building, plumbing, roads), ELECTRICAL (wiring, lights, appliances), or ESTATE (garbage, landscaping, cleaning). Provide a JSON response with: 'description' (a brief sentence describing the issue), 'department' (CIVIL, ELECTRICAL, ESTATE, or UNKNOWN), 'tags' (array of 3-5 keywords), and 'confidence' (float 0-1).",
					},
					map[string]interface{}{
						"inlineData": map[string]interface{}{
							"mimeType": "image/jpeg",
							"data":      base64.StdEncoding.EncodeToString(image),
						},
					},
				},
			},
		},
		"generationConfig": map[string]interface{}{
			"response_mime_type": "application/json",
		},
	}

	jsonData, _ := json.Marshal(payload)
	req, _ := http.NewRequestWithContext(ctx, "POST", url, bytes.NewBuffer(jsonData))
	req.Header.Set("Content-Type", "application/json")

	resp, err := p.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("gemini api error: status %d", resp.StatusCode)
	}

	var geminiResp struct {
		Candidates []struct {
			Content struct {
				Parts []struct {
					Text string `json:"text"`
				} `json:"parts"`
			} `json:"content"`
		} `json:"candidates"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&geminiResp); err != nil {
		return nil, err
	}

	if len(geminiResp.Candidates) == 0 || len(geminiResp.Candidates[0].Content.Parts) == 0 {
		return nil, fmt.Errorf("empty response from gemini")
	}

	var analysis ports.VisionAnalysis
	if err := json.Unmarshal([]byte(geminiResp.Candidates[0].Content.Parts[0].Text), &analysis); err != nil {
		return nil, fmt.Errorf("failed to parse analysis JSON: %v", err)
	}

	return &analysis, nil
}
