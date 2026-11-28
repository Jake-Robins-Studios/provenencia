package citationrender

import (
	"bytes"
	"database/sql"
	"errors"
	"reflect"
	"strconv"
	"strings"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/artifacts"
	"github.com/Jake-Robins-Studios/provenencia/core/database/artifacts/artifactstest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/citations"
	"github.com/Jake-Robins-Studios/provenencia/core/database/databasetest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/dbtest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencegraphs"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencegraphs/evidencegraphstest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields/metadatafieldstest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcemetadata"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sources"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes/sourcetypestest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcevocab/sourcevocabtest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/users"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue/datevaluetest"
	"github.com/Jake-Robins-Studios/provenencia/core/ref"
	"github.com/Jake-Robins-Studios/provenencia/core/valuemark"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
)

// world is a catalog with a user and the product seed.
type world struct {
	t      *testing.T
	c      *database.Catalog
	db     *sql.DB
	userID []byte
	cites  int
}

func newWorld(t *testing.T) *world {
	t.Helper()
	userID := []byte{16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1}
	c, err := database.Create(t.TempDir(), "t.provenencia")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = c.Close() })
	r, err := ref.Mint(ref.PrefixUser)
	if err != nil {
		t.Fatal(err)
	}
	if err := users.Upsert(c, userID, "Jake", r); err != nil {
		t.Fatal(err)
	}
	if err := sourcevocabtest.Install(c); err != nil {
		t.Fatal(err)
	}
	return &world{t: t, c: c, db: dbtest.MustDB(t, c), userID: userID}
}

func (w *world) fieldID(key string) []byte {
	w.t.Helper()
	f, err := metadatafields.Lookup(w.c, key, vocabkey.OriginProvenencia)
	if err != nil {
		w.t.Fatal(err)
	}
	return f.ID
}

// userField makes a field with no unknown text, or finds the one it made, and
// returns its id.
func (w *world) userField(key string) []byte {
	w.t.Helper()
	id, err := metadatafieldstest.Upsert(w.c, metadatafields.Field{
		Key: key, Origin: vocabkey.OriginProvenencia, Label: strings.ToUpper(key), DataType: metadatafields.DataTypeText,
	})
	if err != nil {
		w.t.Fatal(err)
	}
	return id
}

// newType makes a type whose formats are written with keys.
func (w *world) newType(label string, f sourcetypes.Formats) sourcetypes.Type {
	w.t.Helper()
	typ, _, err := writes.Run(w.c, writes.Op{Action: "create_source_type", UserID: w.userID},
		func(tx *database.Tx) (sourcetypes.Type, []rowchange.Change, error) {
			return sourcetypes.Create(tx, sourcetypes.CreateInput{Label: label})
		})
	if err != nil {
		w.t.Fatal(err)
	}
	view, err := sourcetypestest.SetFormats(w.c, w.userID, typ.ID, f)
	if err != nil {
		w.t.Fatal(err)
	}
	if len(view.Diagnostics) > 0 {
		w.t.Fatalf("formats %+v: %+v", f, view.Diagnostics)
	}
	return typ
}

func (w *world) source(typeID []byte, title string) sources.Source {
	w.t.Helper()
	s, _, err := writes.Run(w.c, writes.Op{Action: "create_source", UserID: w.userID},
		func(tx *database.Tx) (sources.Source, []rowchange.Change, error) {
			return sources.Create(tx, w.userID, sources.CreateInput{SourceTypeID: typeID, Title: title})
		})
	if err != nil {
		w.t.Fatal(err)
	}
	return s
}

func (w *world) setDate(sourceID []byte, d *datevalue.Value, mark valuemark.Mark) {
	w.t.Helper()
	_, _, err := writes.Run(w.c, writes.Op{Action: "set_source_date", UserID: w.userID},
		func(tx *database.Tx) (sources.Source, []rowchange.Change, error) {
			return sources.SetDate(tx, w.userID, sourceID, d, mark)
		})
	if err != nil {
		w.t.Fatal(err)
	}
}

