package effects_test

import (
	"bytes"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/artifacts"
	"github.com/Jake-Robins-Studios/provenencia/core/database/citations"
	"github.com/Jake-Robins-Studios/provenencia/core/database/effects"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencegraphs"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields"
	"github.com/Jake-Robins-Studios/provenencia/core/database/observations"
	"github.com/Jake-Robins-Studios/provenencia/core/database/properties"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcemetadata"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sources"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes/sourcetypestest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjects"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjecttypes"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjectvocab/subjectvocabtest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/users"
	"github.com/Jake-Robins-Studios/provenencia/core/namevalue"
	"github.com/Jake-Robins-Studios/provenencia/core/ref"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

// citationReads is the citations read ids the changes of one write resolve to.
func citationReads(t *testing.T, tx *database.Tx, changes []rowchange.Change) [][]byte {
	t.Helper()
	set, err := effects.Resolve(tx.Tx, changes)
	if err != nil {
		t.Fatal(err)
	}
	return set.IDsOf(effects.ReadCitations)
}

func only(changes []rowchange.Change, entity string) []rowchange.Change {
	var out []rowchange.Change
	for _, ch := range changes {
		if ch.EntityType == entity {
			out = append(out, ch)
		}
	}
	return out
}

// readsFixture is a Source with a Default graph and a Jones graph, an Artifact
// linked to both, and a write transaction that is rolled back at cleanup.
func readsFixture(t *testing.T) (tx *database.Tx, userID []byte, def, jones evidencegraphs.Graph, art artifacts.Artifact) {
	t.Helper()
	userID = []byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
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
	db, err := c.DB()
	if err != nil {
		t.Fatal(err)
	}
	sqlTx, err := db.Begin()
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = sqlTx.Rollback() })
	tx = &database.Tx{Tx: sqlTx}

	src, _, err := sources.Create(tx, userID, sources.CreateInput{SourceTypeID: typeID, Title: "Census"})
	if err != nil {
		t.Fatal(err)
	}
	if err := tx.QueryRow(`SELECT id, COALESCE(ref, ''), source_id, name FROM evidence_graphs WHERE source_id = ?`, src.ID).
		Scan(&def.ID, &def.Ref, &def.SourceID, &def.Name); err != nil {
		t.Fatal(err)
	}
	art, _, err = artifacts.Create(tx, userID, artifacts.CreateInput{SourceID: src.ID, Label: "Page"})
	if err != nil {
		t.Fatal(err)
	}
	jones, _, err = evidencegraphs.Create(tx, userID, evidencegraphs.CreateInput{
		SourceID: src.ID, Name: "Jones", ArtifactIDs: [][]byte{art.ID},
	})
	if err != nil {
		t.Fatal(err)
	}
	var linked int
	if err := tx.QueryRow(`SELECT COUNT(*) FROM evidence_graph_artifacts WHERE artifact_id = ?`, art.ID).Scan(&linked); err != nil || linked != 2 {
		t.Fatalf("artifact links: %d %v, want Default and Jones", linked, err)
	}
	return tx, userID, def, jones, art
}

func sameGraphs(t *testing.T, what string, got [][]byte, want ...[]byte) {
	t.Helper()
	if len(got) != len(want) {
		t.Fatalf("%s: %x, want %x", what, got, want)
	}
	for i := range want {
		if !bytes.Equal(got[i], want[i]) {
			t.Fatalf("%s: %x, want %x", what, got, want)
		}
	}
}

// TestCitationReadsNameItsGraph pins a Citation with no Observation: it names
// no graph for graphcache, and its citation read is the graph it was made in
// (Jones), though its Artifact is linked to Default too.
func TestCitationReadsNameItsGraph(t *testing.T) {
	tx, userID, _, jones, art := readsFixture(t)
	_, changes, err := citations.CreateWithObservations(tx, userID, citations.CreateInput{
		GraphID: jones.ID, ArtifactID: art.ID, LocatorJSON: evidenceLocator,
	}, nil)
	if err != nil {
		t.Fatal(err)
	}
	cit := only(changes, "citation")
	set, err := effects.Resolve(tx.Tx, cit)
	if err != nil {
		t.Fatal(err)
	}
	if len(set.EvidenceGraphs) != 0 {
		t.Fatalf("EvidenceGraphs %x, want none", set.EvidenceGraphs)
	}
	if len(set.Reads) != 1 || set.Reads[0].Read != effects.ReadCitations {
		t.Fatalf("Reads %+v, want citations only", set.Reads)
	}
	sameGraphs(t, "citation reads", set.Reads[0].IDs, jones.ID)
}

