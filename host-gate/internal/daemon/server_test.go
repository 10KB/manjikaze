package daemon

import (
	"testing"
)

func TestMapCwd(t *testing.T) {
	s := &Server{
		workspaceMaps: map[string]string{
			"/workspace": "/home/user/project",
		},
	}

	tests := []struct {
		input    string
		expected string
	}{
		{"/workspace", "/home/user/project"},
		{"/workspace/src/main.go", "/home/user/project/src/main.go"},
		{"/other/path", "/other/path"},
	}

	for _, tt := range tests {
		result := s.mapCwd(tt.input)
		if result != tt.expected {
			t.Errorf("mapCwd(%q) = %q, want %q", tt.input, result, tt.expected)
		}
	}
}
