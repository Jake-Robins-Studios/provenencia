package subjectvocab

import (
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
)

// install is subjectvocabtest.Install, which this package's tests cannot import.
func install(c *database.Catalog) error {
	_, err := writes.RunChanges(c, writes.Op{Action: ActionInstall}, func(tx *database.Tx) ([]rowchange.Change, error) {
		return Install(tx)
	})
	return err
}
