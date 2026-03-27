package main

import (
	"fmt"
	"os"

	"github.com/ewout/host-gate/internal/client"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "Usage: host-gate-client <exec|setup> [args...]")
		os.Exit(1)
	}

	switch os.Args[1] {
	case "exec":
		if len(os.Args) < 3 {
			fmt.Fprintln(os.Stderr, "Usage: host-gate-client exec <command> [args...]")
			os.Exit(1)
		}
		if err := client.ExecCommand(os.Args[2], os.Args[3:]); err != nil {
			fmt.Fprintf(os.Stderr, "\033[31m[host-gate] %s\033[0m\n", err)
			os.Exit(1)
		}
	case "setup":
		configPath := "/workspace/.devcontainer/host-gate.json"
		for i, arg := range os.Args[2:] {
			if arg == "--config" && i+1 < len(os.Args[2:]) {
				configPath = os.Args[2:][i+1]
			}
		}
		if err := client.Setup(configPath); err != nil {
			fmt.Fprintf(os.Stderr, "host-gate setup failed: %s\n", err)
			os.Exit(1)
		}
	default:
		fmt.Fprintf(os.Stderr, "Unknown subcommand: %s\nUsage: host-gate-client <exec|setup> [args...]\n", os.Args[1])
		os.Exit(1)
	}
}
