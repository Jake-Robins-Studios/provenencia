package propertyterms

import (
	"database/sql"
	"errors"
	"reflect"
	"sort"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/apperr"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/properties"
	"github.com/Jake-Robins-Studios/provenencia/core/database/properties/propertiestest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/users"
	"github.com/Jake-Robins-Studios/provenencia/core/propertymeta"
	"github.com/Jake-Robins-Studios/provenencia/core/ref"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
)

func runCreate(c *database.Catalog, userID, propID []byte, label, description string) (Term, error) {
	term, _, err := writes.Run(c, writes.Op{Action: "create_property_term", UserID: userID},
		func(tx *database.Tx) (Term, []rowchange.Change, error) {
			return Create(tx, userID, propID, label, description)
		})
	return term, err
}

func runUpdate(c *database.Catalog, userID, id []byte, label, description string) (Term, error) {
	term, _, err := writes.Run(c, writes.Op{Action: "update_property_term", UserID: userID},
		func(tx *database.Tx) (Term, []rowchange.Change, error) {
			return Update(tx, userID, id, label, description)
		})
	return term, err
}

func runDelete(c *database.Catalog, userID, id []byte) error {
	_, _, err := writes.Run(c, writes.Op{Action: "delete_property_term", UserID: userID},
		func(tx *database.Tx) (struct{}, []rowchange.Change, error) {
			changes, err := Delete(tx, userID, id)
			return struct{}{}, changes, err
		})
	return err
}

