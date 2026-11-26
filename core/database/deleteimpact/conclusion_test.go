package deleteimpact_test

import (
	"strings"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/artifacts"
	"github.com/Jake-Robins-Studios/provenencia/core/database/artifacts/artifactstest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/canonicalentities"
	"github.com/Jake-Robins-Studios/provenencia/core/database/catalogmodel"
	"github.com/Jake-Robins-Studios/provenencia/core/database/citations"
	"github.com/Jake-Robins-Studios/provenencia/core/database/dbtest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/deleteimpact"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencegraphs/evidencegraphstest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/identityclaims"
	"github.com/Jake-Robins-Studios/provenencia/core/database/observations"
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
	"github.com/Jake-Robins-Studios/provenencia/core/depictionvalue/depictionvaluetest"
	"github.com/Jake-Robins-Studios/provenencia/core/propertymeta"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
)

func TestImpactConclusion(t *testing.T) {
	c, userID := testCatalog(t)
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
		return sources.Create(tx, userID, sources.CreateInput{SourceTypeID: typeID, Title: "Register"})
	})
	if err != nil {
		t.Fatal(err)
	}
	art, err := artifactstest.Create(c, userID, artifacts.CreateInput{SourceID: src.ID, Label: "Scan"})
	if err != nil {
		t.Fatal(err)
	}
	place, err := subjecttypes.Lookup(c, "place", vocabkey.OriginProvenencia)
	if err != nil {
		t.Fatal(err)
	}
	graph := evidencegraphstest.SoleGraph(t, c, src.ID).ID
	york := subjectstest.OfType(t, c, userID, graph, place.ID, "York")
	toponym, err := properties.Lookup(c, "toponym", vocabkey.OriginProvenencia)
	if err != nil {
		t.Fatal(err)
	}
	res, err := writes.Call(c, writes.Op{Action: "create_citation_with_observations", UserID: userID}, func(tx *database.Tx) (citations.CreateResult, []rowchange.Change, error) {
		return citations.CreateWithObservations(tx, userID, citations.CreateInput{
			GraphID:    graph,
			ArtifactID: art.ID, LocatorJSON: depictionvaluetest.Locator, Transcription: "York",
		}, []observations.Input{{
			SubjectID: york.ID, PropertyID: toponym.ID, Scalar: propertymeta.TextScalar("York"),
		}})
	})
	if err != nil {
		t.Fatal(err)
	}
	obsID := res.Observations[0].ID
	plc, err := writes.Call(c, writes.Op{Action: "create_canonical_entity", UserID: userID}, func(tx *database.Tx) (canonicalentities.Entity, []rowchange.Change, error) {
		return canonicalentities.Create(tx, userID, canonicalentities.CreateInput{SubjectTypeID: place.ID})
	})
	if err != nil {
		t.Fatal(err)
	}
	claim, err := writes.Call(c, writes.Op{Action: "create_identity_claim", UserID: userID}, func(tx *database.Tx) (identityclaims.Claim, []rowchange.Change, error) {
		return identityclaims.Create(tx, userID, identityclaims.CreateInput{
			SubjectID: york.ID, EntityID: plc.ID, Status: identityclaims.StatusAccepted,
		})
	})
	if err != nil {
		t.Fatal(err)
	}

	t.Run("subject type in use names its handle", func(t *testing.T) {
		got := mustImpact(t, c, catalogmodel.KindSubjectType, place.ID)
		if got.Allowed {
			t.Fatalf("%+v", got)
		}
		g := findGroup(t, got, "canonical_entities.subject_type_id")
		if g.Kind != catalogmodel.KindCanonicalEntity || g.Total != 1 || g.Listed[0].Ref != plc.Ref {
			t.Fatalf("%+v", g)
		}
	})

	t.Run("blocked promoted subject reports the handle it would delete", func(t *testing.T) {
		got := mustImpact(t, c, catalogmodel.KindSubject, york.ID)
		if got.Allowed || len(got.Groups) == 0 {
			t.Fatalf("%+v", got)
		}
		assertLastMember(t, got, plc.Ref)
	})

	t.Run("allowed promoted subject names the handle it would delete when sole member", func(t *testing.T) {
		graph := evidencegraphstest.SoleGraph(t, c, src.ID).ID
		leeds := subjectstest.OfType(t, c, userID, graph, place.ID, "Leeds")
		got := mustImpact(t, c, catalogmodel.KindSubject, leeds.ID)
		if !got.Allowed || len(got.Cascades) != 0 {
			t.Fatalf("unpromoted %+v", got)
		}
		res := promotetest.Save(t, c, userID, promote.Input{SubjectID: leeds.ID})
		got = mustImpact(t, c, catalogmodel.KindSubject, leeds.ID)
		if !got.Allowed || len(got.Groups) != 0 {
			t.Fatalf("%+v", got)
		}
		assertLastMember(t, got, res.Entity.Ref)
	})

	t.Run("a member's observation names no handle", func(t *testing.T) {
		got := mustImpact(t, c, catalogmodel.KindObservation, obsID)
		if !got.Allowed || got.Gate != deleteimpact.GateOK || len(got.Groups) != 0 || len(got.Cascades) != 0 {
			t.Fatalf("%+v", got)
		}
	})

	t.Run("observation delete audits only the observation", func(t *testing.T) {
		if _, err := writes.RunChanges(c, writes.Op{Action: "delete_observation", UserID: userID}, func(tx *database.Tx) ([]rowchange.Change, error) {
			return observations.Delete(tx, userID, obsID)
		}); err != nil {
			t.Fatal(err)
		}
		db := dbtest.MustDB(t, c)
		action, revision := dbtest.LatestRevision(t, db)
		types := dbtest.EntityTypes(revision)
		if action != "delete_observation" || strings.Join(types, ",") != "observation" {
			t.Fatalf("%s %v", action, types)
		}
		if _, err := identityclaims.Get(c, claim.ID); err != nil {
			t.Fatalf("claim should stay as written: %v", err)
		}
	})

	t.Run("subject delete removes its claim and deletes the sole-member handle", func(t *testing.T) {
		if _, err := writes.RunChanges(c, writes.Op{Action: "delete_subject", UserID: userID}, func(tx *database.Tx) ([]rowchange.Change, error) {
			return subjects.Delete(tx, userID, york.ID)
		}); err != nil {
			t.Fatal(err)
		}
		db := dbtest.MustDB(t, c)
		action, revision := dbtest.LatestRevision(t, db)
		types := dbtest.EntityTypes(revision)
		if action != "delete_subject" || strings.Join(types, ",") != "identity_claim,canonical_entity,subject" {
			t.Fatalf("%s %v", action, types)
		}
		if _, err := canonicalentities.Get(c, plc.ID); err == nil {
			t.Fatal("handle should be gone")
		}
	})
}

