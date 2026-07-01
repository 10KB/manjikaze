package daemon

import (
	"context"
	crypto_rand "crypto/rand"
	"encoding/hex"
	"fmt"
	"os/exec"
	"strconv"
	"strings"
)

func (s *Server) requireYubiKeyTouch(ctx context.Context) error {
	challenge := make([]byte, 32)
	if _, err := crypto_rand.Read(challenge); err != nil {
		return fmt.Errorf("generate challenge: %w", err)
	}
	challengeHex := hex.EncodeToString(challenge)

	ctx, cancel := context.WithTimeout(ctx, s.cfg.YubiKeyTimeout)
	defer cancel()

	cmd := exec.CommandContext(ctx, "ykman", "otp", "calculate",
		strconv.Itoa(s.cfg.YubiKeySlot),
		challengeHex,
	)

	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("yubikey challenge-response failed: %w (output: %s)", err, string(output))
	}

	response := strings.TrimSpace(string(output))
	if len(response) == 0 {
		return fmt.Errorf("empty yubikey response")
	}

	return nil
}