func TestPropertyTerms(t *testing.T) {
	tests := []struct {
		name string
		run  func(t *testing.T, c *database.Catalog, userID, propID []byte)
	}{
		{
			name: "migration creates property_terms table",
			run: func(t *testing.T, c *database.Catalog, _, _ []byte) {
				db, err := c.DB()
				if err != nil {
					t.Fatal(err)
				}
				var name string
				if err := db.QueryRow(
					`SELECT name FROM sqlite_schema WHERE type='table' AND name='property_terms'`,
				).Scan(&name); err != nil || name != "property_terms" {
					t.Fatalf("table %q %v", name, err)
				}
				var ver int
				if err := db.QueryRow(`PRAGMA user_version`).Scan(&ver); err != nil {
					t.Fatal(err)
				}
				if ver < 24 {
					t.Fatalf("user_version=%d", ver)
				}
			},
		},
		{
			name: "upsert lookup list",
			run: func(t *testing.T, c *database.Catalog, _, propID []byte) {
				id, err := upsert(c, Term{
					PropertyID: propID, Key: "birth", Origin: vocabkey.OriginProvenencia, Label: "Birth",
				})
				if err != nil {
					t.Fatal(err)
				}
				got, err := Lookup(c, propID, "birth", vocabkey.OriginProvenencia)
				if err != nil {
					t.Fatal(err)
				}
				if string(got.ID) != string(id) || got.Label != "Birth" {
					t.Fatalf("got %+v", got)
				}
				list, err := ListByProperty(c, propID)
				if err != nil || len(list) != 1 {
					t.Fatalf("%v len=%d", err, len(list))
				}
			},
		},
		{
			name: "create update delete user term",
			run: func(t *testing.T, c *database.Catalog, userID, propID []byte) {
				got, err := runCreate(c, userID, propID, "Land Grant", "custom")
				if err != nil {
					t.Fatal(err)
				}
				if got.Key != "land-grant" || got.Origin != vocabkey.OriginUser {
					t.Fatalf("got %+v", got)
				}
				updated, err := runUpdate(c, userID, got.ID, "Land Grant 2", "")
				if err != nil {
					t.Fatal(err)
				}
				if updated.Label != "Land Grant 2" {
					t.Fatalf("label %q", updated.Label)
				}
				if err := runDelete(c, userID, got.ID); err != nil {
					t.Fatal(err)
				}
				_, err = GetByID(c, got.ID)
				if !errors.Is(err, sql.ErrNoRows) {
					t.Fatalf("after delete %v", err)
				}
			},
		},
		{
			name: "refuse mutate product term",
			run: func(t *testing.T, c *database.Catalog, userID, propID []byte) {
				id, err := upsert(c, Term{
					PropertyID: propID, Key: "death", Origin: vocabkey.OriginProvenencia, Label: "Death",
				})
				if err != nil {
					t.Fatal(err)
				}
				if _, err := runUpdate(c, userID, id, "X", ""); !errors.Is(err, ErrLocked) {
					t.Fatalf("update %v", err)
				}
				if err := runDelete(c, userID, id); !errors.Is(err, ErrLocked) {
					t.Fatalf("delete %v", err)
				}
			},
		},
		{
			name: "property delete refused while term exists",
			run: func(t *testing.T, c *database.Catalog, userID, propID []byte) {
				if _, err := runCreate(c, userID, propID, "Land Grant", ""); err != nil {
					t.Fatal(err)
				}
				db, err := c.DB()
				if err != nil {
					t.Fatal(err)
				}
				if _, err := db.Exec(`DELETE FROM properties WHERE id = ?`, propID); err == nil {
					t.Fatal("expected property delete to fail while a term remains")
				}
				got, err := properties.GetByID(c, propID)
				if err != nil || string(got.ID) != string(propID) {
					t.Fatalf("property %v %+v", err, got)
				}
				list, err := ListByProperty(c, propID)
				if err != nil || len(list) != 1 {
					t.Fatalf("terms %v len=%d", err, len(list))
				}
			},
		},
		{
			name: "duplicate user key",
			run: func(t *testing.T, c *database.Catalog, userID, propID []byte) {
				if _, err := runCreate(c, userID, propID, "Dup", ""); err != nil {
					t.Fatal(err)
				}
				_, err := runCreate(c, userID, propID, "Dup", "")
				wantDuplicate(t, err, "Dup")
			},
		},
		{
			name: "create refuses a term that reads like an existing one",
			run: func(t *testing.T, c *database.Catalog, userID, propID []byte) {
				if _, err := runCreate(c, userID, propID, "Godfather", ""); err != nil {
					t.Fatal(err)
				}
				if _, err := upsert(c, Term{PropertyID: propID, Key: "godparent", Origin: vocabkey.OriginProvenencia, Label: "Godparent"}); err != nil {
					t.Fatal(err)
				}
				if _, err := runCreate(c, userID, propID, "Café", ""); err != nil {
					t.Fatal(err)
				}
				if _, err := runCreate(c, userID, propID, "A+B", ""); err != nil {
					t.Fatal(err)
				}
				for _, tc := range []struct{ label, want string }{
					{"god-father", "Godfather"},
					{"God Parent", "Godparent"},
					{"Cafe", "Café"},
					{"A B", "A+B"},
				} {
					_, err := runCreate(c, userID, propID, tc.label, "")
					wantDuplicate(t, err, tc.want)
				}
				list, err := ListByProperty(c, propID)
				if err != nil || len(list) != 4 {
					t.Fatalf("no row written for a refused term: %v len=%d", err, len(list))
				}
				if _, err := runCreate(c, userID, propID, "Godmother", ""); err != nil {
					t.Fatalf("a different term is created: %v", err)
				}
			},
		},
		{
			name: "a label with no letters or digits is invalid",
			run: func(t *testing.T, c *database.Catalog, userID, propID []byte) {
				if _, err := runCreate(c, userID, propID, "!!!", ""); !errors.Is(err, ErrInvalid) {
					t.Fatalf("create !!!: want ErrInvalid, got %v", err)
				}
				term, err := runCreate(c, userID, propID, "Godfather", "")
				if err != nil {
					t.Fatal(err)
				}
				if _, err := runUpdate(c, userID, term.ID, "!!!", ""); !errors.Is(err, ErrInvalid) {
					t.Fatalf("update to !!!: want ErrInvalid, got %v", err)
				}
				got, err := GetByID(c, term.ID)
				if err != nil || got.Label != "Godfather" {
					t.Fatalf("label changed: %v %+v", err, got)
				}
			},
		},
		{
			name: "update refuses a rename onto another term and allows a restyle",
			run: func(t *testing.T, c *database.Catalog, userID, propID []byte) {
				father, err := runCreate(c, userID, propID, "Godfather", "")
				if err != nil {
					t.Fatal(err)
				}
				mother, err := runCreate(c, userID, propID, "Godmother", "")
				if err != nil {
					t.Fatal(err)
				}
				_, err = runUpdate(c, userID, mother.ID, "GODFATHER", "")
				wantDuplicate(t, err, "Godfather")
				got, err := GetByID(c, mother.ID)
				if err != nil || got.Label != "Godmother" {
					t.Fatalf("label changed: %v %+v", err, got)
				}
				if _, err := runUpdate(c, userID, father.ID, "God-Father", ""); err != nil {
					t.Fatalf("a term is never its own duplicate: %v", err)
				}
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c, err := database.Create(t.TempDir(), "t.provenencia")
			if err != nil {
				t.Fatal(err)
			}
			defer c.Close()
			userID := []byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
			r, err := ref.Mint(ref.PrefixUser)
			if err != nil {
				t.Fatal(err)
			}
			if err := users.Upsert(c, userID, "Tester", r); err != nil {
				t.Fatal(err)
			}
			propID, err := propertiestest.Upsert(c, properties.Property{
				Key: "event_type", Origin: vocabkey.OriginProvenencia,
				Label: "Event type", ValueType: propertymeta.ValueTypeTerm,
			})
			if err != nil {
				t.Fatal(err)
			}
			tt.run(t, c, userID, propID)
		})
	}
}

