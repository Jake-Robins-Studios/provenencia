package propertyterms

import (
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
)

// upsert makes a term through the write pipeline, as the seed does.
func upsert(c *database.Catalog, t Term) ([]byte, error) {
	return writes.Call(c, writes.Op{Action: "upsert_property_term"},
		func(tx *database.Tx) ([]byte, []rowchange.Change, error) {
			return UpsertTx(tx, t)
		})
}