// set stores a metadata value by field key at an owner.
func (w *world) set(level vocabkey.Level, ownerID []byte, key, text string, mark valuemark.Mark) {
	w.t.Helper()
	w.setField(level, ownerID, w.fieldID(key), text, mark)
}

func (w *world) setField(level vocabkey.Level, ownerID, fieldID []byte, text string, mark valuemark.Mark) {
	w.t.Helper()
	_, _, err := writes.Run(w.c, writes.Op{Action: "set_metadata", UserID: w.userID},
		func(tx *database.Tx) (sourcemetadata.Row, []rowchange.Change, error) {
			return sourcemetadata.Set(tx, w.userID, sourcemetadata.Owner{Level: level, ID: ownerID},
				sourcemetadata.Input{FieldID: fieldID, ValueText: text, Mark: mark})
		})
	if err != nil {
		w.t.Fatal(err)
	}
}

func (w *world) artifact(sourceID []byte, label string) artifacts.Artifact {
	w.t.Helper()
	a, err := artifactstest.Create(w.c, w.userID, artifacts.CreateInput{SourceID: sourceID, Label: label})
	if err != nil {
		w.t.Fatal(err)
	}
	return a
}

func (w *world) graph(sourceID []byte) evidencegraphs.Graph {
	w.t.Helper()
	return evidencegraphstest.SoleGraph(w.t, w.c, sourceID)
}

// pageLocator is a Citation locator stored before S15-59, with a page_label
// alone. Reads ignore the label, so the selector is no page.
func pageLocator(label string) string {
	return `{"version":1,"selectors":[{"type":"page","page_label":"` + label + `"}]}`
}

// cite inserts a Citation directly, as evidencegraphstest.ScaleSeed does.
func (w *world) cite(artifactID, graphID []byte, label, locatorJSON string) []byte {
	w.t.Helper()
	w.cites++
	id := databasetest.BenchID(4, w.cites)
	_, err := w.db.Exec(`INSERT INTO citations (id, ref, artifact_id, graph_id, locator_json, label) VALUES (?, ?, ?, ?, ?, ?)`,
		id, "CIT-T"+strconv.Itoa(w.cites), artifactID, graphID, locatorJSON, database.NullString(label))
	if err != nil {
		w.t.Fatal(err)
	}
	return id
}

// craft runs fn with foreign keys off, as a catalog the app never wrote.
func (w *world) craft(fn func()) {
	w.t.Helper()
	if _, err := w.db.Exec(`PRAGMA foreign_keys=OFF`); err != nil {
		w.t.Fatal(err)
	}
	defer func() {
		if _, err := w.db.Exec(`PRAGMA foreign_keys=ON`); err != nil {
			w.t.Fatal(err)
		}
	}()
	fn()
}

func (w *world) render(ids ...[]byte) []RenderedCitation {
	w.t.Helper()
	got, err := Render(w.c, ids, w.c.Graph().PageInputs())
	if err != nil {
		w.t.Fatal(err)
	}
	return got
}

// census is AC-1.1's catalog: the seeded census type, a dated Source holding
// its values, an Artifact and a graph holding theirs, and a Citation on page
// "14".
type census struct {
	*world
	typ      sourcetypes.Type
	src      sources.Source
	art      artifacts.Artifact
	graph    evidencegraphs.Graph
	citation []byte
}

const (
	censusFull  = "1880 Westmark census, Calder County, Westmark, population schedule, ED 236, piece 1047, fol. 22, p. 14, schedule 9, dwelling 112, family 118, line 14, Ada Robins; digital image, Westmark Heritage (https://example.org/calder/1880 : accessed 12 March 2025); citing county film 7, item 3."
	censusShort = "1880 Westmark census, Calder County, Westmark, ED 236, fol. 22, p. 14, dwell. 112, fam. 118, Ada Robins."
	censusList  = "Calder County, Westmark. 1880 Westmark census, population schedule."
)

