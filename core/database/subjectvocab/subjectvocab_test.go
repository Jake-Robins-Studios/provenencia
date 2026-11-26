package subjectvocab

import (
	"errors"
	"reflect"
	"slices"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/connectrules"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/dbtest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/properties"
	"github.com/Jake-Robins-Studios/provenencia/core/database/properties/propertiestest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/propertyterms"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjecttypes"
	"github.com/Jake-Robins-Studios/provenencia/core/database/users"
	"github.com/Jake-Robins-Studios/provenencia/core/propertymeta"
	"github.com/Jake-Robins-Studios/provenencia/core/ref"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
)

func TestSubjectVocab(t *testing.T) {
	tests := []struct {
		name string
		run  func(t *testing.T, c *database.Catalog)
	}{
		{
			name: "open does not heal deleted property",
			run: func(t *testing.T, c *database.Catalog) {
				if err := install(c); err != nil {
					t.Fatal(err)
				}
				prop, err := properties.Lookup(c, "remark", vocabkey.OriginProvenencia)
				if err != nil {
					t.Fatal(err)
				}
				// Unbind source.remark first so the Property can be deleted.
				srcType, err := subjecttypes.Lookup(c, "source", vocabkey.OriginProvenencia)
				if err != nil {
					t.Fatal(err)
				}
				if _, err := deleteBinding(t, c, testUser(t, c), srcType.ID, prop.ID); err != nil {
					t.Fatal(err)
				}
				db, err := c.DB()
				if err != nil {
					t.Fatal(err)
				}
				if _, err := db.Exec(`DELETE FROM properties WHERE id = ?`, prop.ID); err != nil {
					t.Fatal(err)
				}
				dir := c.Dir()
				_ = c.Close()
				reopened, err := database.Open(dir)
				if err != nil {
					t.Fatal(err)
				}
				defer reopened.Close()
				_, err = properties.Lookup(reopened, "remark", vocabkey.OriginProvenencia)
				if err == nil {
					t.Fatal("healed remark on open")
				}
			},
		},
		{
			name: "refuse remove locked binding",
			run: func(t *testing.T, c *database.Catalog) {
				if err := install(c); err != nil {
					t.Fatal(err)
				}
				ptn, err := subjecttypes.Lookup(c, "participation", vocabkey.OriginProvenencia)
				if err != nil {
					t.Fatal(err)
				}
				personProp, err := properties.Lookup(c, "person", vocabkey.OriginProvenencia)
				if err != nil {
					t.Fatal(err)
				}
				if _, err := deleteBinding(t, c, testUser(t, c), ptn.ID, personProp.ID); !errors.Is(err, ErrLocked) {
					t.Fatalf("got %v", err)
				}
			},
		},
		{
			name: "registry presentation and connect rules",
			run: func(t *testing.T, _ *database.Catalog) {
				for _, info := range AllTypes() {
					if info.Presentation.L10nKey == "" || info.Presentation.IconSymbol == "" {
						t.Fatalf("missing presentation %+v", info)
					}
					if info.Presentation.IconSymbol != "subject_"+info.Key {
						t.Fatalf("%s IconSymbol %q, want subject_%s (Swift maps marks by this rule)", info.Key, info.Presentation.IconSymbol, info.Key)
					}
				}
				rule := Connect("person", "event")
				if rule.Refuse || rule.BridgeTypeKey != "participation" || rule.Disambiguation != DisambiguationRole {
					t.Fatalf("%+v", rule)
				}
				if len(rule.Edges) != 2 || rule.Edges[0].PropertyKey != "person" || rule.Edges[0].EndpointTypeKey != "person" ||
					rule.Edges[1].PropertyKey != "event" || rule.Edges[1].EndpointTypeKey != "event" {
					t.Fatalf("participation edges %+v", rule.Edges)
				}
				rel := Connect("person", "person")
				if len(rel.Edges) != 2 || rel.Edges[0].PropertyKey != "person" || rel.Edges[1].PropertyKey != "related_to" ||
					rel.Edges[1].EndpointTypeKey != "person" {
					t.Fatalf("relationship edges %+v", rel.Edges)
				}
				loc := Connect("event", "place")
				if len(loc.Edges) != 2 || loc.Edges[0].PropertyKey != "event" || loc.Edges[1].PropertyKey != "place" {
					t.Fatalf("location edges %+v", loc.Edges)
				}
				placeRel := Connect("place", "place")
				if placeRel.Refuse || placeRel.BridgeTypeKey != "place_relationship" ||
					placeRel.Disambiguation != DisambiguationPlaceRelationshipType {
					t.Fatalf("%+v", placeRel)
				}
				if len(placeRel.Edges) != 2 || placeRel.Edges[0].PropertyKey != "from" || placeRel.Edges[1].PropertyKey != "to" {
					t.Fatalf("place_relationship edges %+v", placeRel.Edges)
				}
				if endpoint, ok := EdgeEndpoint("participation", "person"); !ok || endpoint != "person" {
					t.Fatalf("EdgeEndpoint participation/person %q %v", endpoint, ok)
				}
				if endpoint, ok := EdgeEndpoint("relationship", "related_to"); !ok || endpoint != "person" {
					t.Fatalf("EdgeEndpoint relationship/related_to %q %v", endpoint, ok)
				}
				if endpoint, ok := EdgeEndpoint("location", "place"); !ok || endpoint != "place" {
					t.Fatalf("EdgeEndpoint location/place %q %v", endpoint, ok)
				}
				if endpoint, ok := EdgeEndpoint("place_relationship", "from"); !ok || endpoint != "place" {
					t.Fatalf("EdgeEndpoint place_relationship/from %q %v", endpoint, ok)
				}
				if _, ok := EdgeEndpoint("participation", "role"); ok {
					t.Fatal("role is not an edge")
				}
				rules := ListConnectRules()
				if len(rules) == 0 || len(rules[0].Edges) != len(rules[0].EdgePropertyKeys) {
					t.Fatalf("ListConnectRules edges %+v", rules)
				}
				refuse := Connect("person", "place")
				if !refuse.Refuse {
					t.Fatalf("%+v", refuse)
				}
				unknown := Connect("person", "source")
				if !unknown.Refuse {
					t.Fatalf("%+v", unknown)
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
			tt.run(t, c)
		})
	}
}

// An inverse names a directed term of the same Property that names this one
// back, so matching can read either end of one relationship.
func TestSeedInversesPairUp(t *testing.T) {
	byKey := map[string]seedTerm{}
	for _, term := range seedTerms {
		byKey[term.PropertyKey+"|"+term.Key] = term
	}
	for _, term := range seedTerms {
		if term.Inverse == "" {
			continue
		}
		other, ok := byKey[term.PropertyKey+"|"+term.Inverse]
		if !ok {
			t.Fatalf("%s: inverse %q is not a %s term", term.Key, term.Inverse, term.PropertyKey)
		}
		if other.Inverse != term.Key || !term.Directed || !other.Directed {
			t.Fatalf("%s ↔ %s: inverses must be directed and name each other", term.Key, other.Key)
		}
	}
}

func TestInstallStoresInverses(t *testing.T) {
	c, err := database.Create(t.TempDir(), "t.provenencia")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = c.Close() })
	if err := install(c); err != nil {
		t.Fatal(err)
	}
	rt, err := properties.Lookup(c, "relationship_type", vocabkey.OriginProvenencia)
	if err != nil {
		t.Fatal(err)
	}
	for key, want := range map[string]string{"parent": "child", "ward": "guardian", "spouse": ""} {
		term, err := propertyterms.Lookup(c, rt.ID, key, vocabkey.OriginProvenencia)
		if err != nil || term.InverseKey != want {
			t.Fatalf("%s inverse %q (%v), want %q", key, term.InverseKey, err, want)
		}
	}
}

