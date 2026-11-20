// Package subjecttypestest holds the Subject type fixture for tests.
package subjecttypestest

import (
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjecttypes"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
)

// Upsert inserts or updates a type by (key, origin) through the write pipeline.
func Upsert(c *database.Catalog, t subjecttypes.Type) ([]byte, error) {
	return writes.Call(c, writes.Op{Action: "upsert_subject_type"},
		func(tx *database.Tx) ([]byte, []rowchange.Change, error) {
			return subjecttypes.UpsertTx(tx, t)
		})
}
