// Package metadatafieldstest holds the metadata field fixture for tests.
package metadatafieldstest

import (
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
)

// Upsert inserts or updates a field by (key, origin) through the write pipeline.
func Upsert(c *database.Catalog, f metadatafields.Field) ([]byte, error) {
	return writes.Call(c, writes.Op{Action: "upsert_metadata_field"},
		func(tx *database.Tx) ([]byte, []rowchange.Change, error) {
			return metadatafields.UpsertTx(tx, f)
		})
}
