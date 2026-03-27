package daemon

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"sync"

	"github.com/ewout/host-gate/internal/protocol"
)

func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status":  "ok",
		"version": "1.0.0",
	})
}

func (s *Server) handleExecute(w http.ResponseWriter, r *http.Request) {
	var req protocol.ExecuteRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid json", http.StatusBadRequest)
		return
	}
	if err := req.Validate(); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	canonical := req.CanonicalString()
	if !protocol.Verify(s.keyManager.Key(), canonical, req.HMAC) {
		http.Error(w, "hmac verification failed", http.StatusUnauthorized)
		return
	}

	if !s.replay.Check(req.Nonce, req.Timestamp) {
		http.Error(w, "replay detected", http.StatusForbidden)
		return
	}

	hostCfg := s.hostConfig
	if reloaded, err := LoadHostConfig(s.cfg.HostConfigPath); err != nil {
		slog.Warn("Failed to reload host config, using last good config", "error", err)
	} else {
		s.hostConfig = reloaded
		hostCfg = reloaded
	}

	effectiveExecution, effectiveApproval, err := hostCfg.ApplyPolicy(
		req.Command, req.Args, req.Execution, req.Approval,
	)
	if err != nil {
		http.Error(w, err.Error(), http.StatusForbidden)
		return
	}

	flusher, ok := w.(http.Flusher)
	if !ok {
		http.Error(w, "streaming not supported", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/x-ndjson")
	w.WriteHeader(http.StatusOK)
	enc := json.NewEncoder(w)

	if effectiveApproval == "none" {
		slog.Info("Auto-approved (approval=none)", "command", req.Command)
	} else if effectiveApproval == "yubikey" {
		enc.Encode(protocol.StreamMsg{Type: "status", Message: "Approve in popup AND touch your YubiKey..."})
		flusher.Flush()

		var wg sync.WaitGroup
		var popupApproved bool
		var popupErr error
		var ykErr error

		wg.Add(2)
		go func() {
			defer wg.Done()
			popupApproved, popupErr = s.requestApproval(r.Context(), req)
		}()
		go func() {
			defer wg.Done()
			ykErr = s.requireYubiKeyTouch(r.Context())
		}()
		wg.Wait()

		if popupErr != nil || !popupApproved {
			msg := "User denied the request"
			if popupErr != nil {
				msg = popupErr.Error()
			}
			enc.Encode(protocol.StreamMsg{Type: "denied", Message: msg})
			flusher.Flush()
			return
		}
		if ykErr != nil {
			enc.Encode(protocol.StreamMsg{Type: "denied", Message: "YubiKey touch failed: " + ykErr.Error()})
			flusher.Flush()
			return
		}
	} else {
		enc.Encode(protocol.StreamMsg{Type: "status", Message: "Waiting for user approval..."})
		flusher.Flush()

		approved, err := s.requestApproval(r.Context(), req)
		if err != nil || !approved {
			msg := "User denied the request"
			if err != nil {
				msg = err.Error()
			}
			enc.Encode(protocol.StreamMsg{Type: "denied", Message: msg})
			flusher.Flush()
			return
		}
	}

	enc.Encode(protocol.StreamMsg{Type: "approved"})
	flusher.Flush()

	if effectiveExecution == "proxy" {
		s.proxyExecute(r.Context(), w, flusher, enc, req)
	}
}