func newCensus(t *testing.T) *census {
	t.Helper()
	w := newWorld(t)
	typ, err := sourcetypes.Lookup(w.c, "census", vocabkey.OriginProvenencia)
	if err != nil {
		t.Fatal(err)
	}
	src := w.source(typ.ID, "1880 census of Calder County")
	w.setDate(src.ID, datevaluetest.YMD(1880, 0, 0), valuemark.Mark{})
	art := w.artifact(src.ID, "County film")
	graph := w.graph(src.ID)
	m := valuemark.Mark{}
	for k, v := range map[string]string{
		"creator": "Westmark", "jurisdiction": "Calder County, Westmark", "schedule": "population schedule",
		"enumeration_district": "236", "piece": "1047", "folio": "22",
	} {
		w.set(vocabkey.LevelSource, src.ID, k, v, m)
	}
	for k, v := range map[string]string{
		"schedule_number": "9", "dwelling_number": "112", "family_number": "118", "line_number": "14", "item": "Ada Robins",
	} {
		w.set(vocabkey.LevelGraph, graph.ID, k, v, m)
	}
	for k, v := range map[string]string{
		"format": "digital image", "provider": "Westmark Heritage", "url": "https://example.org/calder/1880",
		"accessed_date": "12 March 2025", "citing": "county film 7, item 3",
	} {
		w.set(vocabkey.LevelArtifact, art.ID, k, v, m)
	}
	cit := w.cite(art.ID, graph.ID, "", pageLocator("14"))
	w.set(vocabkey.LevelCitation, cit, "page", "14", m)
	return &census{world: w, typ: typ, src: src, art: art, graph: graph, citation: cit}
}

// TestRenderNearestLevel: a format names a field with no level and the render
// reads it from the nearest level that holds a value (AC-1.1 – AC-1.3).
func TestRenderNearestLevel(t *testing.T) {
	m := valuemark.Mark{}
	build := func(t *testing.T, set func(w *world, src sources.Source, art, graph, cit []byte)) string {
		t.Helper()
		w := newWorld(t)
		typ, err := sourcetypes.Lookup(w.c, "census", vocabkey.OriginProvenencia)
		if err != nil {
			t.Fatal(err)
		}
		src := w.source(typ.ID, "1880 census of Calder County")
		art := w.artifact(src.ID, "County film")
		graph := w.graph(src.ID)
		cit := w.cite(art.ID, graph.ID, "", pageLocator("14"))
		set(w, src, art.ID, graph.ID, cit)
		return w.render(cit)[0].Full.Plain()
	}
	t.Run("AC-1.1 a Provider typed on the Source", func(t *testing.T) {
		got := build(t, func(w *world, src sources.Source, art, graph, cit []byte) {
			w.set(vocabkey.LevelSource, src.ID, "provider", "Ancestry", m)
			w.set(vocabkey.LevelArtifact, art, "format", "digital image", m)
		})
		if want := "; digital image, Ancestry"; !strings.Contains(got, want) {
			t.Errorf("full = %q, want it to hold %q", got, want)
		}
	})
	t.Run("AC-1.2 the graph's line number over the Source's", func(t *testing.T) {
		got := build(t, func(w *world, src sources.Source, art, graph, cit []byte) {
			w.set(vocabkey.LevelGraph, graph, "line_number", "14", m)
			w.set(vocabkey.LevelSource, src.ID, "line_number", "9", m)
		})
		if !strings.Contains(got, ", line 14") || strings.Contains(got, "line 9") {
			t.Errorf("full = %q, want line 14", got)
		}
	})
	t.Run("AC-1.3 the Artifact's item over the Source's", func(t *testing.T) {
		got := build(t, func(w *world, src sources.Source, art, graph, cit []byte) {
			w.set(vocabkey.LevelArtifact, art, "item", "From the film", m)
			w.set(vocabkey.LevelSource, src.ID, "item", "From the record", m)
		})
		if !strings.Contains(got, "From the film") || strings.Contains(got, "From the record") {
			t.Errorf("full = %q, want the Artifact's item", got)
		}
	})
	t.Run("AC-1.4 an unknown value at the graph stops the walk", func(t *testing.T) {
		got := build(t, func(w *world, src sources.Source, art, graph, cit []byte) {
			w.set(vocabkey.LevelGraph, graph, "line_number", "", valuemark.Mark{Unknown: true})
			w.set(vocabkey.LevelSource, src.ID, "line_number", "9", m)
		})
		if strings.Contains(got, "line") {
			t.Errorf("full = %q, want no line number: the unknown value answers, so the Source's 9 is not read", got)
		}
	})
	t.Run("AC-2.1 the Citation's line number over the graph's", func(t *testing.T) {
		got := build(t, func(w *world, src sources.Source, art, graph, cit []byte) {
			w.set(vocabkey.LevelCitation, cit, "line_number", "21", m)
			w.set(vocabkey.LevelGraph, graph, "line_number", "14", m)
		})
		if !strings.Contains(got, ", line 21") || strings.Contains(got, "line 14") {
			t.Errorf("full = %q, want line 21", got)
		}
	})
	t.Run("AC-2.2 an unknown value on the Citation stops the walk", func(t *testing.T) {
		got := build(t, func(w *world, src sources.Source, art, graph, cit []byte) {
			w.set(vocabkey.LevelCitation, cit, "line_number", "", valuemark.Mark{Unknown: true})
			w.set(vocabkey.LevelGraph, graph, "line_number", "14", m)
		})
		if strings.Contains(got, "line") {
			t.Errorf("full = %q, want no line number", got)
		}
	})
	t.Run("AC-2.4 the list form reads the Source alone", func(t *testing.T) {
		w := newWorld(t)
		typ, err := sourcetypes.Lookup(w.c, "census", vocabkey.OriginProvenencia)
		if err != nil {
			t.Fatal(err)
		}
		src := w.source(typ.ID, "1880 census of Calder County")
		art := w.artifact(src.ID, "County film")
		graph := w.graph(src.ID)
		cit := w.cite(art.ID, graph.ID, "", pageLocator("14"))
		w.set(vocabkey.LevelSource, src.ID, "jurisdiction", "Calder County, Westmark", m)
		w.set(vocabkey.LevelCitation, cit, "jurisdiction", "Elsewhere", m)
		if full := w.render(cit)[0].Full.Plain(); !strings.Contains(full, "Elsewhere") {
			t.Errorf("full = %q, want the Citation's jurisdiction", full)
		}
		list, err := RenderPreview(w.c, PreviewInput{Form: citationformat.FormList, Target: Target{CitationID: cit}})
		if err != nil {
			t.Fatal(err)
		}
		got := list.Rendered.Plain()
		if !strings.Contains(got, "Calder County, Westmark") || strings.Contains(got, "Elsewhere") {
			t.Errorf("list = %q, want the Source's jurisdiction alone", got)
		}
	})
}

