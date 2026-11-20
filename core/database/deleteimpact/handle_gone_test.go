package deleteimpact_test

import (
	"crypto/rand"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database/deleteimpact"
)

// A bridge-file delete can take any number of Subjects off one handle, past
// SQLite's 32,766 binds; the answer is the same as for a short list.
func TestHandleGoesWithoutAnyNumberLeaving(t *testing.T) {
	const padding = 33000
	type ids func(james, jim []byte) [][]byte
	none := func(_, _ []byte) [][]byte { return nil }
	tests := []struct {
		name          string
		before, after ids // before and after the padding
		padded        bool
		want          bool
	}{
		{"both members leave", func(james, jim []byte) [][]byte { return [][]byte{james, jim} }, none, false, true},
		{"both members leave among many", func(james, jim []byte) [][]byte { return [][]byte{james, jim} }, none, true, true},
		{"a member past the first batch leaves", func(james, _ []byte) [][]byte { return [][]byte{james} }, func(_, jim []byte) [][]byte { return [][]byte{jim} }, true, true},
		{"one member leaves", func(james, _ []byte) [][]byte { return [][]byte{james} }, none, false, false},
		{"one member leaves among many", func(james, _ []byte) [][]byte { return [][]byte{james} }, none, true, false},
		{"one member listed twice among many", func(james, _ []byte) [][]byte { return [][]byte{james} }, func(james, _ []byte) [][]byte { return [][]byte{james} }, true, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c, userID, james, jim, per := twoMemberFixture(t)
			mustClaim(t, c, userID, james, per)
			mustClaim(t, c, userID, jim, per)
			leaving := tt.before(james.ID, jim.ID)
			if tt.padded {
				for range padding {
					id := make([]byte, 16)
					_, _ = rand.Read(id)
					leaving = append(leaving, id)
				}
			}
			leaving = append(leaving, tt.after(james.ID, jim.ID)...)
			db, err := c.DB()
			if err != nil {
				t.Fatal(err)
			}
			tx, err := db.Begin()
			if err != nil {
				t.Fatal(err)
			}
			defer func() { _ = tx.Rollback() }()
			got, err := deleteimpact.HandleGoesWithout(tx, per.ID, leaving)
			if err != nil {
				t.Fatal(err)
			}
			if got != tt.want {
				t.Fatalf("goes %v, want %v", got, tt.want)
			}
		})
	}
}
