// Package sourcecredibilitygradestest holds the credibility grade seed fixture
// for tests.
package sourcecredibilitygradestest

import (
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcecredibilitygrades"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
)

// Install writes the grade seed in one write, as catalog creation does.
func Install(c *database.Catalog) error {
	_, err := writes.Call(c, writes.Op{Action: sourcecredibilitygrades.ActionInstall}, func(tx *database.Tx) (struct{}, []rowchange.Change, error) {
		changes, err := sourcecredibilitygrades.Install(tx)
		return struct{}{}, changes, err
	})
	return err
}
