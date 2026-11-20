// Package propertiestest holds the Property fixture for tests.
package propertiestest

import (
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/properties"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
)

// Upsert inserts or updates a Property by (key, origin) through the write pipeline.
func Upsert(c *database.Catalog, p properties.Property) ([]byte, error) {
	return writes.Call(c, writes.Op{Action: "upsert_property"},
		func(tx *database.Tx) ([]byte, []rowchange.Change, error) {
			return properties.UpsertTx(tx, p)
		})
}
