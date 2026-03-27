package daemon

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

func TestLoadHostConfigWithComments(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "policy.json")

	jsonc := `// This is a comment
// Another comment
{
  "defaultPolicy": "allow",
  "rules": [
    {
      // Rule for git push
      "match": ["git", "push"],
      "allow": true,
      "minApproval": "yubikey"
    }
  ]
}
`
	os.WriteFile(path, []byte(jsonc), 0644)

	loaded, err := LoadHostConfig(path)
	if err != nil {
		t.Fatalf("unexpected error parsing JSONC: %v", err)
	}
	if loaded.DefaultPolicy != "allow" {
		t.Fatalf("expected allow, got %s", loaded.DefaultPolicy)
	}
	if len(loaded.Rules) != 1 {
		t.Fatalf("expected 1 rule, got %d", len(loaded.Rules))
	}
	if loaded.Rules[0].MinApproval != "yubikey" {
		t.Fatalf("expected yubikey, got %s", loaded.Rules[0].MinApproval)
	}
}

func TestLoadHostConfigWithTrailingCommas(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "policy.json")

	jsonc := `{
  "defaultPolicy": "deny",
  "rules": [
    {
      "match": ["aws"],
      "allow": true,
      "minApproval": "popup",
      "minExecution": "proxy",
    },
  ],
}
`
	os.WriteFile(path, []byte(jsonc), 0644)

	loaded, err := LoadHostConfig(path)
	if err != nil {
		t.Fatalf("unexpected error parsing JSONC with trailing commas: %v", err)
	}
	if loaded.DefaultPolicy != "deny" {
		t.Fatalf("expected deny, got %s", loaded.DefaultPolicy)
	}
	if len(loaded.Rules) != 1 {
		t.Fatalf("expected 1 rule, got %d", len(loaded.Rules))
	}
	if loaded.Rules[0].Match[0] != "aws" {
		t.Fatalf("expected aws, got %s", loaded.Rules[0].Match[0])
	}
}

func TestLoadHostConfig(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "policy.json")

	cfg := HostConfig{
		DefaultPolicy: "deny",
		Rules: []HostRule{
			{Match: []string{"git", "push"}, Allow: true, MinApproval: "popup"},
		},
	}
	data, _ := json.Marshal(cfg)
	os.WriteFile(path, data, 0644)

	loaded, err := LoadHostConfig(path)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if loaded.DefaultPolicy != "deny" {
		t.Fatalf("expected deny, got %s", loaded.DefaultPolicy)
	}
	if len(loaded.Rules) != 1 {
		t.Fatalf("expected 1 rule, got %d", len(loaded.Rules))
	}
}

func TestMatchRuleLongestPrefix(t *testing.T) {
	cfg := HostConfig{
		Rules: []HostRule{
			{Match: []string{"git", "push"}, Allow: true, MinApproval: "popup"},
			{Match: []string{"git", "push", "--force"}, Allow: true, MinApproval: "yubikey"},
			{Match: []string{"git"}, Allow: true, MinApproval: "popup"},
		},
	}

	rule := cfg.MatchRule("git", []string{"push", "--force", "origin"})
	if rule == nil {
		t.Fatal("expected a match")
	}
	if rule.MinApproval != "yubikey" {
		t.Fatalf("expected yubikey (longest prefix match), got %s", rule.MinApproval)
	}

	rule = cfg.MatchRule("git", []string{"push", "origin"})
	if rule == nil {
		t.Fatal("expected a match")
	}
	if rule.MinApproval != "popup" {
		t.Fatalf("expected popup (git push match), got %s", rule.MinApproval)
	}

	rule = cfg.MatchRule("git", []string{"status"})
	if rule == nil {
		t.Fatal("expected a match for bare git")
	}
	if rule.MinApproval != "popup" {
		t.Fatalf("expected popup (bare git match), got %s", rule.MinApproval)
	}
}

