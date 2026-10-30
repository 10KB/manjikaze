package client

import (
	"encoding/json"
	"os"
)

type Config struct {
	Rules []Rule `json:"rules"`
}

type Rule struct {
	Match     []string `json:"match"`
	Execution string   `json:"execution"`
	Approval  string   `json:"approval"`
}

func LoadConfig(path string) (*Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var cfg Config
	if err := json.Unmarshal(data, &cfg); err != nil {
		return nil, err
	}
	return &cfg, nil
}

func (c *Config) MatchRule(command string, args []string) *Rule {
	fullCmd := make([]string, 0, 1+len(args))
	fullCmd = append(fullCmd, command)
	fullCmd = append(fullCmd, args...)

	var bestMatch *Rule
	bestLen := 0
	for i, rule := range c.Rules {
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
			bestMatch = &c.Rules[i]
			bestLen = len(rule.Match)
		}
	}
	return bestMatch
}

// UniqueBaseCommands returns the set of unique first elements from all rule matches.
func (c *Config) UniqueBaseCommands() []string {
	seen := make(map[string]bool)
	var cmds []string
	for _, rule := range c.Rules {
		if len(rule.Match) > 0 && !seen[rule.Match[0]] {
			seen[rule.Match[0]] = true
			cmds = append(cmds, rule.Match[0])
		}
	}
	return cmds
}
