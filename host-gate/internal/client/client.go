package client

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"

	"github.com/ewout/host-gate/internal/protocol"
)

type SocketClient struct {
	socketPath string
	httpClient *http.Client
}

func NewSocketClient(socketPath string) *SocketClient {
	return &SocketClient{
		socketPath: socketPath,
		httpClient: &http.Client{
			Transport: &http.Transport{
				DialContext: func(ctx context.Context, _, _ string) (net.Conn, error) {
					return net.Dial("unix", socketPath)
				},
			},
		},
	}
}

func (c *SocketClient) Execute(req protocol.ExecuteRequest) (io.ReadCloser, int, error) {
	body, err := json.Marshal(req)
	if err != nil {
		return nil, 0, fmt.Errorf("marshal request: %w", err)
	}

	resp, err := c.httpClient.Post("http://host-gate/execute", "application/json", bytes.NewReader(body))
	if err != nil {
		return nil, 0, fmt.Errorf("send request: %w", err)
	}

	return resp.Body, resp.StatusCode, nil
}

func (c *SocketClient) Health() error {
	resp, err := c.httpClient.Get("http://host-gate/health")
	if err != nil {
		return fmt.Errorf("health check: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("health check returned status %d", resp.StatusCode)
	}
	return nil
}
