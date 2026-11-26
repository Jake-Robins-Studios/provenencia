package effects_test

import (
	"bytes"
	"database/sql"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/artifacts"
	"github.com/Jake-Robins-Studios/provenencia/core/database/artifacts/artifactstest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/effects"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencegraphs/evidencegraphstest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/identityclaims"
	"github.com/Jake-Robins-Studios/provenencia/core/database/observations"
	"github.com/Jake-Robins-Studios/provenencia/core/database/observations/observationstest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/promote"
	"github.com/Jake-Robins-Studios/provenencia/core/database/promote/promotetest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/properties"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sources"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes/sourcetypestest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjects"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjects/subjectstest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjecttypes"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjectvocab/subjectvocabtest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/users"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue"
	"github.com/Jake-Robins-Studios/provenencia/core/depictionvalue/depictionvaluetest"
	"github.com/Jake-Robins-Studios/provenencia/core/ref"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
	"github.com/google/uuid"
)

// TestHandlePaths resolves Effect.Handles through Resolve (Set.Handles)
// against a catalog; these checks are the rules the registry states.
//
// membersOf keeps accepted and provisional claims and drops rejected. A
// citation edit recomputes handles only when transcription_uncertain is on
// the diff. onStatus runs when the old or the new status is accepted, and a
// status that is never accepted does not recompute observers. A date value
// walks inbound to the observation that points at it. value_date_id is
// unique, so that is one observation today.
func TestHandlePaths(t *testing.T) {
	userID := []byte{9, 8, 7, 6, 5, 4, 3, 2, 1, 9, 8, 7, 6, 5, 4, 3}
	c, err := database.Create(t.TempDir(), "t.provenencia")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = c.Close() })
	ur, err := ref.Mint(ref.PrefixUser)
	if err != nil {
		t.Fatal(err)
	}
	if err := users.Upsert(c, userID, "Tester", ur); err != nil {
		t.Fatal(err)
	}
	if err := subjectvocabtest.Install(c); err != nil {
		t.Fatal(err)
	}
	typeID, err := sourcetypestest.Upsert(c, sourcetypes.Type{
		Key: "book", Origin: vocabkey.OriginProvenencia, Label: "Book",
	})
	if err != nil {
		t.Fatal(err)
	}
	src, _, err := writes.Run(c, writes.Op{Action: "create_source", UserID: userID}, func(tx *database.Tx) (sources.Source, []rowchange.Change, error) {
		return sources.Create(tx, userID, sources.CreateInput{SourceTypeID: typeID, Title: "A"})
	})
	if err != nil {
		t.Fatal(err)
	}
	art, err := artifactstest.Create(c, userID, artifacts.CreateInput{SourceID: src.ID, Label: "Scan"})
	if err != nil {
		t.Fatal(err)
	}
	personType, err := subjecttypes.Lookup(c, "person", vocabkey.OriginProvenencia)
	if err != nil {
		t.Fatal(err)
	}
	placeType, err := subjecttypes.Lookup(c, "place", vocabkey.OriginProvenencia)
	if err != nil {
		t.Fatal(err)
	}
	mk := func(typeID []byte, label string, x int64) subjects.Subject {
		t.Helper()
		graph := evidencegraphstest.SoleGraph(t, c, src.ID).ID
		return subjectstest.At(t, c, userID, graph, typeID, label, subjects.Placement{GridX: x, GridY: 0})
	}
	alice := mk(personType.ID, "Alice", 0)
	bob := mk(personType.ID, "Bob", 4)
	cara := mk(personType.ID, "Cara", 8)
	drew := mk(personType.ID, "Drew", 12)
	eve := mk(personType.ID, "Eve", 14)
	boston := mk(placeType.ID, "Boston", 16)

	aliceRes := promotetest.Save(t, c, userID, promote.Input{SubjectID: alice.ID})
	bobRes := promotetest.Save(t, c, userID, promote.Input{SubjectID: bob.ID})
	eveRes := promotetest.Save(t, c, userID, promote.Input{SubjectID: eve.ID})
	bostonRes := promotetest.Save(t, c, userID, promote.Input{SubjectID: boston.ID})
	if _, err := writes.Call(c, writes.Op{Action: "create_identity_claim", UserID: userID}, func(tx *database.Tx) (identityclaims.Claim, []rowchange.Change, error) {
		return identityclaims.Create(tx, userID, identityclaims.CreateInput{
			SubjectID: cara.ID, EntityID: aliceRes.Entity.ID, Status: identityclaims.StatusRejected,
		})
	}); err != nil {
		t.Fatal(err)
	}
	if _, err := writes.Call(c, writes.Op{Action: "create_identity_claim", UserID: userID}, func(tx *database.Tx) (identityclaims.Claim, []rowchange.Change, error) {
		return identityclaims.Create(tx, userID, identityclaims.CreateInput{
			SubjectID: drew.ID, EntityID: aliceRes.Entity.ID, Status: identityclaims.StatusProvisional,
		})
	}); err != nil {
		t.Fatal(err)
	}

	personProp, err := properties.Lookup(c, "person", vocabkey.OriginProvenencia)
	if err != nil {
		t.Fatal(err)
	}
	dateProp, err := properties.Lookup(c, "start_date", vocabkey.OriginProvenencia)
	if err != nil {
		t.Fatal(err)
	}
	graph := evidencegraphstest.SoleGraph(t, c, src.ID).ID
	year := 1842
	created, _, err := observationstest.Cite(c, userID, graph, art.ID, depictionvaluetest.Locator, []observations.Input{{
		SubjectID: boston.ID, PropertyID: dateProp.ID,
		Date: &datevalue.Value{Kind: datevalue.KindPoint, StartYear: &year},
	}}...)
	if err != nil {
		t.Fatal(err)
	}
	dateID := created.Observations[0].ValueDateID
	if len(dateID) != 16 {
		t.Fatal("date value was not stored")
	}

	// Bob's observation points at Alice. Person subjects are not bound to a
	// subject-valued property, so this row is inserted directly: the registry
	// reads observations, and the binding rule is the writer's.
	db, err := c.DB()
	if err != nil {
		t.Fatal(err)
	}
	insertPointing := func(subjectID []byte) {
		t.Helper()
		id, err := uuid.NewV7()
		if err != nil {
			t.Fatal(err)
		}
		r, err := ref.Mint(ref.PrefixObservation)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := db.Exec(`INSERT INTO observations (
			id, ref, citation_id, subject_id, property_id, polarity, value_subject_id
		) VALUES (?, ?, ?, ?, ?, 'positive', ?)`,
			id[:], r, created.Citation.ID, subjectID, personProp.ID, alice.ID); err != nil {
			t.Fatal(err)
		}
	}
	insertPointing(bob.ID)
	insertPointing(eve.ID)

	tx, err := db.Begin()
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = tx.Rollback() })

	t.Run("members keep accepted and provisional", func(t *testing.T) {
		got := mustHandles(t, tx, observationSubject(alice.ID))
		if !idSet(got, aliceRes.Entity.ID) {
			t.Fatalf("alice handles %d", len(got))
		}
		got = mustHandles(t, tx, observationSubject(drew.ID))
		if !idSet(got, aliceRes.Entity.ID) {
			t.Fatalf("provisional handles %d", len(got))
		}
		got = mustHandles(t, tx, observationSubject(cara.ID))
		if len(got) != 0 {
			t.Fatalf("rejected claim resolved %d handles", len(got))
		}
	})

	t.Run("transcription_uncertain only", func(t *testing.T) {
		note := rowchange.Change{
			EntityType: "citation", EntityID: created.Citation.ID, Action: rowchange.ActionUpdate,
			Fields: map[string]rowchange.FieldDiff{
				"transcription_note": {Old: "", New: "ink faded"},
			},
		}
		if got := mustHandles(t, tx, note); len(got) != 0 {
			t.Fatalf("note edit resolved %d handles", len(got))
		}
		uncertain := note
		uncertain.Fields = map[string]rowchange.FieldDiff{
			"transcription_uncertain": {Old: false, New: true},
		}
		got := mustHandles(t, tx, uncertain)
		if !idSet(got, bostonRes.Entity.ID, bobRes.Entity.ID, eveRes.Entity.ID) {
			t.Fatalf("uncertain edit resolved %d handles", len(got))
		}
		if got := mustHandleScopes(t, tx, uncertain); len(got) != 0 {
			t.Fatalf("uncertain edit scoped %d handles", len(got))
		}
	})

	t.Run("accepted on old or new status", func(t *testing.T) {
		base := rowchange.Change{
			EntityType: "identity_claim", EntityID: aliceRes.Claim.ID, Action: rowchange.ActionUpdate,
		}
		argument := base
		argument.Fields = map[string]rowchange.FieldDiff{"argument": {Old: "", New: "sure"}}
		if got := mustHandles(t, tx, argument); !idSet(got, aliceRes.Entity.ID) {
			t.Fatalf("argument edit resolved %d handles", len(got))
		}
		acceptedToRejected := base
		acceptedToRejected.Fields = map[string]rowchange.FieldDiff{
			"status": {Old: identityclaims.StatusAccepted, New: identityclaims.StatusRejected},
		}
		if got := mustHandles(t, tx, acceptedToRejected); !idSet(got, aliceRes.Entity.ID, bobRes.Entity.ID, eveRes.Entity.ID) {
			t.Fatalf("accepted→rejected resolved %d handles", len(got))
		}
		rejectedToAccepted := base
		rejectedToAccepted.Fields = map[string]rowchange.FieldDiff{
			"status": {Old: identityclaims.StatusRejected, New: identityclaims.StatusAccepted},
		}
		if got := mustHandles(t, tx, rejectedToAccepted); !idSet(got, aliceRes.Entity.ID, bobRes.Entity.ID, eveRes.Entity.ID) {
			t.Fatalf("rejected→accepted resolved %d handles", len(got))
		}
		neither := base
		neither.Fields = map[string]rowchange.FieldDiff{
			"status": {Old: identityclaims.StatusProvisional, New: identityclaims.StatusRejected},
		}
		if got := mustHandles(t, tx, neither); !idSet(got, aliceRes.Entity.ID) {
			t.Fatalf("status that is never accepted resolved %d handles", len(got))
		}
	})

	t.Run("date value reaches its observation", func(t *testing.T) {
		ch := rowchange.Change{
			EntityType: "date_value", EntityID: dateID, Action: rowchange.ActionUpdate,
			Fields: map[string]rowchange.FieldDiff{"start_year": {Old: 1842, New: 1843}},
		}
		got := mustHandles(t, tx, ch)
		if !idSet(got, bostonRes.Entity.ID) {
			t.Fatalf("date value resolved %d handles", len(got))
		}
	})

	t.Run("observation note reaches member handle", func(t *testing.T) {
		noteID, err := uuid.NewV7()
		if err != nil {
			t.Fatal(err)
		}
		ch := rowchange.Change{
			EntityType: "observation_note", EntityID: noteID[:], Action: rowchange.ActionCreate,
			Fields: map[string]rowchange.FieldDiff{
				"observation_id": {New: dashed(created.Observations[0].ID)},
			},
		}
		got := mustHandleScopes(t, tx, ch)
		if !idSet(got, bostonRes.Entity.ID) {
			t.Fatalf("note scoped %d handles", len(got))
		}
	})

	t.Run("resolve reports note handle scopes", func(t *testing.T) {
		noteID, err := uuid.NewV7()
		if err != nil {
			t.Fatal(err)
		}
		ch := rowchange.Change{
			EntityType: "observation_note", EntityID: noteID[:], Action: rowchange.ActionCreate,
			Fields: map[string]rowchange.FieldDiff{
				"observation_id": {New: dashed(created.Observations[0].ID)},
			},
		}
		set, err := effects.Resolve(tx, []rowchange.Change{ch})
		if err != nil {
			t.Fatal(err)
		}
		if !idSet(set.HandleScopes, bostonRes.Entity.ID) {
			t.Fatalf("resolve scoped %d handles", len(set.HandleScopes))
		}
		if len(set.Handles) != 0 {
			t.Fatalf("resolve reported %d recompute handles for a note", len(set.Handles))
		}
	})

	t.Run("subject move scopes both handles", func(t *testing.T) {
		ch := observationSubject(bob.ID)
		ch.Fields["subject_id"] = rowchange.FieldDiff{Old: dashed(alice.ID), New: dashed(bob.ID)}
		got := mustHandleScopes(t, tx, ch)
		if !idSet(got, aliceRes.Entity.ID, bobRes.Entity.ID) {
			t.Fatalf("subject move scoped %d handles", len(got))
		}
	})

	t.Run("a grade change names the handles citing the Source", func(t *testing.T) {
		ch := rowchange.Change{
			EntityType: "source_credibility_assessment", EntityID: []byte{2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2},
			Action: rowchange.ActionUpdate,
			Fields: map[string]rowchange.FieldDiff{
				"source_id":            {New: dashed(src.ID)},
				"credibility_grade_id": {Old: "a", New: "b"},
			},
		}
		if got := mustHandles(t, tx, ch); !idSet(got, bostonRes.Entity.ID, bobRes.Entity.ID, eveRes.Entity.ID) || len(got) != 3 {
			t.Fatalf("grade change resolved %d handles", len(got))
		}
	})

	t.Run("a Subject that changes Source names its handles", func(t *testing.T) {
		moved := func(id []byte, field string) rowchange.Change {
			return rowchange.Change{
				EntityType: "subject", EntityID: id, Action: rowchange.ActionUpdate,
				Fields: map[string]rowchange.FieldDiff{field: {Old: "a", New: "b"}},
			}
		}
		for _, id := range [][]byte{alice.ID, drew.ID} {
			if got := mustHandles(t, tx, moved(id, "source_id")); !idSet(got, aliceRes.Entity.ID) || len(got) != 1 {
				t.Fatalf("source change resolved %d handles", len(got))
			}
		}
		if got := mustHandles(t, tx, moved(cara.ID, "source_id")); len(got) != 0 {
			t.Fatalf("rejected member resolved %d handles", len(got))
		}
		if got := mustHandles(t, tx, moved(alice.ID, "label")); len(got) != 0 {
			t.Fatalf("label edit resolved %d handles", len(got))
		}
	})

	t.Run("rejected member is not scoped", func(t *testing.T) {
		if got := mustHandleScopes(t, tx, observationSubject(cara.ID)); len(got) != 0 {
			t.Fatalf("rejected claim scoped %d handles", len(got))
		}
	})
}

func dashed(id []byte) string {
	var u uuid.UUID
	copy(u[:], id)
	return u.String()
}

func observationSubject(subjectID []byte) rowchange.Change {
	return rowchange.Change{
		EntityType: "observation",
		EntityID:   []byte{1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
		Action:     rowchange.ActionUpdate,
		Fields: map[string]rowchange.FieldDiff{
			"subject_id": {New: dashed(subjectID)},
		},
	}
}

func mustHandles(t *testing.T, tx *sql.Tx, changes ...rowchange.Change) [][]byte {
	t.Helper()
	set, err := effects.Resolve(tx, changes)
	if err != nil {
		t.Fatal(err)
	}
	return set.Handles
}

func mustHandleScopes(t *testing.T, tx *sql.Tx, changes ...rowchange.Change) [][]byte {
	t.Helper()
	set, err := effects.Resolve(tx, changes)
	if err != nil {
		t.Fatal(err)
	}
	return set.HandleScopes
}

func idSet(got [][]byte, want ...[]byte) bool {
	if len(got) != len(want) {
		return false
	}
	for _, id := range want {
		found := false
		for _, other := range got {
			if bytes.Equal(id, other) {
				found = true
				break
			}
		}
		if !found {
			return false
		}
	}
	return true
}
