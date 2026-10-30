package client

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"syscall"
	"time"

	"github.com/ewout/host-gate/internal/protocol"
	"github.com/google/uuid"
)

func ExecCommand(command string, args []string) error {
	cfg, err := LoadConfig(configPath())
	if err != nil {
		return passthrough(command, args)
	}

	rule := cfg.MatchRule(command, args)
	if rule == nil {
		return passthrough(command, args)
	}

	nonce := uuid.New().String()
	timestamp := time.Now().Unix()
	cwd, _ := os.Getwd()

	req := protocol.ExecuteRequest{
		Version:   1,
		Nonce:     nonce,
		Timestamp: timestamp,
		Command:   command,
		Args:      args,
		Cwd:       cwd,
		HostCwd:   mapToHostCwd(cwd),
		Execution: rule.Execution,
		Approval:  rule.Approval,
	}

	key, err := os.ReadFile(hmacKeyPath())
	if err != nil {
		return fmt.Errorf("read HMAC key: %w (is host-gate daemon running?)", err)
	}
	req.HMAC = protocol.Sign(key, req.CanonicalString())

	client := NewSocketClient(socketPath())
	body, statusCode, err := client.Execute(req)
	if err != nil {
		return fmt.Errorf("host-gate request failed: %w", err)
	}
	defer body.Close()

	if statusCode != http.StatusOK {
		errBody, _ := io.ReadAll(body)
		return fmt.Errorf("host-gate daemon error (HTTP %d): %s", statusCode, strings.TrimSpace(string(errBody)))
	}

	return processStream(body, command, args, rule.Execution)
}

func processStream(resp io.Reader, command string, args []string, execution string) error {
	scanner := bufio.NewScanner(resp)
	for scanner.Scan() {
		var msg protocol.StreamMsg
		if err := json.Unmarshal(scanner.Bytes(), &msg); err != nil {
			continue
		}

		switch msg.Type {
		case "status":
			fmt.Fprintf(os.Stderr, "\033[2m[host-gate] %s\033[0m\n", msg.Message)
		case "approved":
			if execution == "local" {
				realPath, err := findRealBinary(command)
				if err != nil {
					return err
				}
				return syscall.Exec(realPath, append([]string{command}, args...), os.Environ())
			}
		case "denied":
			fmt.Fprintf(os.Stderr, "\033[31m[host-gate] Denied: %s\033[0m\n", msg.Message)
			os.Exit(1)
		case "output":
			if msg.Stream == "stdout" {
				fmt.Fprint(os.Stdout, msg.Data)
			} else {
				fmt.Fprint(os.Stderr, msg.Data)
			}
		case "exit":
			os.Exit(msg.Code)
		case "error":
			fmt.Fprintf(os.Stderr, "\033[31m[host-gate] Error: %s\033[0m\n", msg.Message)
			os.Exit(1)
		}
	}
	return nil
}

func passthrough(command string, args []string) error {
	realPath, err := findRealBinary(command)
	if err != nil {
		return err
	}
	return syscall.Exec(realPath, append([]string{command}, args...), os.Environ())
}

func findRealBinary(command string) (string, error) {
	wrapperDir := "/usr/local/lib/host-gate/bin"
	paths := strings.Split(os.Getenv("PATH"), ":")
	for _, dir := range paths {
		if dir == wrapperDir {
			continue
		}
		candidate := filepath.Join(dir, command)
		if info, err := os.Stat(candidate); err == nil && !info.IsDir() {
			if info.Mode()&0111 != 0 {
				return candidate, nil
			}
		}
	}
	return "", fmt.Errorf("real binary not found: %s", command)
}

func mapToHostCwd(containerCwd string) string {
	hostWs := os.Getenv("HOST_GATE_HOST_WORKSPACE")
	containerWs := os.Getenv("HOST_GATE_CONTAINER_WORKSPACE")
	if hostWs == "" || containerWs == "" {
		return ""
	}
	if strings.HasPrefix(containerCwd, containerWs) {
		suffix := strings.TrimPrefix(containerCwd, containerWs)
		return filepath.Join(hostWs, suffix)
	}
	return ""
}

func configPath() string {
	if p := os.Getenv("HOST_GATE_CONFIG"); p != "" {
		return p
	}
	return "/workspace/.devcontainer/host-gate.json"
}

func hmacKeyPath() string {
	if p := os.Getenv("HOST_GATE_HMAC_KEY"); p != "" {
		return p
	}
	return "/var/run/host-gate/hmac.key"
}

func socketPath() string {
	if p := os.Getenv("HOST_GATE_SOCKET"); p != "" {
		return p
	}
	return "/var/run/host-gate/gate.sock"
}
