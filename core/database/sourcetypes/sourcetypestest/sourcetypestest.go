// Package sourcetypestest holds the Source type fixture for tests.
package sourcetypestest

import (
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
)

// Upsert inserts or updates a type by (key, origin) through the write pipeline.
func Upsert(c *database.Catalog, t sourcetypes.Type) ([]byte, error) {
	return writes.Call(c, writes.Op{Action: "upsert_source_type"},
		func(tx *database.Tx) ([]byte, []rowchange.Change, error) {
			return sourcetypes.UpsertTx(tx, t, nil)
		})
}
