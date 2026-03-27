package client

import (
	"os"
	"path/filepath"
	"testing"
)

func TestLoadConfig(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "host-gate.json")
	os.WriteFile(path, []byte(`{
		"rules": [
			{"match": ["git", "push"], "execution": "proxy", "approval": "popup"}
		]
	}`), 0644)

	cfg, err := LoadConfig(path)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(cfg.Rules) != 1 {
		t.Fatalf("expected 1 rule, got %d", len(cfg.Rules))
	}
}

func TestMatchRuleLongestPrefix(t *testing.T) {
	cfg := Config{
		Rules: []Rule{
			{Match: []string{"git", "push"}, Execution: "proxy", Approval: "popup"},
			{Match: []string{"git", "push", "--force"}, Execution: "proxy", Approval: "yubikey"},
		},
	}

	rule := cfg.MatchRule("git", []string{"push", "--force", "origin"})
	if rule == nil {
		t.Fatal("expected a match")
	}
	if rule.Approval != "yubikey" {
		t.Fatalf("expected yubikey, got %s", rule.Approval)
	}
}

func TestMatchRuleFallsBackToShorterMatch(t *testing.T) {
	cfg := Config{
		Rules: []Rule{
			{Match: []string{"git", "push"}, Execution: "proxy", Approval: "popup"},
			{Match: []string{"git", "push", "--force"}, Execution: "proxy", Approval: "yubikey"},
		},
	}

	rule := cfg.MatchRule("git", []string{"push", "--force-with-lease"})
	if rule == nil {
		t.Fatal("expected a match")
	}
	if rule.Approval != "popup" {
		t.Fatalf("expected popup (git push match, not git push --force), got %s", rule.Approval)
	}
}

func TestMatchRuleNoMatch(t *testing.T) {
	cfg := Config{
		Rules: []Rule{
			{Match: []string{"git", "push"}, Execution: "proxy", Approval: "popup"},
		},
	}

	rule := cfg.MatchRule("npm", []string{"install"})
	if rule != nil {
		t.Fatal("expected no match")
	}
}

func TestUniqueBaseCommands(t *testing.T) {
	cfg := Config{
		Rules: []Rule{
			{Match: []string{"git", "push"}, Execution: "proxy", Approval: "popup"},
			{Match: []string{"git", "push", "--force"}, Execution: "proxy", Approval: "yubikey"},
			{Match: []string{"npm", "publish"}, Execution: "proxy", Approval: "yubikey"},
		},
	}

	cmds := cfg.UniqueBaseCommands()
	if len(cmds) != 2 {
		t.Fatalf("expected 2 unique commands, got %d: %v", len(cmds), cmds)
	}

	found := make(map[string]bool)
	for _, c := range cmds {
		found[c] = true
	}
	if !found["git"] || !found["npm"] {
		t.Fatalf("expected git and npm, got %v", cmds)
	}
}
