package citationrender

import (
	"strconv"
	"testing"
	"time"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/databasetest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sources"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue/datevaluetest"
	"github.com/Jake-Robins-Studios/provenencia/core/valuemark"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
)

const (
	scaleSources         = 30
	scaleArtifactsPerSrc = 2
	scaleGraphsPerSrc    = 5
)

// scaleValues are AC-1.1's stored values by the table that holds them.
var scaleValues = []struct {
	table, owner string
	values       map[string]string
}{
	{"source_metadata", "source_id", map[string]string{
		"creator": "Westmark", "jurisdiction": "Calder County, Westmark", "schedule": "population schedule",
		"enumeration_district": "236", "piece": "1047", "folio": "22",
	}},
	{"artifact_metadata", "artifact_id", map[string]string{
		"format": "digital image", "provider": "Westmark Heritage", "url": "https://example.org/calder/1880",
		"accessed_date": "12 March 2025", "citing": "county film 7, item 3",
	}},
	{"evidence_graph_metadata", "graph_id", map[string]string{
		"schedule_number": "9", "dwelling_number": "112", "family_number": "118", "line_number": "14", "item": "Ada Robins",
	}},
}

// seedScale files 30 Sources of the seeded census type, each dated 1880 and
// holding AC-1.1's values, each with 2 Artifacts and 5 graphs (every graph
// linked to both Artifacts) and perSource Citations spread evenly over its
// graphs and Artifacts. It writes direct INSERTs on one transaction, as
// evidencegraphstest.ScaleSeed does, then dates the Sources through
// sources.SetDate. It returns the Citation ids.
func seedScale(t *testing.T, w *world, perSource int) [][]byte {
	t.Helper()
	typ, err := sourcetypes.Lookup(w.c, "census", vocabkey.OriginProvenencia)
	if err != nil {
		t.Fatal(err)
	}
	keys := []string{}
	for _, sv := range scaleValues {
		for k := range sv.values {
			keys = append(keys, k)
		}
	}
	tx, err := w.db.Begin()
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = tx.Rollback() }()
	res, err := metadatafields.ResolveKeysTx(tx, keys, vocabkey.OriginProvenencia)
	if err != nil {
		t.Fatal(err)
	}
	exec := func(q string, args ...any) {
		t.Helper()
		if _, err := tx.Exec(q, args...); err != nil {
			t.Fatal(err)
		}
	}
	n := strconv.Itoa
	var meta, cit int
	values := func(table, owner string, ownerID []byte, vals map[string]string) {
		for key, text := range vals {
			meta++
			exec(`INSERT INTO `+table+` (id, `+owner+`, field_id, value_text) VALUES (?, ?, ?, ?)`,
				databasetest.BenchID(7, meta), ownerID, res.IDs[key], text)
		}
	}
	var ids [][]byte
	var sourceIDs [][]byte
	for s := 1; s <= scaleSources; s++ {
		srcID := databasetest.BenchID(1, s)
		sourceIDs = append(sourceIDs, srcID)
		exec(`INSERT INTO sources (id, ref, source_type_id, title) VALUES (?, ?, ?, ?)`, srcID, "SRC-B"+n(s), typ.ID, "Census "+n(s))
		values(scaleValues[0].table, scaleValues[0].owner, srcID, scaleValues[0].values)
		var arts, graphs [][]byte
		for a := 0; a < scaleArtifactsPerSrc; a++ {
			i := (s-1)*scaleArtifactsPerSrc + a + 1
			id := databasetest.BenchID(2, i)
			arts = append(arts, id)
			exec(`INSERT INTO artifacts (id, ref, source_id, label) VALUES (?, ?, ?, ?)`, id, "ART-B"+n(i), srcID, "Film "+n(i))
			values(scaleValues[1].table, scaleValues[1].owner, id, scaleValues[1].values)
		}
		for g := 0; g < scaleGraphsPerSrc; g++ {
			i := (s-1)*scaleGraphsPerSrc + g + 1
			id := databasetest.BenchID(3, i)
			graphs = append(graphs, id)
			exec(`INSERT INTO evidence_graphs (id, ref, source_id, name) VALUES (?, ?, ?, ?)`, id, "GPH-B"+n(i), srcID, "Graph "+n(i))
			values(scaleValues[2].table, scaleValues[2].owner, id, scaleValues[2].values)
			for _, a := range arts {
				exec(`INSERT INTO evidence_graph_artifacts (graph_id, artifact_id) VALUES (?, ?)`, id, a)
			}
		}
		for k := 0; k < perSource; k++ {
			cit++
			id := databasetest.BenchID(4, cit)
			ids = append(ids, id)
			exec(`INSERT INTO citations (id, ref, artifact_id, graph_id, locator_json) VALUES (?, ?, ?, ?, ?)`,
				id, "CIT-B"+n(cit), arts[k%scaleArtifactsPerSrc], graphs[k%scaleGraphsPerSrc], pageLocator("14"))
		}
	}
	if err := tx.Commit(); err != nil {
		t.Fatal(err)
	}
	for _, id := range sourceIDs {
		_, _, err := writes.Run(w.c, writes.Op{Action: "set_source_date", UserID: w.userID},
			func(tx *database.Tx) (sources.Source, []rowchange.Change, error) {
				return sources.SetDate(tx, w.userID, id, datevaluetest.YMD(1880, 0, 0), valuemark.Mark{})
			})
		if err != nil {
			t.Fatal(err)
		}
	}
	return ids
}

// TestRenderScale holds the map's Scale: a Person page citing 30 Sources renders
// up to 300 Citations, and a value with 1,200 records renders in one call. The
// reads are a fixed number of SELECTs, growing only by batches of 500.
func TestRenderScale(t *testing.T) {
	for _, tt := range []struct {
		citations, perSource, selects int
		budget                        time.Duration
	}{
		{300, 10, 9, 100 * time.Millisecond},
		{1200, 40, 11, 400 * time.Millisecond},
	} {
		t.Run(strconv.Itoa(tt.citations), func(t *testing.T) {
			w := newWorld(t)
			ids := seedScale(t, w, tt.perSource)
			if len(ids) != tt.citations {
				t.Fatalf("seeded %d Citations, want %d", len(ids), tt.citations)
			}
			render := func() []RenderedCitation {
				got, err := Render(w.c, ids, w.c.Graph().PageInputs())
				if err != nil {
					t.Fatal(err)
				}
				return got
			}
			selects := databasetest.CountSelects(t, w.c)
			got := render() // warms the catalog
			selects.Reset()
			render()
			if n := selects.N(); n != tt.selects {
				t.Errorf("%d SELECTs for %d Citations, want %d", n, tt.citations, tt.selects)
			}
			if len(got) != tt.citations {
				t.Fatalf("got %d results, want %d", len(got), tt.citations)
			}
			for i, r := range got {
				if r.Full.Plain() != censusFull {
					t.Fatalf("result %d = %q, want %q", i, r.Full.Plain(), censusFull)
				}
			}
			databasetest.WithinBudget(t, strconv.Itoa(tt.citations)+" Citations", databasetest.Warm(func() { render() }), tt.budget)
		})
	}
}