func TestRenderCensus(t *testing.T) {
	w := newCensus(t)
	got := w.render(w.citation)
	if len(got) != 1 {
		t.Fatalf("got %d, want 1", len(got))
	}
	wantRuns := []citationformat.Run{
		{Text: "1880 Westmark census, Calder County, Westmark, population schedule, ED 236, piece 1047, fol. 22, p. 14, schedule 9, dwelling 112, family 118, line 14, Ada Robins; digital image, "},
		{Text: "Westmark Heritage", Italic: true},
		{Text: " (https://example.org/calder/1880 : accessed 12 March 2025); citing county film 7, item 3."},
	}
	if !reflect.DeepEqual(got[0].Full.Runs, wantRuns) {
		t.Errorf("full runs\n got %+v\nwant %+v", got[0].Full.Runs, wantRuns)
	}
	if got[0].Full.Plain() != censusFull || got[0].Short.Plain() != censusShort {
		t.Errorf("full %q\nshort %q", got[0].Full.Plain(), got[0].Short.Plain())
	}
}

// TestRenderLocatorLabelAlone is AC-1.2: a stored locator's page_label is
// ignored on read and prints nothing when no level holds a page value.
func TestRenderLocatorLabelAlone(t *testing.T) {
	w := newCensus(t)
	id := w.cite(w.art.ID, w.graph.ID, "", pageLocator("23"))
	got := w.render(id)
	if len(got) != 1 {
		t.Fatalf("got %d, want 1", len(got))
	}
	if full := got[0].Full.Plain(); strings.Contains(full, ", p.") {
		t.Errorf("full = %q, want no page group", full)
	}
}