func TestInstallFlagsNeutralTerms(t *testing.T) {
	c, err := database.Create(t.TempDir(), "t.provenencia")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = c.Close() })
	if err := install(c); err != nil {
		t.Fatal(err)
	}
	sex, err := properties.Lookup(c, "sex_at_birth", vocabkey.OriginProvenencia)
	if err != nil {
		t.Fatal(err)
	}
	for key, want := range map[string]bool{"unknown": true, "indeterminate": true, "male": false, "female": false} {
		term, err := propertyterms.Lookup(c, sex.ID, key, vocabkey.OriginProvenencia)
		if err != nil || term.Neutral != want {
			t.Fatalf("%s neutral %v (%v), want %v", key, term.Neutral, err, want)
		}
	}
}

func TestInstallLetsAUserTermJoinASeededProperty(t *testing.T) {
	c, err := database.Create(t.TempDir(), "t.provenencia")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = c.Close() })
	if err := install(c); err != nil {
		t.Fatal(err)
	}

	gender, err := properties.Lookup(c, "gender", vocabkey.OriginProvenencia)
	if err != nil {
		t.Fatal(err)
	}

	userID := []byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
	userRef, err := ref.Mint(ref.PrefixUser)
	if err != nil {
		t.Fatal(err)
	}
	if err := users.Upsert(c, userID, "Tester", userRef); err != nil {
		t.Fatal(err)
	}
	created, _, err := writes.Run(c, writes.Op{Action: "create_property_term", UserID: userID},
		func(tx *database.Tx) (propertyterms.Term, []rowchange.Change, error) {
			return propertyterms.Create(tx, userID, gender.ID, "Agender", "")
		})
	if err != nil || created.Key != "agender" || created.Origin != vocabkey.OriginUser {
		t.Fatalf("create gender term %+v %v", created, err)
	}
}

