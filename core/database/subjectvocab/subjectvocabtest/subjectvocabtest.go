// Package subjectvocabtest holds test helpers for the Subject vocabulary: the
// seed and binding writes. The error-returning helpers keep the signatures of
// the product functions they replaced, beside Assign, which fails the test
// itself.
package subjectvocabtest

import (
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjectvocab"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
)

// Assign binds a Property to the end of a type's order through writes.Call, as
// the assign RPC does, and fails the test on error.
func Assign(t testing.TB, c *database.Catalog, userID, typeID, propertyID []byte) {
	t.Helper()
	if _, err := writes.Call(c, writes.Op{Action: subjectvocab.ActionAssign, UserID: userID},
		func(tx *database.Tx) (struct{}, []rowchange.Change, error) {
			changes, err := subjectvocab.AppendBinding(tx, userID, typeID, propertyID)
			return struct{}{}, changes, err
		}); err != nil {
		t.Fatal(err)
	}
}

// Install writes the Subject vocabulary seed in one audited write, as catalog
// creation does.
func Install(c *database.Catalog) error {
	_, err := writes.Call(c, writes.Op{Action: subjectvocab.ActionInstall}, func(tx *database.Tx) (struct{}, []rowchange.Change, error) {
		changes, err := subjectvocab.Install(tx)
		return struct{}{}, changes, err
	})
	return err
}

// EnsureBinding sets a binding's sort_order through the write pipeline: it
// inserts the pair or moves it to sortOrder.
func EnsureBinding(c *database.Catalog, typeID, propertyID []byte, sortOrder int) error {
	_, err := writes.Call(c, writes.Op{Action: "ensure_subject_type_property"}, func(tx *database.Tx) (struct{}, []rowchange.Change, error) {
		changes, err := subjectvocab.EnsureBindingTx(tx, typeID, propertyID, sortOrder)
		return struct{}{}, changes, err
	})
	return err
}