func TestRender(t *testing.T) {
	m := valuemark.Mark{}
	one := func(t *testing.T, w *world, ids ...[]byte) RenderedCitation {
		t.Helper()
		got := w.render(ids...)
		if len(got) != 1 {
			t.Fatalf("got %d results, want 1: %+v", len(got), got)
		}
		return got[0]
	}
	// base is a Source titled "Family Bible" of a type with the given full
	// format, an Artifact "Scan" and its default graph.
	base := func(t *testing.T, full, short string, fields ...string) (*world, sourcetypes.Type, sources.Source, artifacts.Artifact, evidencegraphs.Graph) {
		t.Helper()
		w := newWorld(t)
		for _, key := range fields {
			w.userField(key)
		}
		typ := w.newType("Book of hours", sourcetypes.Formats{Full: full, Short: short})
		src := w.source(typ.ID, "Family Bible")
		return w, typ, src, w.artifact(src.ID, "Scan"), w.graph(src.ID)
	}

	// stored with a page_label; the file page still reads
	imageLocator := `{"version":1,"selectors":[{"type":"artifact"},{"type":"page","artifact_page":37,"page_label":"23"}]}`
	for _, tc := range []struct {
		name         string
		full         string
		fields       []string
		label        string
		locator      string
		setup        func(w *world, src sources.Source)
		want         string // the full text, unless dropsGroup
		dropsGroup   bool   // no runs
		wantTypeName bool
	}{
		{name: "each built-in", full: `{source.title}/{source.type}/{artifact.label}/{graph.name}/{citation.label}`, label: "entry", locator: pageLocator("1"), wantTypeName: true},
		{name: "no short format leaves the short empty", full: `{source.title}`, locator: pageLocator("1"), want: "Family Bible"},
		{name: "the image is the file page", full: `image {citation.image}`, locator: imageLocator, want: "image 37"},
		{name: "no file page drops the image group", full: `[image {citation.image}]`, locator: pageLocator("23"), dropsGroup: true},
		{
			name: "an unknown value with no unknown text drops its group", full: `Bible[ x {meta.k}]`, fields: []string{"k"}, locator: pageLocator("1"),
			setup: func(w *world, src sources.Source) {
				w.setField(vocabkey.LevelSource, src.ID, w.userField("k"), "", valuemark.Mark{Unknown: true})
			},
			want: "Bible",
		},
		{
			name: "a blank value with a stored supplied mark prints nothing", full: `Bible[ x {meta.k}]`, fields: []string{"k"}, locator: pageLocator("1"),
			setup: func(w *world, src sources.Source) {
				k := w.userField("k")
				w.setField(vocabkey.LevelSource, src.ID, k, "v", valuemark.Mark{})
				if _, err := w.db.Exec(`UPDATE source_metadata SET value_text = '', is_supplied = 1 WHERE source_id = ? AND field_id = ?`, src.ID, k); err != nil {
					w.t.Fatal(err)
				}
			},
			want: "Bible",
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			w, typ, src, art, graph := base(t, tc.full, "", tc.fields...)
			if tc.setup != nil {
				tc.setup(w, src)
			}
			r := one(t, w, w.cite(art.ID, graph.ID, tc.label, tc.locator))
			switch {
			case tc.dropsGroup:
				if len(r.Full.Runs) != 0 {
					t.Errorf("got %+v", r)
				}
			case tc.wantTypeName:
				want := "Family Bible/" + typ.Label + "/Scan/" + graph.Name + "/entry"
				if r.Full.Plain() != want {
					t.Errorf("full = %q, want %q", r.Full.Plain(), want)
				}
			default:
				if r.Full.Plain() != tc.want {
					t.Errorf("full = %q, want %q", r.Full.Plain(), tc.want)
				}
			}
			if len(r.Short.Runs) != 0 { // every case here has no short format
				t.Errorf("short = %+v", r.Short)
			}
		})
	}
	t.Run("a stored full text that does not parse leaves the fallback", func(t *testing.T) {
		w, typ, _, art, graph := base(t, `{source.title}`, "")
		if _, err := w.db.Exec(`UPDATE source_types SET citation_full = '{source.title' WHERE id = ?`, typ.ID); err != nil {
			t.Fatal(err)
		}
		r := one(t, w, w.cite(art.ID, graph.ID, "", pageLocator("1")))
		if len(r.Full.Runs) != 0 {
			t.Errorf("got %+v", r)
		}
	})
	t.Run("a field named by key in a stored format answers nothing", func(t *testing.T) {
		w, typ, _, art, graph := base(t, `{source.title}`, "")
		w.userField("k")
		if _, err := w.db.Exec(`UPDATE source_types SET citation_full = '{meta.k}' WHERE id = ?`, typ.ID); err != nil {
			t.Fatal(err)
		}
		r := one(t, w, w.cite(art.ID, graph.ID, "", pageLocator("1")))
		if r.Full.Plain() != "" {
			t.Errorf("full = %q", r.Full.Plain())
		}
	})
	t.Run("a Citation's Source is its graph's", func(t *testing.T) {
		w := newWorld(t)
		k := w.userField("k")
		typ := w.newType("Book of hours", sourcetypes.Formats{Full: `{source.title}: {meta.k}`})
		a := w.source(typ.ID, "Source A")
		b := w.source(typ.ID, "Source B")
		artB := w.artifact(b.ID, "Scan B")
		w.setField(vocabkey.LevelArtifact, artB.ID, k, "from B", m)
		graphA := w.graph(a.ID)
		var id []byte
		w.craft(func() { id = w.cite(artB.ID, graphA.ID, "", pageLocator("1")) })
		r := one(t, w, id)
		if r.Full.Plain() != "Source A: from B" {
			t.Errorf("full = %q", r.Full.Plain())
		}
	})
	t.Run("a Citation with a missing graph row has no format to render", func(t *testing.T) {
		w, _, _, art, _ := base(t, `{source.title}`, "")
		var id []byte
		w.craft(func() { id = w.cite(art.ID, databasetest.BenchID(3, 99), "", pageLocator("1")) })
		r := one(t, w, id)
		if len(r.Full.Runs) != 0 {
			t.Errorf("full = %q", r.Full.Plain())
		}
	})

	t.Run("order, repeats and missing ids", func(t *testing.T) {
		w, _, _, art, graph := base(t, `{source.title}`, "")
		c1 := w.cite(art.ID, graph.ID, "", pageLocator("1"))
		c3 := w.cite(art.ID, graph.ID, "", pageLocator("3"))
		x := databasetest.BenchID(4, 999)
		in := w.c.Graph().PageInputs()
		got, err := Render(w.c, [][]byte{c3, c1, c3, x}, in)
		if err != nil {
			t.Fatal(err)
		}
		if len(got) != 2 || !bytes.Equal(got[0].CitationID, c3) || !bytes.Equal(got[1].CitationID, c1) {
			t.Fatalf("got %+v, want C3 then C1", got)
		}
		_, graphs, srcs := in.Lists()
		if len(graphs) != 1 || !bytes.Equal(graphs[0], graph.ID) || len(srcs) != 1 {
			t.Errorf("inputs graphs %x sources %x", graphs, srcs)
		}
	})
	t.Run("no ids", func(t *testing.T) {
		w := newWorld(t)
		in := w.c.Graph().PageInputs()
		got, err := Render(w.c, nil, in)
		if err != nil || got != nil {
			t.Fatalf("got %+v, %v", got, err)
		}
		if _, graphs, srcs := in.Lists(); len(graphs) != 0 || len(srcs) != 0 {
			t.Errorf("recorded %x %x", graphs, srcs)
		}
	})
	t.Run("an id that is not 16 bytes", func(t *testing.T) {
		w := newWorld(t)
		_, err := Render(w.c, [][]byte{make([]byte, 15)}, w.c.Graph().PageInputs())
		if !errors.Is(err, citations.ErrInvalid) {
			t.Fatalf("got %v, want citations.ErrInvalid", err)
		}
	})
}