func TestInstallMatchesRegistry(t *testing.T) {
	c, err := database.Create(t.TempDir(), "t.provenencia")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = c.Close() })
	if err := install(c); err != nil {
		t.Fatal(err)
	}

	propertyIDs := map[string][]byte{}
	for _, sp := range seedProperties {
		p, err := properties.Lookup(c, sp.Key, vocabkey.OriginProvenencia)
		if err != nil {
			t.Fatalf("property %s: %v", sp.Key, err)
		}
		wantCardinality := sp.Cardinality
		if wantCardinality == "" {
			wantCardinality = propertymeta.CardinalitySingle
		}
		if p.Label != sp.Label || p.ValueType != sp.ValueType || p.Cardinality != wantCardinality {
			t.Fatalf("property %s: got %+v, registry %+v", sp.Key, p, sp)
		}
		propertyIDs[sp.Key] = p.ID
	}

	for _, st := range seedTerms {
		id, ok := propertyIDs[st.PropertyKey]
		if !ok {
			t.Fatalf("term %s/%s: property not in registry", st.PropertyKey, st.Key)
		}
		term, err := propertyterms.Lookup(c, id, st.Key, vocabkey.OriginProvenencia)
		if err != nil {
			t.Fatalf("term %s/%s: %v", st.PropertyKey, st.Key, err)
		}
		if term.Label != st.Label || term.Neutral != st.Neutral || term.Directed != st.Directed || term.InverseKey != st.Inverse {
			t.Fatalf("term %s/%s: got %+v, registry %+v", st.PropertyKey, st.Key, term, st)
		}
	}

	for _, sty := range seedTypes {
		typ, err := subjecttypes.Lookup(c, sty.Key, vocabkey.OriginProvenencia)
		if err != nil {
			t.Fatalf("type %s: %v", sty.Key, err)
		}
		got, err := ListBindings(c, typ.ID)
		if err != nil {
			t.Fatal(err)
		}
		want := BindingsForType(sty.Key)
		if len(got) != len(want) {
			t.Fatalf("type %s: %d bindings, registry %d", sty.Key, len(got), len(want))
		}
		byKey := map[string]Binding{}
		for _, b := range got {
			byKey[b.Property.Key] = b
		}
		for _, w := range want {
			b, ok := byKey[w.PropertyKey]
			if !ok || b.SortOrder != w.SortOrder || b.Locked != w.Locked {
				t.Fatalf("type %s binding %s: got %+v, registry %+v", sty.Key, w.PropertyKey, b, w)
			}
		}
	}
}

func TestAllTypesPaletteSortFollowsBoardOrder(t *testing.T) {
	want := []string{
		"person", "event", "place", "relationship",
		"participation", "location", "place_relationship", "source",
	}
	types := AllTypes()
	byKey := map[string]int{}
	seen := map[int]string{}
	for _, ty := range types {
		byKey[ty.Key] = ty.PaletteSort
		if other, dup := seen[ty.PaletteSort]; dup {
			t.Errorf("types %q and %q share PaletteSort %d", other, ty.Key, ty.PaletteSort)
		}
		seen[ty.PaletteSort] = ty.Key
	}
	if len(types) != len(want) {
		t.Fatalf("AllTypes() has %d types, want %d", len(types), len(want))
	}
	for i := 1; i < len(want); i++ {
		prev, cur := want[i-1], want[i]
		t.Run(prev+" before "+cur, func(t *testing.T) {
			if byKey[prev] >= byKey[cur] {
				t.Errorf("PaletteSort %s=%d, %s=%d; want %s first", prev, byKey[prev], cur, byKey[cur], prev)
			}
		})
	}
}

