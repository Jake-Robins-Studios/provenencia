//go:build cgo

package databasetest_test

import (
	"strings"
	"testing"
	"time"

	"github.com/Jake-Robins-Studios/provenencia/core/database/databasetest"
)

func TestCollected(t *testing.T) {
	t.Run("setup runs before each read, untimed", func(t *testing.T) {
		var log strings.Builder
		sleeps := []time.Duration{6, 4, 2}
		i := 0
		d := databasetest.Collected(3,
			func() { log.WriteString("s"); time.Sleep(30 * time.Millisecond) },
			func() { log.WriteString("r"); time.Sleep(sleeps[i] * time.Millisecond); i++ })
		if log.String() != "srsrsr" {
			t.Errorf("log = %q, want srsrsr", log.String())
		}
		if d >= 6*time.Millisecond {
			t.Errorf("Collected = %v, want the fastest read and not the setup", d)
		}
	})
	t.Run("a nil setup is none", func(t *testing.T) {
		var log strings.Builder
		databasetest.Collected(3, nil, func() { log.WriteString("r") })
		if log.String() != "rrr" {
			t.Errorf("log = %q, want rrr", log.String())
		}
	})
}
