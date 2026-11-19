package sourcetypes

import (
	"github.com/mendahu/provenencia/core/database"
	"github.com/mendahu/provenencia/core/database/rowchange"
	"github.com/mendahu/provenencia/core/writes"
)

// upsert is sourcetypestest.Upsert, which this package's tests cannot import.
func upsert(c *database.Catalog, t Type) ([]byte, error) {
	return writes.Call(c, writes.Op{Action: "upsert_source_type"},
		func(tx *database.Tx) ([]byte, []rowchange.Change, error) {
			return UpsertTx(tx, t)
		})
}