func assertLeaves(t *testing.T, r deleteimpact.Report, handleRef string) {
	t.Helper()
	if len(r.Cascades) != 1 {
		t.Fatalf("cascades %+v", r.Cascades)
	}
	g := r.Cascades[0]
	if g.Via != deleteimpact.ViaLeavesHandle || g.Kind != catalogmodel.KindCanonicalEntity ||
		g.Total != 1 || len(g.Listed) != 1 || g.Listed[0].Ref != handleRef {
		t.Fatalf("%+v", g)
	}
}

func assertLastMember(t *testing.T, r deleteimpact.Report, handleRef string) {
	t.Helper()
	if len(r.Cascades) != 1 {
		t.Fatalf("cascades %+v", r.Cascades)
	}
	g := r.Cascades[0]
	if g.Via != deleteimpact.ViaLastMember || g.Kind != catalogmodel.KindCanonicalEntity ||
		g.Total != 1 || len(g.Listed) != 1 || g.Listed[0].Ref != handleRef {
		t.Fatalf("%+v", g)
	}
}

func findGroup(t *testing.T, r deleteimpact.Report, via string) deleteimpact.Group {
	t.Helper()
	for _, g := range r.Groups {
		if g.Via == via {
			return g
		}
	}
	t.Fatalf("no group %s in %+v", via, r)
	return deleteimpact.Group{}
}

func findCascade(t *testing.T, r deleteimpact.Report, via string) deleteimpact.Group {
	t.Helper()
	for _, g := range r.Cascades {
		if g.Via == via {
			return g
		}
	}
	t.Fatalf("no cascade %s in %+v", via, r.Cascades)
	return deleteimpact.Group{}
}