// TestRenderUnknownAndSupplied is AC-1.6.
func TestRenderUnknownAndSupplied(t *testing.T) {
	w := newWorld(t)
	typ := w.newType("Pamphlet", sourcetypes.Formats{Full: `{meta.publisher}; {source.date}; p. {meta.page}.`})
	a := w.source(typ.ID, "Source A")
	b := w.source(typ.ID, "Source B")
	w.set(vocabkey.LevelSource, a.ID, "publisher", "", valuemark.Mark{Unknown: true})
	w.setDate(a.ID, nil, valuemark.Mark{Unknown: true})
	w.set(vocabkey.LevelSource, b.ID, "publisher", "Ashby Press", valuemark.Mark{Supplied: true})
	w.setDate(b.ID, datevaluetest.About(1880, 0, 0), valuemark.Mark{Supplied: true})
	artA, artB := w.artifact(a.ID, "Scan"), w.artifact(b.ID, "Scan")
	ca := w.cite(artA.ID, w.graph(a.ID).ID, "", `{"version":1,"selectors":[{"type":"page","page_unknown":true}]}`)
	cb := w.cite(artB.ID, w.graph(b.ID).ID, "", `{"version":1,"selectors":[{"type":"page","page_label":"23","page_supplied":true}]}`)
	w.set(vocabkey.LevelCitation, ca, "page", "", valuemark.Mark{Unknown: true})
	w.set(vocabkey.LevelCitation, cb, "page", "23", valuemark.Mark{Supplied: true})
	got := w.render(ca, cb)
	if len(got) != 2 {
		t.Fatalf("got %d", len(got))
	}
	if got[0].Full.Plain() != "n.p.; n.d.; p. unpaginated." || got[1].Full.Plain() != "[Ashby Press]; [ca. 1880]; p. [23]." {
		t.Errorf("got %q and %q", got[0].Full.Plain(), got[1].Full.Plain())
	}
}

