package daemon

import (
	"bufio"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"os/exec"
	"sync"

	"github.com/ewout/host-gate/internal/protocol"
)

func (s *Server) proxyExecute(
	ctx context.Context,
	w http.ResponseWriter,
	flusher http.Flusher,
	enc *json.Encoder,
	req protocol.ExecuteRequest,
) {
	hostCwd := req.HostCwd
	if hostCwd == "" {
		hostCwd = s.mapCwd(req.Cwd)
	}

	args := make([]string, len(req.Args))
	copy(args, req.Args)
	cmd := exec.CommandContext(ctx, req.Command, args...)
	cmd.Dir = hostCwd

	stdoutPipe, err := cmd.StdoutPipe()
	if err != nil {
		enc.Encode(protocol.StreamMsg{Type: "error", Message: err.Error()})
		flusher.Flush()
		return
	}
	stderrPipe, err := cmd.StderrPipe()
	if err != nil {
		enc.Encode(protocol.StreamMsg{Type: "error", Message: err.Error()})
		flusher.Flush()
		return
	}

	if err := cmd.Start(); err != nil {
		enc.Encode(protocol.StreamMsg{Type: "error", Message: err.Error()})
		flusher.Flush()
		return
	}

	var wg sync.WaitGroup
	streamPipe := func(pipe io.Reader, stream string) {
		defer wg.Done()
		scanner := bufio.NewScanner(pipe)
		for scanner.Scan() {
			enc.Encode(protocol.StreamMsg{
				Type:   "output",
				Stream: stream,
				Data:   scanner.Text() + "\n",
			})
			flusher.Flush()
		}
	}

	wg.Add(2)
	go streamPipe(stdoutPipe, "stdout")
	go streamPipe(stderrPipe, "stderr")
	wg.Wait()

	exitCode := 0
	if err := cmd.Wait(); err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			exitCode = exitErr.ExitCode()
		}
	}

	enc.Encode(protocol.StreamMsg{Type: "exit", Code: exitCode})
	flusher.Flush()
}
