// Package sourcevocabtest holds the Source seed fixture for tests.
package sourcevocabtest

import (
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcevocab"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
)

// Install writes the Source seed in one audited write, as catalog creation does.
func Install(c *database.Catalog) error {
	_, err := writes.Call(c, writes.Op{Action: sourcevocab.ActionInstall}, func(tx *database.Tx) (struct{}, []rowchange.Change, error) {
		changes, err := sourcevocab.Install(tx)
		return struct{}{}, changes, err
	})
	return err
}
