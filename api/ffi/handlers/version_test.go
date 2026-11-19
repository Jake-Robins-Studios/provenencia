package handlers

import (
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/api/proto/engine"
	"github.com/Jake-Robins-Studios/provenencia/core"
)

func TestGetVersion(t *testing.T) {
	runRPC(t, GetVersion, []rpcTest{
		{name: "matches core.Version", req: &engine.GetVersionRequest{}, want: &engine.GetVersionResponse{Version: core.Version}},
		{name: "empty payload", want: &engine.GetVersionResponse{Version: core.Version}},
	})
}
