package client

import (
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
)

func Setup(configPath string) error {
	cfg, err := LoadConfig(configPath)
	if err != nil {
		return fmt.Errorf("load config: %w", err)
	}

	wrapperDir := "/usr/local/lib/host-gate/bin"
	if err := os.MkdirAll(wrapperDir, 0755); err != nil {
		return fmt.Errorf("create wrapper dir: %w", err)
	}

	commands := cfg.UniqueBaseCommands()

	for _, cmd := range commands {
		wrapperPath := filepath.Join(wrapperDir, cmd)
		wrapperContent := fmt.Sprintf("#!/bin/sh\nexec host-gate-client exec %s \"$@\"\n", cmd)
		if err := os.WriteFile(wrapperPath, []byte(wrapperContent), 0755); err != nil {
			return fmt.Errorf("write wrapper for %s: %w", cmd, err)
		}
		slog.Info("Created wrapper", "command", cmd, "path", wrapperPath)
	}

	profileScript := fmt.Sprintf("export PATH=%s:$PATH\n", wrapperDir)
	if err := os.WriteFile("/etc/profile.d/host-gate.sh", []byte(profileScript), 0644); err != nil {
		slog.Warn("Could not write /etc/profile.d/host-gate.sh", "error", err)
	}

	appendToFile("/etc/bash.bashrc", profileScript)

	if err := os.MkdirAll("/etc/zsh", 0755); err == nil {
		appendToFile("/etc/zsh/zshenv", profileScript)
	}

	slog.Info("Setup complete", "commands", commands)
	return nil
}

func appendToFile(path, content string) {
	f, err := os.OpenFile(path, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return
	}
	defer f.Close()

	existing, _ := os.ReadFile(path)
	if len(existing) > 0 {
		// Avoid duplicate entries
		for _, line := range splitLines(string(existing)) {
			if line == content || line+"\n" == content {
				return
			}
		}
	}

	f.WriteString(content)
}

func splitLines(s string) []string {
	var lines []string
	start := 0
	for i := 0; i < len(s); i++ {
		if s[i] == '\n' {
			lines = append(lines, s[start:i])
			start = i + 1
		}
	}
	if start < len(s) {
		lines = append(lines, s[start:])
	}
	return lines
}