func TestRenderLimits(t *testing.T) {
	t.Run("more ids than the cap, before any query", func(t *testing.T) {
		w := newWorld(t)
		selects := databasetest.CountSelects(t, w.c)
		ids := make([][]byte, MaxCitations+1)
		for i := range ids {
			ids[i] = databasetest.BenchID(4, i)
		}
		if _, err := Render(w.c, ids, w.c.Graph().PageInputs()); !errors.Is(err, citations.ErrInvalid) {
			t.Fatalf("got %v, want citations.ErrInvalid", err)
		}
		if n := selects.N(); n != 0 {
			t.Errorf("%d SELECTs ran, want 0", n)
		}
	})
	// Each Citation renders 64 KiB of full and 64 KiB of short.
	big := strings.Repeat(`{source.title}`, 285)
	over := func(t *testing.T, n int) ([]RenderedCitation, error) {
		t.Helper()
		w := newWorld(t)
		typ := w.newType("Big", sourcetypes.Formats{Full: big, Short: big})
		src := w.source(typ.ID, strings.Repeat("t", 255))
		art, graph := w.artifact(src.ID, "Scan"), w.graph(src.ID)
		ids := make([][]byte, n)
		for i := range ids {
			ids[i] = w.cite(art.ID, graph.ID, "", pageLocator("1"))
		}
		return Render(w.c, ids, w.c.Graph().PageInputs())
	}
	t.Run("more rendered text than the cap", func(t *testing.T) {
		if _, err := over(t, 70); !errors.Is(err, citations.ErrInvalid) {
			t.Fatalf("got %v, want citations.ErrInvalid", err)
		}
	})
	t.Run("under the cap", func(t *testing.T) {
		got, err := over(t, 60)
		if err != nil || len(got) != 60 {
			t.Fatalf("got %d, %v", len(got), err)
		}
		if n := len(got[0].Full.Plain()); n != citationformat.MaxRenderedBytes {
			t.Errorf("full is %d bytes, want %d", n, citationformat.MaxRenderedBytes)
		}
	})
}

