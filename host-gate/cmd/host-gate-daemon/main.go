package main

import (
	"context"
	"flag"
	"log/slog"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"

	"github.com/ewout/host-gate/internal/daemon"
)

func main() {
	socketDir := flag.String("socket-dir", "", "Socket directory (default: $XDG_RUNTIME_DIR/host-gate)")
	hostConfig := flag.String("host-config", "", "Host policy config (default: ~/.config/host-gate/policy.json)")
	approvalTimeout := flag.Duration("approval-timeout", 60*time.Second, "Timeout for user approval")
	yubikeySlot := flag.Int("yubikey-slot", 2, "YubiKey OTP slot for challenge-response")
	yubikeyTimeout := flag.Duration("yubikey-timeout", 30*time.Second, "Timeout for YubiKey touch")
	logLevel := flag.String("log-level", "info", "Log level: debug, info, warn, error")

	var workspaceMaps workspaceMapFlags
	flag.Var(&workspaceMaps, "workspace-map", "Container-to-host path mapping (e.g., /workspace:/home/user/project). Can be specified multiple times.")

	flag.Parse()

	configureLogging(*logLevel)

	if *socketDir == "" {
		xdgRuntime := os.Getenv("XDG_RUNTIME_DIR")
		if xdgRuntime == "" {
			slog.Error("XDG_RUNTIME_DIR not set and --socket-dir not provided")
			os.Exit(1)
		}
		*socketDir = filepath.Join(xdgRuntime, "host-gate")
	}

	if *hostConfig == "" {
		home, _ := os.UserHomeDir()
		*hostConfig = filepath.Join(home, ".config", "host-gate", "policy.json")
	}

	cfg := daemon.Config{
		SocketDir:       *socketDir,
		HostConfigPath:  *hostConfig,
		ApprovalTimeout: *approvalTimeout,
		YubiKeySlot:     *yubikeySlot,
		YubiKeyTimeout:  *yubikeyTimeout,
		WorkspaceMaps:   workspaceMaps,
	}

	srv, err := daemon.NewServer(cfg)
	if err != nil {
		slog.Error("Failed to create server", "error", err)
		os.Exit(1)
	}

	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sigCh
		slog.Info("Shutting down...")
		srv.Shutdown(context.Background())
	}()

	if err := srv.ListenAndServe(); err != nil {
		slog.Error("Server error", "error", err)
		os.Exit(1)
	}
}

type workspaceMapFlags []string

func (w *workspaceMapFlags) String() string { return "" }
func (w *workspaceMapFlags) Set(val string) error {
	*w = append(*w, val)
	return nil
}

func configureLogging(level string) {
	var lvl slog.Level
	switch level {
	case "debug":
		lvl = slog.LevelDebug
	case "warn":
		lvl = slog.LevelWarn
	case "error":
		lvl = slog.LevelError
	default:
		lvl = slog.LevelInfo
	}
	slog.SetDefault(slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{Level: lvl})))
}