// wantDuplicate fails unless err is ErrDuplicateKey naming the existing term's label.
func wantDuplicate(t *testing.T, err error, label string) {
	t.Helper()
	var ae *apperr.Error
	if !errors.Is(err, ErrDuplicateKey) || !errors.As(err, &ae) || !reflect.DeepEqual(ae.Params(), []string{label}) {
		t.Fatalf("want ErrDuplicateKey [%s], got %v", label, err)
	}
}

// upsertChanges is upsert with the changes it returns.
func upsertChanges(c *database.Catalog, t Term) ([]byte, []rowchange.Change, error) {
	var changes []rowchange.Change
	id, err := writes.Call(c, writes.Op{Action: "upsert_property_term"}, func(tx *database.Tx) ([]byte, []rowchange.Change, error) {
		id, cs, err := UpsertTx(tx, t)
		changes = cs
		return id, cs, err
	})
	return id, changes, err
}

func fieldKeys(ch rowchange.Change) []string {
	var keys []string
	for k := range ch.Fields {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}

func TestUpsertTx(t *testing.T) {
	c, err := database.Create(t.TempDir(), "t.provenencia")
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()
	propID, err := propertiestest.Upsert(c, properties.Property{Key: "kin", Origin: vocabkey.OriginProvenencia, Label: "Kin", ValueType: propertymeta.ValueTypeTerm})
	if err != nil {
		t.Fatal(err)
	}
	parent := Term{PropertyID: propID, Key: "parent", Origin: vocabkey.OriginProvenencia, Label: "Parent", Directed: true, InverseKey: "child"}

	id, changes, err := upsertChanges(c, parent)
	if err != nil || len(changes) != 1 {
		t.Fatalf("create: %v %+v", err, changes)
	}
	ch := changes[0]
	if ch.EntityType != "property_term" || ch.Action != rowchange.ActionCreate ||
		!reflect.DeepEqual(fieldKeys(ch), []string{"directed", "id", "inverse_key", "key", "label", "origin", "property_id"}) ||
		ch.Fields["directed"].New != true || ch.Fields["inverse_key"].New != "child" {
		t.Fatalf("create change %+v", ch)
	}
	got, err := GetByID(c, id)
	if err != nil || !got.Directed || got.InverseKey != "child" || got.Neutral {
		t.Fatalf("stored %v %+v", err, got)
	}

	if _, changes, err = upsertChanges(c, parent); err != nil || len(changes) != 0 {
		t.Fatalf("same: %v %+v", err, changes)
	}

	neutral := parent
	neutral.Neutral = true
	_, changes, err = upsertChanges(c, neutral)
	if err != nil || len(changes) != 1 || changes[0].Action != rowchange.ActionUpdate ||
		!reflect.DeepEqual(fieldKeys(changes[0]), []string{"neutral"}) {
		t.Fatalf("neutral: %v %+v", err, changes)
	}
	if d := changes[0].Fields["neutral"]; d.Old != nil || d.New != true {
		t.Fatalf("neutral diff %+v", d)
	}
	if got, err = GetByID(c, id); err != nil || !got.Neutral {
		t.Fatalf("neutral stored %v %+v", err, got)
	}

	base := Term{PropertyID: propID, Key: "x", Origin: vocabkey.OriginProvenencia, Label: "X"}
	bad := map[string]Term{}
	for name, mutate := range map[string]func(*Term){
		"blank key":         func(t *Term) { t.Key = "" },
		"blank label":       func(t *Term) { t.Label = "" },
		"bogus origin":      func(t *Term) { t.Origin = "bogus" },
		"short property id": func(t *Term) { t.PropertyID = propID[:8] },
		"non-empty ID":      func(t *Term) { t.ID = make([]byte, 16) },
	} {
		term := base
		mutate(&term)
		bad[name] = term
	}
	for name, term := range bad {
		if _, _, err := upsertChanges(c, term); !errors.Is(err, ErrInvalid) {
			t.Fatalf("%s: got %v", name, err)
		}
	}
}

// TestChangeKeys pins the audit keys of a researcher's term.
func TestChangeKeys(t *testing.T) {
	c, err := database.Create(t.TempDir(), "t.provenencia")
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()
	userID := []byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
	r, err := ref.Mint(ref.PrefixUser)
	if err != nil {
		t.Fatal(err)
	}
	if err := users.Upsert(c, userID, "Tester", r); err != nil {
		t.Fatal(err)
	}
	propID, err := propertiestest.Upsert(c, properties.Property{Key: "role", Origin: vocabkey.OriginProvenencia, Label: "Role", ValueType: propertymeta.ValueTypeTerm})
	if err != nil {
		t.Fatal(err)
	}
	var created, updated, deleted []rowchange.Change
	term, err := writes.Call(c, writes.Op{Action: "create_property_term", UserID: userID}, func(tx *database.Tx) (Term, []rowchange.Change, error) {
		got, cs, err := Create(tx, userID, propID, "Godfather", "note")
		created = cs
		return got, cs, err
	})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := writes.Call(c, writes.Op{Action: "update_property_term", UserID: userID}, func(tx *database.Tx) (Term, []rowchange.Change, error) {
		got, cs, err := Update(tx, userID, term.ID, "Godfather 2", "")
		updated = cs
		return got, cs, err
	}); err != nil {
		t.Fatal(err)
	}
	if _, err := writes.Call(c, writes.Op{Action: "delete_property_term", UserID: userID}, func(tx *database.Tx) (struct{}, []rowchange.Change, error) {
		cs, err := Delete(tx, userID, term.ID)
		deleted = cs
		return struct{}{}, cs, err
	}); err != nil {
		t.Fatal(err)
	}
	if len(created) != 1 || !reflect.DeepEqual(fieldKeys(created[0]), []string{"description", "id", "key", "label", "origin", "property_id"}) {
		t.Fatalf("create keys %+v", created)
	}
	if len(updated) != 1 || !reflect.DeepEqual(fieldKeys(updated[0]), []string{"description", "label"}) {
		t.Fatalf("update keys %+v", updated)
	}
	if len(deleted) != 1 || !reflect.DeepEqual(fieldKeys(deleted[0]), []string{"id", "key", "label", "origin", "property_id"}) {
		t.Fatalf("delete keys %+v", deleted)
	}
}