func TestMatchRuleNoMatch(t *testing.T) {
	cfg := HostConfig{
		Rules: []HostRule{
			{Match: []string{"git", "push"}, Allow: true},
		},
	}

	rule := cfg.MatchRule("npm", []string{"publish"})
	if rule != nil {
		t.Fatal("expected no match for npm")
	}
}

func TestApplyPolicyDefaultDeny(t *testing.T) {
	cfg := HostConfig{DefaultPolicy: "deny"}

	_, _, err := cfg.ApplyPolicy("git", []string{"push"}, "proxy", "popup")
	if err == nil {
		t.Fatal("expected denial with no matching rule and default deny")
	}
}

func TestApplyPolicyDefaultAllow(t *testing.T) {
	cfg := HostConfig{DefaultPolicy: "allow"}

	exec, approval, err := cfg.ApplyPolicy("git", []string{"push"}, "proxy", "popup")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if exec != "proxy" || approval != "popup" {
		t.Fatalf("expected proxy/popup passthrough, got %s/%s", exec, approval)
	}
}

func TestApplyPolicyExplicitDeny(t *testing.T) {
	cfg := HostConfig{
		DefaultPolicy: "allow",
		Rules: []HostRule{
			{Match: []string{"kubectl", "delete"}, Allow: false},
		},
	}

	_, _, err := cfg.ApplyPolicy("kubectl", []string{"delete", "ns", "prod"}, "local", "popup")
	if err == nil {
		t.Fatal("expected explicit denial")
	}
}

func TestApplyPolicyEscalation(t *testing.T) {
	cfg := HostConfig{
		DefaultPolicy: "deny",
		Rules: []HostRule{
			{Match: []string{"git", "push"}, Allow: true, MinApproval: "yubikey", MinExecution: "proxy"},
		},
	}

	exec, approval, err := cfg.ApplyPolicy("git", []string{"push"}, "local", "popup")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if exec != "proxy" {
		t.Fatalf("expected escalation to proxy, got %s", exec)
	}
	if approval != "yubikey" {
		t.Fatalf("expected escalation to yubikey, got %s", approval)
	}
}

func TestApplyPolicyNoneApproval(t *testing.T) {
	cfg := HostConfig{
		DefaultPolicy: "deny",
		Rules: []HostRule{
			{Match: []string{"aws"}, Allow: true, MinApproval: "none", MinExecution: "proxy"},
		},
	}

	exec, approval, err := cfg.ApplyPolicy("aws", []string{"s3", "ls"}, "proxy", "none")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if exec != "proxy" {
		t.Fatalf("expected proxy, got %s", exec)
	}
	if approval != "none" {
		t.Fatalf("expected none, got %s", approval)
	}
}

func TestApplyPolicyNoneEscalatedByHost(t *testing.T) {
	cfg := HostConfig{
		DefaultPolicy: "deny",
		Rules: []HostRule{
			{Match: []string{"aws"}, Allow: true, MinApproval: "popup", MinExecution: "proxy"},
		},
	}

	exec, approval, err := cfg.ApplyPolicy("aws", []string{"s3", "ls"}, "proxy", "none")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if exec != "proxy" {
		t.Fatalf("expected proxy, got %s", exec)
	}
	if approval != "popup" {
		t.Fatalf("expected host to escalate none->popup, got %s", approval)
	}
}

func TestApplyPolicyNoDowngrade(t *testing.T) {
	cfg := HostConfig{
		DefaultPolicy: "deny",
		Rules: []HostRule{
			{Match: []string{"git", "push"}, Allow: true, MinApproval: "popup", MinExecution: "local"},
		},
	}

	exec, approval, err := cfg.ApplyPolicy("git", []string{"push"}, "proxy", "yubikey")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if exec != "proxy" {
		t.Fatalf("expected proxy to be preserved (more restrictive), got %s", exec)
	}
	if approval != "yubikey" {
		t.Fatalf("expected yubikey to be preserved (more restrictive), got %s", approval)
	}
}
