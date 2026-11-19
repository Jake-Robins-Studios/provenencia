package sourcetypes

import (
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
)

// upsert is sourcetypestest.Upsert, which this package's tests cannot import.
func upsert(c *database.Catalog, t Type) ([]byte, error) {
	return writes.Call(c, writes.Op{Action: "upsert_source_type"},
		func(tx *database.Tx) ([]byte, []rowchange.Change, error) {
			return UpsertTx(tx, t, nil)
		})
}
