package protocol

// StreamMsg is a single NDJSON message in the streaming response.
type StreamMsg struct {
	Type    string `json:"type"`
	Message string `json:"message,omitempty"`
	Stream  string `json:"stream,omitempty"`
	Data    string `json:"data,omitempty"`
	Code    int    `json:"code,omitempty"`
}
