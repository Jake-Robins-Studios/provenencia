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

// SetFormats writes a type's citation formats through the write pipeline as
// the user, with the type's own label, description and icon, and returns the
// view, with the write's diagnostics.
func SetFormats(c *database.Catalog, userID, typeID []byte, in sourcetypes.Formats, choices ...sourcetypes.FieldChoice) (sourcetypes.FormatsView, error) {
	view, _, err := writes.Run(c, writes.Op{Action: "update_source_type", UserID: userID},
		func(tx *database.Tx) (sourcetypes.FormatsView, []rowchange.Change, error) {
			t, err := sourcetypes.GetByIDTx(tx.Tx, typeID)
			if err != nil {
				return sourcetypes.FormatsView{}, nil, err
			}
			_, view, changes, err := sourcetypes.UpdateWithFormats(tx, typeID, t.Label, t.Description, t.IconKey, in, choices)
			return view, changes, err
		})
	return view, err
}
