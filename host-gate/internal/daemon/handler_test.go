package daemon

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"testing"
	"time"

	"github.com/ewout/host-gate/internal/protocol"
)

func setupTestServer(t *testing.T, hostCfg *HostConfig) (*Server, []byte) {
	t.Helper()
	dir := t.TempDir()

	km, err := NewKeyManager(filepath.Join(dir, "hmac.key"))
	if err != nil {
		t.Fatalf("key manager: %v", err)
	}

	if hostCfg == nil {
		hostCfg = &HostConfig{DefaultPolicy: "allow"}
	}

	mux := http.NewServeMux()
	s := &Server{
		cfg: Config{
			SocketDir:       dir,
			ApprovalTimeout: 5 * time.Second,
			YubiKeySlot:     2,
			YubiKeyTimeout:  5 * time.Second,
		},
		keyManager:    km,
		hostConfig:    hostCfg,
		replay:        NewReplayGuard(30 * time.Second),
		mux:           mux,
		workspaceMaps: map[string]string{},
	}

	mux.HandleFunc("GET /health", s.handleHealth)
	mux.HandleFunc("POST /execute", s.handleExecute)

	return s, km.Key()
}

func makeSignedRequest(key []byte) protocol.ExecuteRequest {
	req := protocol.ExecuteRequest{
		Version:   1,
		Nonce:     "test-nonce-" + time.Now().String(),
		Timestamp: time.Now().Unix(),
		Command:   "echo",
		Args:      []string{"hello"},
		Cwd:       "/workspace",
		Execution: "proxy",
		Approval:  "popup",
	}
	req.HMAC = protocol.Sign(key, req.CanonicalString())
	return req
}

func TestHealthEndpoint(t *testing.T) {
	s, _ := setupTestServer(t, nil)

	req := httptest.NewRequest("GET", "/health", nil)
	w := httptest.NewRecorder()
	s.mux.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", w.Code)
	}

	var resp map[string]string
	json.Unmarshal(w.Body.Bytes(), &resp)
	if resp["status"] != "ok" {
		t.Fatalf("expected status ok, got %s", resp["status"])
	}
}

func TestExecuteRejectsInvalidJSON(t *testing.T) {
	s, _ := setupTestServer(t, nil)

	req := httptest.NewRequest("POST", "/execute", bytes.NewReader([]byte("not json")))
	w := httptest.NewRecorder()
	s.mux.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d", w.Code)
	}
}

func TestExecuteRejectsInvalidRequest(t *testing.T) {
	s, _ := setupTestServer(t, nil)

	body, _ := json.Marshal(protocol.ExecuteRequest{Version: 2})
	req := httptest.NewRequest("POST", "/execute", bytes.NewReader(body))
	w := httptest.NewRecorder()
	s.mux.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d", w.Code)
	}
}

func TestExecuteRejectsWrongHMAC(t *testing.T) {
	s, _ := setupTestServer(t, nil)

	execReq := protocol.ExecuteRequest{
		Version:   1,
		Nonce:     "nonce",
		Timestamp: time.Now().Unix(),
		Command:   "echo",
		Args:      []string{},
		Cwd:       "/workspace",
		Execution: "proxy",
		Approval:  "popup",
		HMAC:      "wrong-hmac",
	}

	body, _ := json.Marshal(execReq)
	req := httptest.NewRequest("POST", "/execute", bytes.NewReader(body))
	w := httptest.NewRecorder()
	s.mux.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", w.Code)
	}
}

func TestExecuteRejectsReplay(t *testing.T) {
	s, key := setupTestServer(t, nil)

	execReq := protocol.ExecuteRequest{
		Version:   1,
		Nonce:     "replay-nonce",
		Timestamp: time.Now().Unix(),
		Command:   "echo",
		Args:      []string{},
		Cwd:       "/workspace",
		Execution: "proxy",
		Approval:  "popup",
	}
	execReq.HMAC = protocol.Sign(key, execReq.CanonicalString())

	// First request should pass replay check (will fail at approval since no zenity)
	body, _ := json.Marshal(execReq)
	req1 := httptest.NewRequest("POST", "/execute", bytes.NewReader(body))
	w1 := httptest.NewRecorder()
	s.mux.ServeHTTP(w1, req1)

	// Second request with same nonce should be rejected
	body2, _ := json.Marshal(execReq)
	req2 := httptest.NewRequest("POST", "/execute", bytes.NewReader(body2))
	w2 := httptest.NewRecorder()
	s.mux.ServeHTTP(w2, req2)

	if w2.Code != http.StatusForbidden {
		t.Fatalf("expected 403 for replay, got %d", w2.Code)
	}
}

func TestExecuteRejectsHostPolicyDeny(t *testing.T) {
	hostCfg := &HostConfig{
		DefaultPolicy: "deny",
		Rules: []HostRule{
			{Match: []string{"kubectl", "delete"}, Allow: false},
		},
	}
	s, key := setupTestServer(t, hostCfg)

	execReq := protocol.ExecuteRequest{
		Version:   1,
		Nonce:     "policy-nonce",
		Timestamp: time.Now().Unix(),
		Command:   "kubectl",
		Args:      []string{"delete", "ns", "prod"},
		Cwd:       "/workspace",
		Execution: "local",
		Approval:  "popup",
	}
	execReq.HMAC = protocol.Sign(key, execReq.CanonicalString())

	body, _ := json.Marshal(execReq)
	req := httptest.NewRequest("POST", "/execute", bytes.NewReader(body))
	w := httptest.NewRecorder()
	s.mux.ServeHTTP(w, req)

	if w.Code != http.StatusForbidden {
		t.Fatalf("expected 403 for policy denial, got %d", w.Code)
	}
}

func TestExecuteRejectsUnknownCommandDefaultDeny(t *testing.T) {
	hostCfg := &HostConfig{DefaultPolicy: "deny"}
	s, key := setupTestServer(t, hostCfg)

	execReq := makeSignedRequest(key)
	body, _ := json.Marshal(execReq)
	req := httptest.NewRequest("POST", "/execute", bytes.NewReader(body))
	w := httptest.NewRecorder()
	s.mux.ServeHTTP(w, req)

	if w.Code != http.StatusForbidden {
		t.Fatalf("expected 403 for unknown command with default deny, got %d", w.Code)
	}
}
