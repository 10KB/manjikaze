package daemon

import (
	"context"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"
)

type Server struct {
	cfg           Config
	keyManager    *KeyManager
	hostConfig    *HostConfig
	replay        *ReplayGuard
	mux           *http.ServeMux
	httpServer    *http.Server
	workspaceMaps map[string]string
}

func NewServer(cfg Config) (*Server, error) {
	if err := os.MkdirAll(cfg.SocketDir, 0700); err != nil {
		return nil, fmt.Errorf("create socket dir: %w", err)
	}

	km, err := NewKeyManager(filepath.Join(cfg.SocketDir, "hmac.key"))
	if err != nil {
		return nil, fmt.Errorf("key manager: %w", err)
	}

	hostCfg, err := LoadHostConfig(cfg.HostConfigPath)
	if err != nil {
		slog.Warn("Could not load host config, using deny-all default", "error", err)
		hostCfg = &HostConfig{DefaultPolicy: "deny"}
	}

	wsMaps := make(map[string]string)
	for _, m := range cfg.WorkspaceMaps {
		parts := strings.SplitN(m, ":", 2)
		if len(parts) == 2 {
			wsMaps[parts[0]] = parts[1]
		}
	}

	mux := http.NewServeMux()
	s := &Server{
		cfg:           cfg,
		keyManager:    km,
		hostConfig:    hostCfg,
		replay:        NewReplayGuard(30 * time.Second),
		mux:           mux,
		workspaceMaps: wsMaps,
	}

	mux.HandleFunc("GET /health", s.handleHealth)
	mux.HandleFunc("POST /execute", s.handleExecute)

	return s, nil
}

func (s *Server) ListenAndServe() error {
	socketPath := filepath.Join(s.cfg.SocketDir, "gate.sock")
	os.Remove(socketPath)

	listener, err := net.Listen("unix", socketPath)
	if err != nil {
		return fmt.Errorf("listen: %w", err)
	}

	if err := os.Chmod(socketPath, 0600); err != nil {
		return fmt.Errorf("chmod socket: %w", err)
	}

	slog.Info("Listening", "socket", socketPath)
	s.httpServer = &http.Server{Handler: s.mux}
	return s.httpServer.Serve(listener)
}

func (s *Server) Shutdown(ctx context.Context) error {
	if s.httpServer != nil {
		return s.httpServer.Shutdown(ctx)
	}
	return nil
}

// mapCwd translates a container working directory to a host path using workspace maps.
func (s *Server) mapCwd(containerCwd string) string {
	for containerPrefix, hostPrefix := range s.workspaceMaps {
		if strings.HasPrefix(containerCwd, containerPrefix) {
			suffix := strings.TrimPrefix(containerCwd, containerPrefix)
			return filepath.Join(hostPrefix, suffix)
		}
	}
	return containerCwd
}