// testUser upserts the catalog's test user and returns its id.
func testUser(t *testing.T, c *database.Catalog) []byte {
	t.Helper()
	id := []byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
	r, err := ref.Mint(ref.PrefixUser)
	if err != nil {
		t.Fatal(err)
	}
	if err := users.Upsert(c, id, "Tester", r); err != nil {
		t.Fatal(err)
	}
	return id
}

func appendBinding(t *testing.T, c *database.Catalog, userID, typeID, propertyID []byte) ([]rowchange.Change, error) {
	t.Helper()
	changes, err := writes.Call(c, writes.Op{Action: ActionAssign, UserID: userID},
		func(tx *database.Tx) ([]rowchange.Change, []rowchange.Change, error) {
			ch, err := AppendBinding(tx, userID, typeID, propertyID)
			return ch, ch, err
		})
	return changes, err
}

func deleteBinding(t *testing.T, c *database.Catalog, userID, typeID, propertyID []byte) ([]rowchange.Change, error) {
	t.Helper()
	return writes.Call(c, writes.Op{Action: ActionRemove, UserID: userID},
		func(tx *database.Tx) ([]rowchange.Change, []rowchange.Change, error) {
			ch, err := DeleteBinding(tx, userID, typeID, propertyID)
			return ch, ch, err
		})
}

func installedPerson(t *testing.T) (*database.Catalog, []byte, []byte) {
	t.Helper()
	c, err := database.Create(t.TempDir(), "t.provenencia")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = c.Close() })
	userID := testUser(t, c)
	if err := install(c); err != nil {
		t.Fatal(err)
	}
	person, err := subjecttypes.Lookup(c, "person", vocabkey.OriginProvenencia)
	if err != nil {
		t.Fatal(err)
	}
	return c, userID, person.ID
}

func bindingIDs(t *testing.T, c *database.Catalog, typeID []byte) [][]byte {
	t.Helper()
	bs, err := ListBindings(c, typeID)
	if err != nil {
		t.Fatal(err)
	}
	var ids [][]byte
	for _, b := range bs {
		ids = append(ids, b.Property.ID)
	}
	return ids
}

func reorder(c *database.Catalog, userID, typeID []byte, ids [][]byte) ([]rowchange.Change, error) {
	return writes.Call(c, writes.Op{Action: ActionReorder, UserID: userID},
		func(tx *database.Tx) ([]rowchange.Change, []rowchange.Change, error) {
			ch, err := ReorderBindings(tx, userID, typeID, ids)
			return ch, ch, err
		})
}

func TestReorderBindings(t *testing.T) {
	c, userID, personID := installedPerson(t)
	ids := bindingIDs(t, c, personID)
	if len(ids) < 3 {
		t.Fatalf("person binds %d", len(ids))
	}
	order := func() []string {
		var keys []string
		bs, _ := ListBindings(c, personID)
		for _, b := range bs {
			keys = append(keys, b.Property.Key)
		}
		return keys
	}
	before := order()

	t.Run("same order records nothing", func(t *testing.T) {
		ch, err := reorder(c, userID, personID, ids)
		if err != nil || len(ch) != 0 {
			t.Fatalf("changes %d err %v", len(ch), err)
		}
	})

	t.Run("invalid lists change nothing", func(t *testing.T) {
		missing := ids[:len(ids)-1]
		extra := append(append([][]byte(nil), ids...), []byte{9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9})
		repeated := append(append([][]byte(nil), ids[:len(ids)-1]...), ids[0])
		for name, list := range map[string][][]byte{"missing": missing, "extra": extra, "repeated": repeated, "empty": nil} {
			if _, err := reorder(c, userID, personID, list); !errors.Is(err, ErrInvalid) {
				t.Errorf("%s: got %v, want ErrInvalid", name, err)
			}
		}
		if got := order(); !slices.Equal(got, before) {
			t.Fatalf("order moved: %v", got)
		}
	})

	t.Run("a swap records the moved rows", func(t *testing.T) {
		swapped := append([][]byte(nil), ids...)
		swapped[0], swapped[1] = swapped[1], swapped[0]
		ch, err := reorder(c, userID, personID, swapped)
		if err != nil {
			t.Fatal(err)
		}
		if len(ch) != 2 {
			t.Fatalf("changes %d, want 2", len(ch))
		}
		for _, x := range ch {
			if x.EntityType != "subject_type_property" || x.Action != rowchange.ActionUpdate {
				t.Fatalf("change %+v", x)
			}
		}
		got := order()
		if got[0] != before[1] || got[1] != before[0] {
			t.Fatalf("order %v from %v", got, before)
		}
	})
}

