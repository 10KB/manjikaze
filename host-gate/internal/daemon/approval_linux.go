package daemon

import (
	"context"
	"fmt"
	"html"
	"os"
	"os/exec"
	"strings"

	"github.com/ewout/host-gate/internal/protocol"
)

func (s *Server) requestApproval(ctx context.Context, req protocol.ExecuteRequest) (bool, error) {
	fullCommand := req.Command + " " + strings.Join(req.Args, " ")
	title := "Host Gate: Command Approval"
	text := fmt.Sprintf(
		"A container requests to run:\n\n<b>%s</b>\n\nWorking directory: %s\nExecution: %s\nApproval: %s",
		html.EscapeString(fullCommand),
		html.EscapeString(req.Cwd),
		req.Execution,
		req.Approval,
	)

	ctx, cancel := context.WithTimeout(ctx, s.cfg.ApprovalTimeout)
	defer cancel()

	cmd := exec.CommandContext(ctx, "zenity",
		"--question",
		"--title", title,
		"--text", text,
		"--ok-label", "Allow",
		"--cancel-label", "Deny",
		"--icon-name", "dialog-warning",
		"--width", "450",
	)

	// Inherit graphical session environment
	cmd.Env = os.Environ()

	if err := cmd.Run(); err != nil {
		if _, ok := err.(*exec.ExitError); ok {
			return false, nil
		}
		return false, err
	}
	return true, nil
}
