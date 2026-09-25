package protocol

import (
	"encoding/json"
	"fmt"
	"strings"
)

type ExecuteRequest struct {
	Version   int      `json:"version"`
	Nonce     string   `json:"nonce"`
	Timestamp int64    `json:"timestamp"`
	Command   string   `json:"command"`
	Args      []string `json:"args"`
	Cwd       string   `json:"cwd"`
	HostCwd   string   `json:"hostCwd,omitempty"`
	Execution string   `json:"execution"`
	Approval  string   `json:"approval"`
	HMAC      string   `json:"hmac"`
}

func (r *ExecuteRequest) Validate() error {
	if r.Version != 1 {
		return fmt.Errorf("unsupported protocol version: %d", r.Version)
	}
	if r.Nonce == "" {
		return fmt.Errorf("nonce is required")
	}
	if r.Timestamp == 0 {
		return fmt.Errorf("timestamp is required")
	}
	if r.Command == "" {
		return fmt.Errorf("command is required")
	}
	if r.Cwd == "" {
		return fmt.Errorf("cwd is required")
	}
	if r.Execution != "proxy" && r.Execution != "local" {
		return fmt.Errorf("execution must be 'proxy' or 'local', got %q", r.Execution)
	}
	if r.Approval != "none" && r.Approval != "popup" && r.Approval != "yubikey" {
		return fmt.Errorf("approval must be 'none', 'popup', or 'yubikey', got %q", r.Approval)
	}
	if r.HMAC == "" {
		return fmt.Errorf("hmac is required")
	}
	return nil
}

// CanonicalString produces the string that is HMAC-signed.
// Format: v1:{nonce}:{timestamp}:{command}:{args_json}:{cwd}:{hostCwd}:{execution}:{approval}
func (r *ExecuteRequest) CanonicalString() string {
	argsJSON, _ := json.Marshal(r.Args)
	return strings.Join([]string{
		"v1",
		r.Nonce,
		fmt.Sprintf("%d", r.Timestamp),
		r.Command,
		string(argsJSON),
		r.Cwd,
		r.HostCwd,
		r.Execution,
		r.Approval,
	}, ":")
}
