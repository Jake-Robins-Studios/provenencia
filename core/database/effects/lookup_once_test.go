package effects_test

import (
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database/citations"
	"github.com/Jake-Robins-Studios/provenencia/core/database/effects"
	"github.com/Jake-Robins-Studios/provenencia/core/database/observations"
	"github.com/Jake-Robins-Studios/provenencia/core/database/properties"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sources"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjects"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjecttypes"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue/datevaluetest"
	"github.com/Jake-Robins-Studios/provenencia/core/depictionvalue/depictionvaluetest"
	"github.com/Jake-Robins-Studios/provenencia/core/valuemark"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

// TestResolveRunsEachLookupOnce pins that one changed row runs each distinct
// lookup (query text and id) once, and that the memo dies with the change.
func TestResolveRunsEachLookupOnce(t *testing.T) {
	const sourceOwner = "FROM sources WHERE date_value_id"
	const valueObservations = "FROM observations WHERE value_date_id"

	t.Run("source date", func(t *testing.T) {
		tx, userID, _, _, art := readsFixture(t)
		_, changes, err := sources.SetDate(tx, userID, art.SourceID, datevaluetest.YMD(1880, 0, 0), valuemark.Mark{})
		if err != nil {
			t.Fatal(err)
		}
		dates := only(changes, "date_value")
		dateID := dates[0].EntityID
		log := &effects.QueryLog{Querier: tx.Tx}
		if _, err := effects.Resolve(log, dates); err != nil {
			t.Fatal(err)
		}
		if n := log.Count(sourceOwner, dateID); n != 1 {
			t.Errorf("sources lookups = %d, want 1", n)
		}
		if r := log.Repeats(); len(r) != 0 {
			t.Errorf("repeated lookups: %q", r)
		}
	})

	t.Run("observation date", func(t *testing.T) {
		tx, userID, _, jones, art := readsFixture(t)
		_, changes, err := citations.CreateWithObservations(tx, userID, citations.CreateInput{
			GraphID: jones.ID, ArtifactID: art.ID, LocatorJSON: depictionvaluetest.Locator,
		}, nil)
		if err != nil {
			t.Fatal(err)
		}
		citationID := only(changes, "citation")[0].EntityID
		placeType, err := subjecttypes.LookupTx(tx.Tx, "place", vocabkey.OriginProvenencia)
		if err != nil {
			t.Fatal(err)
		}
		place, _, err := subjects.Create(tx, userID, subjects.CreateInput{
			GraphID: jones.ID, SubjectTypeID: placeType.ID, Label: "York",
		}, nil)
		if err != nil {
			t.Fatal(err)
		}
		startDate, err := properties.LookupTx(tx.Tx, "start_date", vocabkey.OriginProvenencia)
		if err != nil {
			t.Fatal(err)
		}
		_, obsChanges, err := observations.InsertManyTx(tx.Tx, citationID, []observations.Input{
			{SubjectID: place.ID, PropertyID: startDate.ID, Date: datevaluetest.YMD(1842, 0, 0)},
		}, observations.InsertOptions{})
		if err != nil {
			t.Fatal(err)
		}
		dates := only(obsChanges, "date_value")
		dateID := dates[0].EntityID
		log := &effects.QueryLog{Querier: tx.Tx}
		if _, err := effects.Resolve(log, dates); err != nil {
			t.Fatal(err)
		}
		if n := log.Count(valueObservations, dateID); n != 1 {
			t.Errorf("observations lookups = %d, want 1", n)
		}
		if n := log.Count("FROM identity_claims WHERE subject_id", place.ID); n != 1 {
			t.Errorf("identity_claims lookups = %d, want 1", n)
		}
		if r := log.Repeats(); len(r) != 0 {
			t.Errorf("repeated lookups: %q", r)
		}
	})

	t.Run("twice in one batch", func(t *testing.T) {
		tx, userID, _, _, art := readsFixture(t)
		_, changes, err := sources.SetDate(tx, userID, art.SourceID, datevaluetest.YMD(1880, 0, 0), valuemark.Mark{})
		if err != nil {
			t.Fatal(err)
		}
		date := only(changes, "date_value")[0]
		log := &effects.QueryLog{Querier: tx.Tx}
		if _, err := effects.Resolve(log, []rowchange.Change{date, date}); err != nil {
			t.Fatal(err)
		}
		if n := log.Count(sourceOwner, date.EntityID); n != 2 {
			t.Errorf("sources lookups = %d, want 2 (one per change)", n)
		}
	})
}