// TestFirstObservationMovesNoOtherGraph: a Citation made in Jones gains its
// first Observation; the write names Jones alone, never Default, though the
// Artifact is linked to both.
func TestFirstObservationMovesNoOtherGraph(t *testing.T) {
	tx, userID, _, jones, art := readsFixture(t)
	_, changes, err := citations.CreateWithObservations(tx, userID, citations.CreateInput{
		GraphID: jones.ID, ArtifactID: art.ID, LocatorJSON: evidenceLocator,
	}, nil)
	if err != nil {
		t.Fatal(err)
	}
	citationID := only(changes, "citation")[0].EntityID
	personType, err := subjecttypes.LookupTx(tx.Tx, "person", vocabkey.OriginProvenencia)
	if err != nil {
		t.Fatal(err)
	}
	nameProp, err := properties.LookupTx(tx.Tx, "name", vocabkey.OriginProvenencia)
	if err != nil {
		t.Fatal(err)
	}
	subject, _, err := subjects.Create(tx, userID, subjects.CreateInput{
		GraphID: jones.ID, SubjectTypeID: personType.ID, Label: "Ada",
	}, nil)
	if err != nil {
		t.Fatal(err)
	}
	_, obsChanges, err := observations.InsertManyTx(tx.Tx, citationID, []observations.Input{
		{SubjectID: subject.ID, PropertyID: nameProp.ID, Name: &namevalue.Value{Form: "Ada"}},
	}, observations.InsertOptions{})
	if err != nil {
		t.Fatal(err)
	}
	sameGraphs(t, "first Observation: citation reads", citationReads(t, tx, only(obsChanges, "observation")), jones.ID)
}

// TestMetadataValuesNameCitationGraphs: a value set on a Citation, its graph,
// its Artifact or its Source moves the citation_boards read of the graph the
// Citation was made in, and no value moves the citations read (its counts).
func TestMetadataValuesNameCitationGraphs(t *testing.T) {
	tx, userID, def, jones, art := readsFixture(t)
	_, changes, err := citations.CreateWithObservations(tx, userID, citations.CreateInput{
		GraphID: jones.ID, ArtifactID: art.ID, LocatorJSON: evidenceLocator,
	}, nil)
	if err != nil {
		t.Fatal(err)
	}
	citationID := only(changes, "citation")[0].EntityID
	field, _, err := metadatafields.Create(tx, "Page", metadatafields.DataTypeText, "")
	if err != nil {
		t.Fatal(err)
	}
	var sourceID []byte
	if err := tx.QueryRow(`SELECT source_id FROM evidence_graphs WHERE id = ?`, jones.ID).Scan(&sourceID); err != nil {
		t.Fatal(err)
	}
	owners := []struct {
		name  string
		owner sourcemetadata.Owner
		want  [][]byte
	}{
		{"citation", sourcemetadata.Owner{Level: vocabkey.LevelCitation, ID: citationID}, [][]byte{jones.ID}},
		{"graph", sourcemetadata.Owner{Level: vocabkey.LevelGraph, ID: jones.ID}, [][]byte{jones.ID}},
		{"artifact", sourcemetadata.Owner{Level: vocabkey.LevelArtifact, ID: art.ID}, [][]byte{jones.ID}},
	}
	for _, o := range owners {
		t.Run(o.name, func(t *testing.T) {
			_, ch, err := sourcemetadata.Set(tx, userID, o.owner, sourcemetadata.Input{FieldID: field.ID, ValueText: "2"})
			if err != nil {
				t.Fatal(err)
			}
			set, err := effects.Resolve(tx.Tx, ch)
			if err != nil {
				t.Fatal(err)
			}
			sameGraphs(t, "citation_boards", set.IDsOf(effects.ReadCitationBoards), o.want...)
			if got := set.IDsOf(effects.ReadCitations); len(got) != 0 {
				t.Errorf("citations read %x, want none", got)
			}
		})
	}
	t.Run("source", func(t *testing.T) {
		_, ch, err := sourcemetadata.Set(tx, userID, sourcemetadata.Owner{Level: vocabkey.LevelSource, ID: sourceID},
			sourcemetadata.Input{FieldID: field.ID, ValueText: "2"})
		if err != nil {
			t.Fatal(err)
		}
		set, err := effects.Resolve(tx.Tx, ch)
		if err != nil {
			t.Fatal(err)
		}
		got := set.IDsOf(effects.ReadCitationBoards)
		if len(got) != 2 || !((bytes.Equal(got[0], def.ID) && bytes.Equal(got[1], jones.ID)) || (bytes.Equal(got[0], jones.ID) && bytes.Equal(got[1], def.ID))) {
			t.Errorf("citation_boards %x, want both graphs of the Source", got)
		}
		if got := set.IDsOf(effects.ReadCitations); len(got) != 0 {
			t.Errorf("citations read %x, want none", got)
		}
	})
}