// TestRenderBudgetSignal: render refuses an over-budget batch with its own
// signal, not citations.ErrInvalid, so renderAll leaves out only that case.
func TestRenderBudgetSignal(t *testing.T) {
	w := newWorld(t)
	ids := seedScale(t, w, 1)
	tx, err := w.db.Begin()
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = tx.Rollback() }()
	_, _, err = render(tx, ids[:1], w.c.Graph().PageInputs(), 1)
	if !errors.Is(err, errOverBudget) || errors.Is(err, citations.ErrInvalid) {
		t.Fatalf("got %v, want errOverBudget alone", err)
	}
	got, spent, err := render(tx, ids[:1], w.c.Graph().PageInputs(), MaxBatchBytes)
	if err != nil || len(got) != 1 || spent != size(got[0].Full)+size(got[0].Short) {
		t.Fatalf("got %d, spent %d, %v", len(got), spent, err)
	}
}

// TestRenderAll: any number of Citations render, a batch at a time, within one
// byte budget for the whole call.
func TestRenderAll(t *testing.T) {
	w := newWorld(t)
	ids := seedScale(t, w, 10) // 300 Citations that render alike
	// inTx runs f on a read transaction that is over before the next call.
	inTx := func(f func(tx *sql.Tx) ([]RenderedCitation, error)) ([]RenderedCitation, error) {
		tx, err := w.db.Begin()
		if err != nil {
			t.Fatal(err)
		}
		defer func() { _ = tx.Rollback() }()
		return f(tx)
	}
	one, err := inTx(func(tx *sql.Tx) ([]RenderedCitation, error) {
		got, _, err := render(tx, ids[:1], w.c.Graph().PageInputs(), MaxBatchBytes)
		return got, err
	})
	if err != nil || len(one) != 1 {
		t.Fatalf("one Citation: %v %v", one, err)
	}
	unit := size(one[0].Full) + size(one[0].Short)
	if unit == 0 {
		t.Fatal("a rendered Citation has no text")
	}
	idsOf := func(rs []RenderedCitation) [][]byte {
		var out [][]byte
		for _, r := range rs {
			out = append(out, r.CitationID)
		}
		return out
	}
	for _, tc := range []struct {
		name         string
		ids          [][]byte
		batch, limit int
		want         [][]byte
		err          error
	}{
		{"every Citation in input order", ids, 120, MaxBatchBytes, ids, nil},
		{"a repeat past the first batch renders once", append(append([][]byte{}, ids...), ids[0]), 120, MaxBatchBytes, ids, nil},
		{"batches over the budget are left out", ids[:250], 100, 60 * unit, ids[200:250], nil},
		{"the budget left decides the next batch", ids[:250], 100, 150 * unit, append(append([][]byte{}, ids[:100]...), ids[200:250]...), nil},
		{"an id that is not 16 bytes", [][]byte{ids[0], make([]byte, 15)}, 100, MaxBatchBytes, nil, citations.ErrInvalid},
	} {
		t.Run(tc.name, func(t *testing.T) {
			if tc.err != nil {
				if _, err := RenderAll(w.c, tc.ids, w.c.Graph().PageInputs()); !errors.Is(err, tc.err) {
					t.Fatalf("err %v, want %v", err, tc.err)
				}
				return
			}
			rs, err := inTx(func(tx *sql.Tx) ([]RenderedCitation, error) {
				return renderAll(tx, tc.ids, w.c.Graph().PageInputs(), tc.batch, tc.limit)
			})
			if err != nil {
				t.Fatal(err)
			}
			got := idsOf(rs)
			if !reflect.DeepEqual(got, tc.want) {
				t.Fatalf("rendered %d Citations, want %d", len(got), len(tc.want))
			}
		})
	}
	if rs, err := RenderAll(w.c, nil, w.c.Graph().PageInputs()); err != nil || rs != nil {
		t.Fatalf("no ids: %v %v", rs, err)
	}
	if rs, err := RenderAll(w.c, ids, w.c.Graph().PageInputs()); err != nil || len(rs) != len(ids) {
		t.Fatalf("RenderAll over %d ids: %d, %v", len(ids), len(rs), err)
	}
}