func TestBindingChanges(t *testing.T) {
	c, userID, personID := installedPerson(t)
	prop, err := writes.Call(c, writes.Op{Action: "create_property", UserID: userID},
		func(tx *database.Tx) (properties.Property, []rowchange.Change, error) {
			return properties.Create(tx, userID, "Burial Ground", propertymeta.ValueTypeText, "", "")
		})
	if err != nil {
		t.Fatal(err)
	}
	ch, err := appendBinding(t, c, userID, personID, prop.ID)
	if err != nil || len(ch) != 1 || ch[0].Action != rowchange.ActionCreate || ch[0].EntityType != "subject_type_property" {
		t.Fatalf("append %+v %v", ch, err)
	}
	if string(ch[0].EntityID) != string(prop.ID) {
		t.Fatal("entity id is not the property id")
	}
	if ch[0].Fields["sort_order"].New == nil || ch[0].Fields["subject_type_id"].New == nil {
		t.Fatalf("fields %+v", ch[0].Fields)
	}
	revs := func() int {
		db, _ := c.DB()
		var n int
		_ = db.QueryRow(`SELECT COUNT(*) FROM audit_transactions`).Scan(&n)
		return n
	}
	n := revs()
	if ch, err := appendBinding(t, c, userID, personID, prop.ID); err != nil || len(ch) != 0 {
		t.Fatalf("append again %+v %v", ch, err)
	}
	if revs() != n {
		t.Fatal("a bound pair recorded a revision")
	}
	ch, err = deleteBinding(t, c, userID, personID, prop.ID)
	if err != nil || len(ch) != 1 || ch[0].Action != rowchange.ActionDelete {
		t.Fatalf("delete %+v %v", ch, err)
	}
	if ch[0].Fields["subject_type_id"].Old == nil || ch[0].Fields["property_id"].Old == nil {
		t.Fatalf("delete fields %+v", ch[0].Fields)
	}
	name, err := properties.Lookup(c, "name", vocabkey.OriginProvenencia)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := deleteBinding(t, c, userID, personID, name.ID); !errors.Is(err, ErrLocked) {
		t.Fatalf("locked delete: %v", err)
	}
}

func TestEnsureBindingTx(t *testing.T) {
	c, _, personID := installedPerson(t)
	prop, err := propertiestest.Upsert(c, properties.Property{Key: "burial_ground", Origin: vocabkey.OriginProvenencia, Label: "Burial ground", ValueType: propertymeta.ValueTypeText})
	if err != nil {
		t.Fatal(err)
	}
	ensure := func(typeID, propertyID []byte, order int) ([]rowchange.Change, error) {
		return writes.Call(c, writes.Op{Action: "ensure_subject_type_property"},
			func(tx *database.Tx) ([]rowchange.Change, []rowchange.Change, error) {
				ch, err := EnsureBindingTx(tx, typeID, propertyID, order)
				return ch, ch, err
			})
	}
	ch, err := ensure(personID, prop, 3)
	if err != nil || len(ch) != 1 || ch[0].Action != rowchange.ActionCreate || ch[0].EntityType != "subject_type_property" ||
		ch[0].Fields["sort_order"].New != 3 || string(ch[0].EntityID) != string(prop) {
		t.Fatalf("create %+v %v", ch, err)
	}
	if ch, err = ensure(personID, prop, 3); err != nil || len(ch) != 0 {
		t.Fatalf("same %+v %v", ch, err)
	}
	ch, err = ensure(personID, prop, 5)
	if err != nil || len(ch) != 1 || ch[0].Action != rowchange.ActionUpdate {
		t.Fatalf("reorder %+v %v", ch, err)
	}
	f := ch[0].Fields
	if f["sort_order"].Old != 3 || f["sort_order"].New != 5 ||
		f["subject_type_id"].Old != database.UUIDJSON(personID) || f["subject_type_id"].New != database.UUIDJSON(personID) ||
		f["property_id"].Old != database.UUIDJSON(prop) || f["property_id"].New != database.UUIDJSON(prop) {
		t.Fatalf("reorder fields %+v", f)
	}
	if !reflect.DeepEqual(ch[0], bindingOrderChange(personID, prop, 3, 5)) {
		t.Fatalf("not the ReorderBindings shape: %+v", ch[0])
	}
	if _, err := ensure(personID[:4], prop, 1); !errors.Is(err, ErrInvalid) {
		t.Fatalf("short id: %v", err)
	}
}

