package daemon

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"
)

type HostConfig struct {
	DefaultPolicy string     `json:"defaultPolicy"`
	Rules         []HostRule `json:"rules"`
}

type HostRule struct {
	Match        []string `json:"match"`
	Allow        bool     `json:"allow"`
	MinApproval  string   `json:"minApproval,omitempty"`
	MinExecution string   `json:"minExecution,omitempty"`
}

func LoadHostConfig(path string) (*HostConfig, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	cleaned := stripJSONComments(string(data))
	var cfg HostConfig
	if err := json.Unmarshal([]byte(cleaned), &cfg); err != nil {
		return nil, fmt.Errorf("parse host config: %w", err)
	}
	return &cfg, nil
}

// stripJSONComments removes // line comments and trailing commas to allow
// JSONC-style configs that are easy to hand-edit.
func stripJSONComments(s string) string {
	var b strings.Builder
	for _, line := range strings.Split(s, "\n") {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "//") {
			continue
		}
		b.WriteString(line)
		b.WriteByte('\n')
	}
	return stripTrailingCommas(b.String())
}

func stripTrailingCommas(s string) string {
	var b strings.Builder
	b.Grow(len(s))
	inString := false
	escaped := false
	for i := 0; i < len(s); i++ {
		ch := s[i]
		if inString {
			b.WriteByte(ch)
			if escaped {
				escaped = false
			} else if ch == '\\' {
				escaped = true
			} else if ch == '"' {
				inString = false
			}
			continue
		}
		if ch == '"' {
			inString = true
			b.WriteByte(ch)
			continue
		}
		if ch == ',' {
			j := i + 1
			for j < len(s) && (s[j] == ' ' || s[j] == '\t' || s[j] == '\n' || s[j] == '\r') {
				j++
			}
			if j < len(s) && (s[j] == ']' || s[j] == '}') {
				continue
			}
		}
		b.WriteByte(ch)
	}
	return b.String()
}

func (hc *HostConfig) MatchRule(command string, args []string) *HostRule {
	fullCmd := make([]string, 0, 1+len(args))
	fullCmd = append(fullCmd, command)
	fullCmd = append(fullCmd, args...)

	var bestMatch *HostRule
	bestLen := 0
	for i, rule := range hc.Rules {
		if len(rule.Match) > len(fullCmd) {
			continue
		}
		match := true
		for j, part := range rule.Match {
			if part != fullCmd[j] {
				match = false
				break
			}
		}
		if match && len(rule.Match) > bestLen {
			bestMatch = &hc.Rules[i]
			bestLen = len(rule.Match)
		}
	}
	return bestMatch
}

// ApplyPolicy checks the host policy and returns the effective execution/approval modes.
// Returns an error if the command is denied.
func (hc *HostConfig) ApplyPolicy(command string, args []string, reqExecution, reqApproval string) (string, string, error) {
	rule := hc.MatchRule(command, args)

	if rule == nil {
		if hc.DefaultPolicy == "allow" {
			return reqExecution, reqApproval, nil
		}
		return "", "", fmt.Errorf("command not allowed by host policy (no matching rule, default: deny)")
	}

	if !rule.Allow {
		return "", "", fmt.Errorf("command explicitly denied by host policy")
	}

	execution := reqExecution
	if modeRank(rule.MinExecution) > modeRank(execution) {
		execution = rule.MinExecution
	}

	approval := reqApproval
	if modeRank(rule.MinApproval) > modeRank(approval) {
		approval = rule.MinApproval
	}

	return execution, approval, nil
}

// modeRank returns the restrictiveness rank of a mode.
// Approval: none(0) < popup(1) < yubikey(2)
// Execution: local(0) < proxy(1)
func modeRank(mode string) int {
	switch mode {
	case "none", "":
		return 0
	case "local", "popup":
		return 1
	case "proxy", "yubikey":
		return 2
	default:
		return 0
	}
}
