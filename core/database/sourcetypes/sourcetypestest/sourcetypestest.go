// Package sourcetypestest holds the Source type fixture for tests.
package sourcetypestest

import (
	"github.com/mendahu/provenencia/core/database"
	"github.com/mendahu/provenencia/core/database/rowchange"
	"github.com/mendahu/provenencia/core/database/sourcetypes"
	"github.com/mendahu/provenencia/core/writes"
)

// Upsert inserts or updates a type by (key, origin) through the write pipeline.
func Upsert(c *database.Catalog, t sourcetypes.Type) ([]byte, error) {
	return writes.Call(c, writes.Op{Action: "upsert_source_type"},
		func(tx *database.Tx) ([]byte, []rowchange.Change, error) {
			return sourcetypes.UpsertTx(tx, t)
		})
}