func TestInstallRecordsOneRevision(t *testing.T) {
	c, err := database.Create(t.TempDir(), "t.provenencia")
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()
	db, err := c.DB()
	if err != nil {
		t.Fatal(err)
	}
	if err := install(c); err != nil {
		t.Fatal(err)
	}
	if n := dbtest.Revisions(t, db); n != 1 {
		t.Fatalf("revisions=%d", n)
	}
	action, changes := dbtest.LatestRevision(t, db)
	want := len(seedTypes) + len(seedProperties) + len(seedTerms) + len(allBindings())
	if action != ActionInstall || len(changes) != want {
		t.Fatalf("action %q changes %d, want %d", action, len(changes), want)
	}
	for _, ch := range changes {
		if ch.Action != rowchange.ActionCreate {
			t.Fatalf("change %+v", ch)
		}
	}
	if n := dbtest.Count(t, db, "SELECT COUNT(*) FROM audit_transactions WHERE user_id IS NULL"); n != 1 {
		t.Fatalf("null-user revisions=%d", n)
	}
	if err := install(c); err != nil {
		t.Fatal(err)
	}
	if n := dbtest.Revisions(t, db); n != 1 {
		t.Fatalf("second install revisions=%d", n)
	}
}

func TestInstallFailureLeavesNothing(t *testing.T) {
	saved := seedBindings
	t.Cleanup(func() { seedBindings = saved })
	seedBindings = append(slices.Clone(saved), seedBinding{TypeKey: "nope", PropertyKey: "name"})
	c, err := database.Create(t.TempDir(), "t.provenencia")
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()
	if err := install(c); !errors.Is(err, ErrInvalid) {
		t.Fatalf("got %v", err)
	}
	if types, err := subjecttypes.List(c); err != nil || len(types) != 0 {
		t.Fatalf("types %v %v", err, types)
	}
	if props, err := properties.List(c); err != nil || len(props) != 0 {
		t.Fatalf("properties %v %v", err, props)
	}
}

// A term whose filed links may not loop is a seeded, directed term with no
// inverse, and its bridge's first endpoint is the from end: the filing rule
// and the proposal both read a canon edge that way.
func TestAcyclicTermsAreSeededDirectedWithNoInverse(t *testing.T) {
	byKey := map[string]seedTerm{}
	for _, term := range seedTerms {
		byKey[term.PropertyKey+"|"+term.Key] = term
	}
	checked := 0
	for _, b := range connectrules.Bridges() {
		for _, term := range b.AcyclicTerms {
			checked++
			seed, ok := byKey[b.Disambiguation+"|"+string(term)]
			if !ok || !seed.Directed || seed.Inverse != "" {
				t.Fatalf("%s %s: seeded %v directed %v inverse %q", b.BridgeTypeKey, term, ok, seed.Directed, seed.Inverse)
			}
			if len(b.Endpoints) != 2 || b.Endpoints[0].PropertyKey != vocabkey.PropertyFrom {
				t.Fatalf("%s: first endpoint must be %s", b.BridgeTypeKey, vocabkey.PropertyFrom)
			}
		}
	}
	if checked == 0 {
		t.Fatal("no acyclic term registered")
	}
}
