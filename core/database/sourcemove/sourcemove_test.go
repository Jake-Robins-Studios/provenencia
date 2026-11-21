package sourcemove_test

import (
	"bytes"
	"errors"
	"slices"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/artifacts"
	"github.com/Jake-Robins-Studios/provenencia/core/database/artifacts/artifactstest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/catalogmodel"
	"github.com/Jake-Robins-Studios/provenencia/core/database/dbtest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/effects"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencegraphs"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencegraphs/evidencegraphstest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/evidencelayer/evidencelayertest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields"
	"github.com/Jake-Robins-Studios/provenencia/core/database/observations"
	"github.com/Jake-Robins-Studios/provenencia/core/database/promote"
	"github.com/Jake-Robins-Studios/provenencia/core/database/promote/promotetest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcecredibility"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcecredibilitygrades"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcecredibilitygrades/sourcecredibilitygradestest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcemetadata"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcemove"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sources"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjects"
	"github.com/Jake-Robins-Studios/provenencia/core/database/subjects/subjectstest"
	"github.com/Jake-Robins-Studios/provenencia/core/namevalue/namevaluetest"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
	"github.com/google/uuid"
)

var userID = evidencelayertest.UserID

// world is a catalog with a Source S1 ("Register": its Default graph and the
// Artifact "Scan" linked to it) and an empty-handed target Source S2.
type world struct {
	*evidencelayertest.Records
	s2 sources.Source
}

func newWorld(t *testing.T) *world {
	t.Helper()
	r := evidencelayertest.New(t)
	s2, _ := r.NewSource("Target")
	return &world{Records: r, s2: s2}
}

// art is an Artifact of src on no graph.
func (w *world) art(src sources.Source, label string) artifacts.Artifact {
	w.T.Helper()
	a, err := artifactstest.Create(w.C, userID, artifacts.CreateInput{
		SourceID: src.ID, Label: label, Graphs: evidencegraphs.GraphLinks{Given: true},
	})
	evidencelayertest.Must(w.T, err)
	return a
}

// graph is a named graph of src linked to the Artifacts.
func (w *world) graph(src sources.Source, name string, arts ...artifacts.Artifact) evidencegraphs.Graph {
	w.T.Helper()
	ids := make([][]byte, len(arts))
	for i, a := range arts {
		ids[i] = a.ID
	}
	return evidencegraphstest.Create(w.T, w.C, userID, src.ID, name, ids...)
}

func (w *world) people(g evidencegraphs.Graph, n int) []subjects.Subject {
	w.T.Helper()
	var out []subjects.Subject
	for range n {
		out = append(out, subjectstest.On(w.T, w.C, userID, g.ID, "person", "P"))
	}
	return out
}

func (w *world) credibility(src sources.Source, key string) {
	w.T.Helper()
	evidencelayertest.Must(w.T, sourcecredibilitygradestest.Install(w.C))
	g, err := sourcecredibilitygrades.Lookup(w.C, key, vocabkey.OriginProvenencia)
	evidencelayertest.Must(w.T, err)
	w.Run("set_credibility", func(tx *database.Tx) ([]rowchange.Change, error) {
		_, ch, err := sourcecredibility.Upsert(tx, userID, sourcecredibility.UpsertInput{SourceID: src.ID, CredibilityGradeID: g.ID})
		return ch, err
	})
}

func (w *world) move(seed evidencegraphs.Seed, target []byte) (sourcemove.Result, writes.Result, error) {
	return writes.Run(w.C, writes.Op{Action: "move_to_source", UserID: userID}, func(tx *database.Tx) (sourcemove.Result, []rowchange.Change, error) {
		return sourcemove.Move(tx, userID, seed, target)
	})
}

func (w *world) sourceOf(table string, id []byte) []byte {
	w.T.Helper()
	var s []byte
	if err := dbtest.MustDB(w.T, w.C).QueryRow(`SELECT source_id FROM `+table+` WHERE id = ?`, id).Scan(&s); err != nil {
		w.T.Fatal(err)
	}
	return s
}

func (w *world) count(query string, args ...any) int {
	w.T.Helper()
	var n int
	if err := dbtest.MustDB(w.T, w.C).QueryRow(query, args...).Scan(&n); err != nil {
		w.T.Fatal(err)
	}
	return n
}

func (w *world) revisions() int { return w.count(`SELECT COUNT(*) FROM audit_transactions`) }

func (w *world) verify() {
	w.T.Helper()
	evidencelayertest.Must(w.T, w.C.Graph().Verify())
}

func refs(arts []artifacts.Artifact) []string {
	var out []string
	for _, a := range arts {
		out = append(out, a.Ref)
	}
	return out
}

func graphIDs(gs []evidencegraphs.Graph) [][]byte {
	var out [][]byte
	for _, g := range gs {
		out = append(out, g.ID)
	}
	return out
}

func sameIDs(a, b [][]byte) bool {
	x, y := slices.Clone(a), slices.Clone(b)
	slices.SortFunc(x, bytes.Compare)
	slices.SortFunc(y, bytes.Compare)
	return slices.EqualFunc(x, y, bytes.Equal)
}

func ids(gs ...evidencegraphs.Graph) [][]byte { return graphIDs(gs) }

func TestImpact(t *testing.T) {
	t.Run("one Artifact with its own graph", func(t *testing.T) { // AC-1.1, AC-1.7 not
		w := newWorld(t)
		a1, a2 := w.art(w.Source, "A1"), w.art(w.Source, "A2")
		g1, _ := w.graph(w.Source, "G1", a1), w.graph(w.Source, "G2", a2)
		w.people(g1, 3)

		rep, err := sourcemove.Impact(w.C, evidencegraphs.Seed{ArtifactID: a1.ID}, nil)
		if err != nil {
			t.Fatal(err)
		}
		if !bytes.Equal(rep.Bundle.SourceID, w.Source.ID) {
			t.Fatal("Source")
		}
		if got := refs(rep.Artifacts); len(got) != 1 || got[0] != a1.Ref {
			t.Fatalf("artifacts %v", got)
		}
		if len(rep.Graphs) != 1 || !bytes.Equal(rep.Graphs[0].ID, g1.ID) || len(rep.Progress) != 1 || rep.Progress[0].SubjectCount != 3 {
			t.Fatalf("graphs %+v progress %+v", rep.Graphs, rep.Progress)
		}
		if rep.LeavesSourceEmpty || rep.LeavesNoGraph || rep.SourceCredibilityKey != "" || rep.TargetCredibilityKey != "" || rep.CredibilityDiffers {
			t.Fatalf("report %+v", rep)
		}
	})

	t.Run("a shared graph widens the bundle", func(t *testing.T) { // AC-1.2
		w := newWorld(t)
		a1, a2, a3, a4 := w.art(w.Source, "A1"), w.art(w.Source, "A2"), w.art(w.Source, "A3"), w.art(w.Source, "A4")
		g1 := w.graph(w.Source, "G1", a1, a2)
		g2 := w.graph(w.Source, "G2", a2, a3)
		w.graph(w.Source, "G3", a4)
		for _, seed := range []evidencegraphs.Seed{{ArtifactID: a1.ID}, {GraphID: g2.ID}} {
			rep, err := sourcemove.Impact(w.C, seed, nil)
			if err != nil {
				t.Fatal(err)
			}
			got := refs(rep.Artifacts)
			want := []string{a1.Ref, a2.Ref, a3.Ref}
			slices.Sort(got)
			slices.Sort(want)
			if !slices.Equal(got, want) {
				t.Fatalf("artifacts %v want %v", got, want)
			}
			if len(rep.Graphs) != 2 || !sameIDs(graphIDs(rep.Graphs), ids(g1, g2)) || len(rep.Progress) != 2 {
				t.Fatalf("graphs %+v", rep.Graphs)
			}
			// ListBySource order: by ref, case-insensitive.
			if !slices.IsSortedFunc(rep.Artifacts, func(a, b artifacts.Artifact) int {
				return bytes.Compare([]byte(a.Ref), []byte(b.Ref))
			}) {
				t.Fatalf("artifacts not in ref order: %v", refs(rep.Artifacts))
			}
		}
	})

	t.Run("an Artifact in no graph", func(t *testing.T) { // AC-1.3
		w := newWorld(t)
		a5 := w.art(w.Source, "A5")
		rep, err := sourcemove.Impact(w.C, evidencegraphs.Seed{ArtifactID: a5.ID}, nil)
		if err != nil {
			t.Fatal(err)
		}
		if len(rep.Artifacts) != 1 || len(rep.Graphs) != 0 || len(rep.Progress) != 0 {
			t.Fatalf("report %+v", rep)
		}
	})

	t.Run("a graph with no Artifacts", func(t *testing.T) { // AC-1.4
		w := newWorld(t)
		def := w.Graph(w.Source)
		// A new Source's Default graph holds no Artifact until one is linked.
		if _, err := dbtest.MustDB(t, w.C).Exec(`DELETE FROM evidence_graph_artifacts WHERE graph_id = ?`, def); err != nil {
			t.Fatal(err)
		}
		subjectstest.On(t, w.C, userID, def, "person", "Ada")
		rep, err := sourcemove.Impact(w.C, evidencegraphs.Seed{GraphID: def}, nil)
		if err != nil {
			t.Fatal(err)
		}
		if len(rep.Artifacts) != 0 || len(rep.Graphs) != 1 || rep.Progress[0].SubjectCount != 1 {
			t.Fatalf("report %+v", rep)
		}
	})

	t.Run("credibility", func(t *testing.T) { // AC-1.5, AC-1.6
		w := newWorld(t)
		a1 := w.art(w.Source, "A1")
		w.graph(w.Source, "G1", a1)
		w.credibility(w.Source, "low_trust")
		rep, err := sourcemove.Impact(w.C, evidencegraphs.Seed{ArtifactID: a1.ID}, w.s2.ID)
		if err != nil {
			t.Fatal(err)
		}
		if rep.SourceCredibilityKey != "low_trust" || rep.TargetCredibilityKey != "" || !rep.CredibilityDiffers {
			t.Fatalf("report %+v", rep)
		}

		w = newWorld(t)
		a1 = w.art(w.Source, "A1")
		w.credibility(w.s2, "standard")
		rep, err = sourcemove.Impact(w.C, evidencegraphs.Seed{ArtifactID: a1.ID}, w.s2.ID)
		if err != nil {
			t.Fatal(err)
		}
		if rep.SourceCredibilityKey != "" || rep.TargetCredibilityKey != "standard" || rep.CredibilityDiffers {
			t.Fatalf("report %+v", rep)
		}
	})

	t.Run("leaves the Source empty and without a graph", func(t *testing.T) { // AC-1.7
		w := newWorld(t)
		rep, err := sourcemove.Impact(w.C, evidencegraphs.Seed{ArtifactID: w.Artifact.ID}, nil)
		if err != nil {
			t.Fatal(err)
		}
		if !rep.LeavesSourceEmpty || !rep.LeavesNoGraph {
			t.Fatalf("report %+v", rep)
		}
	})

	t.Run("refusals", func(t *testing.T) { // AC-1.8, AC-1.9
		w := newWorld(t)
		missing := make([]byte, 16)
		missing[0] = 9
		rows := []struct {
			name   string
			seed   evidencegraphs.Seed
			target []byte
			want   error
		}{
			{"no seed", evidencegraphs.Seed{}, nil, sourcemove.ErrInvalid},
			{"two seeds", evidencegraphs.Seed{ArtifactID: w.Artifact.ID, GraphID: w.Graph(w.Source)}, nil, sourcemove.ErrInvalid},
			{"same Source", evidencegraphs.Seed{ArtifactID: w.Artifact.ID}, w.Source.ID, sourcemove.ErrInvalid},
			{"short target", evidencegraphs.Seed{ArtifactID: w.Artifact.ID}, w.s2.ID[:3], sourcemove.ErrInvalid},
			{"missing Artifact", evidencegraphs.Seed{ArtifactID: missing}, nil, sourcemove.ErrNotFound},
			{"missing graph", evidencegraphs.Seed{GraphID: missing}, nil, sourcemove.ErrNotFound},
			{"missing target", evidencegraphs.Seed{ArtifactID: w.Artifact.ID}, missing, sources.ErrNotFound},
		}
		for _, tt := range rows {
			t.Run(tt.name, func(t *testing.T) {
				if _, err := sourcemove.Impact(w.C, tt.seed, tt.target); !errors.Is(err, tt.want) {
					t.Fatalf("got %v want %v", err, tt.want)
				}
			})
		}
	})
}

// citedBundle is S1's A1 in graph G1 with a Citation and an Observation on P1,
// a metadata value on A1 and on G1, and 3 Subjects in G1.
type citedBundle struct {
	a1       artifacts.Artifact
	g1       evidencegraphs.Graph
	subjects []subjects.Subject
	other    artifacts.Artifact // S1's A2 in its own graph
	otherG   evidencegraphs.Graph
}

func (w *world) cited() citedBundle {
	w.T.Helper()
	b := citedBundle{}
	b.a1 = w.art(w.Source, "A1")
	b.other = w.art(w.Source, "A2")
	b.g1 = w.graph(w.Source, "G1", b.a1)
	b.otherG = w.graph(w.Source, "G2", b.other)
	b.subjects = w.people(b.g1, 3)
	w.Cite(b.a1, b.subjects[0], observations.Input{PropertyID: w.Prop("name").ID, Name: namevaluetest.Western("Ada")})
	line, _, err := writes.Run(w.C, writes.Op{Action: "create_metadata_field", UserID: userID}, func(tx *database.Tx) (metadatafields.Field, []rowchange.Change, error) {
		return metadatafields.Create(tx, "Line", metadatafields.DataTypeText, "")
	})
	evidencelayertest.Must(w.T, err)
	w.Run("set_metadata", func(tx *database.Tx) ([]rowchange.Change, error) {
		_, ch, err := sourcemetadata.Set(tx, userID, sourcemetadata.Owner{Level: vocabkey.LevelArtifact, ID: b.a1.ID}, sourcemetadata.Input{FieldID: line.ID, ValueText: "film 7"})
		if err != nil {
			return nil, err
		}
		_, more, err := sourcemetadata.Set(tx, userID, sourcemetadata.Owner{Level: vocabkey.LevelGraph, ID: b.g1.ID}, sourcemetadata.Input{FieldID: line.ID, ValueText: "Ada Robins"})
		return append(ch, more...), err
	})
	return b
}

func (w *world) metadata(b citedBundle) []sourcemetadata.Row {
	w.T.Helper()
	tx, err := dbtest.MustDB(w.T, w.C).Begin()
	evidencelayertest.Must(w.T, err)
	defer tx.Rollback()
	rows, err := sourcemetadata.ListByOwnersTx(tx, []sourcemetadata.Owner{
		{Level: vocabkey.LevelArtifact, ID: b.a1.ID}, {Level: vocabkey.LevelGraph, ID: b.g1.ID},
	})
	evidencelayertest.Must(w.T, err)
	return rows
}

func TestMove(t *testing.T) {
	t.Run("a bundle keeps every id and attachment", func(t *testing.T) { // AC-2.1, AC-2.6
		w := newWorld(t)
		b := w.cited()
		beforeMeta := w.metadata(b)
		var citation, observation, link int
		citation = w.count(`SELECT COUNT(*) FROM citations WHERE artifact_id = ? AND graph_id = ?`, b.a1.ID, b.g1.ID)
		observation = w.count(`SELECT COUNT(*) FROM observations`)
		link = w.count(`SELECT COUNT(*) FROM evidence_graph_artifacts WHERE graph_id = ? AND artifact_id = ?`, b.g1.ID, b.a1.ID)
		if citation != 1 || link != 1 {
			t.Fatalf("setup: %d citations %d links", citation, link)
		}
		refBefore := w.count(`SELECT COUNT(*) FROM artifacts WHERE id = ? AND ref = ?`, b.a1.ID, b.a1.Ref)

		res, wrote, err := w.move(evidencegraphs.Seed{ArtifactID: b.a1.ID}, w.s2.ID)
		if err != nil {
			t.Fatal(err)
		}
		if refBefore != 1 || w.count(`SELECT COUNT(*) FROM artifacts WHERE id = ? AND ref = ?`, b.a1.ID, b.a1.Ref) != 1 {
			t.Fatal("Artifact ref changed")
		}
		for table, id := range map[string][]byte{"artifacts": b.a1.ID, "evidence_graphs": b.g1.ID} {
			if !bytes.Equal(w.sourceOf(table, id), w.s2.ID) {
				t.Fatalf("%s row not on the target", table)
			}
		}
		for _, s := range b.subjects {
			if !bytes.Equal(w.sourceOf("subjects", s.ID), w.s2.ID) {
				t.Fatal("Subject not on the target")
			}
		}
		if !bytes.Equal(w.sourceOf("artifacts", b.other.ID), w.Source.ID) || !bytes.Equal(w.sourceOf("evidence_graphs", b.otherG.ID), w.Source.ID) {
			t.Fatal("rows outside the bundle moved")
		}
		if w.count(`SELECT COUNT(*) FROM citations WHERE artifact_id = ? AND graph_id = ?`, b.a1.ID, b.g1.ID) != 1 ||
			w.count(`SELECT COUNT(*) FROM observations`) != observation ||
			w.count(`SELECT COUNT(*) FROM evidence_graph_artifacts WHERE graph_id = ? AND artifact_id = ?`, b.g1.ID, b.a1.ID) != 1 {
			t.Fatal("Citation, Observation or link changed")
		}
		afterMeta := w.metadata(b)
		if len(afterMeta) != 2 || len(beforeMeta) != 2 {
			t.Fatalf("metadata rows %d -> %d", len(beforeMeta), len(afterMeta))
		}
		for i := range afterMeta {
			if afterMeta[i].ValueText != beforeMeta[i].ValueText {
				t.Fatalf("metadata %q -> %q", beforeMeta[i].ValueText, afterMeta[i].ValueText)
			}
		}
		if len(res.Bundle.ArtifactIDs) != 1 || len(res.Bundle.GraphIDs) != 1 || res.DefaultGraphID != nil {
			t.Fatalf("result %+v", res)
		}

		// AC-2.6: one revision, both Sources scoped.
		if w.count(`SELECT COUNT(*) FROM audit_transactions WHERE action_type = 'move_to_source'`) != 1 {
			t.Fatal("not one audit revision")
		}
		for _, s := range []sources.Source{w.Source, w.s2} {
			if w.count(`SELECT COUNT(*) FROM audit_transaction_scopes sc JOIN audit_transactions t ON t.id = sc.audit_transaction_id
				WHERE t.action_type = 'move_to_source' AND sc.scope_type = 'source' AND sc.scope_id = ?`, s.ID) != 1 {
				t.Fatalf("Source %s has no scope row", s.Ref)
			}
		}
		if !sameIDs(wrote.Effects.SourceScopes, [][]byte{w.Source.ID, w.s2.ID}) {
			t.Fatalf("source scopes %x", wrote.Effects.SourceScopes)
		}
		if !sameIDs(wrote.Effects.IDsOf(effects.ReadEvidenceGraphs), [][]byte{w.Source.ID, w.s2.ID}) ||
			!sameIDs(wrote.Effects.IDsOf(effects.ReadSourceRecords), [][]byte{w.Source.ID, w.s2.ID}) {
			t.Fatalf("reads %+v", wrote.Effects.Reads)
		}
		w.verify()
	})

	t.Run("a graph seed carries its shared Artifacts", func(t *testing.T) { // AC-2.2
		w := newWorld(t)
		a1, a2, a3, a4 := w.art(w.Source, "A1"), w.art(w.Source, "A2"), w.art(w.Source, "A3"), w.art(w.Source, "A4")
		g1 := w.graph(w.Source, "G1", a1, a2)
		g2 := w.graph(w.Source, "G2", a2, a3)
		g3 := w.graph(w.Source, "G3", a4)
		if _, _, err := w.move(evidencegraphs.Seed{GraphID: g2.ID}, w.s2.ID); err != nil {
			t.Fatal(err)
		}
		for table, id := range map[string][]byte{"artifacts": a1.ID, "evidence_graphs": g1.ID} {
			if !bytes.Equal(w.sourceOf(table, id), w.s2.ID) {
				t.Fatalf("%s row stayed", table)
			}
		}
		for _, a := range []artifacts.Artifact{a2, a3} {
			if !bytes.Equal(w.sourceOf("artifacts", a.ID), w.s2.ID) {
				t.Fatal("Artifact stayed")
			}
		}
		if !bytes.Equal(w.sourceOf("evidence_graphs", g2.ID), w.s2.ID) {
			t.Fatal("graph stayed")
		}
		if !bytes.Equal(w.sourceOf("artifacts", a4.ID), w.Source.ID) || !bytes.Equal(w.sourceOf("evidence_graphs", g3.ID), w.Source.ID) {
			t.Fatal("rows outside the bundle moved")
		}
		w.verify()
	})

	t.Run("scale", func(t *testing.T) { // AC-2.3
		w := newWorld(t)
		var arts []artifacts.Artifact
		for i := range 5 {
			arts = append(arts, w.art(w.Source, string(rune('A'+i))))
		}
		g1 := w.graph(w.Source, "G1", arts...)
		gs := []evidencegraphs.Graph{g1}
		for i := 1; i < 5; i++ {
			gs = append(gs, w.graph(w.Source, "G", arts[i]))
		}
		var all []subjects.Subject
		for _, g := range gs {
			all = append(all, w.people(g, 20)...)
		}
		revisions := w.revisions()
		res, _, err := w.move(evidencegraphs.Seed{ArtifactID: arts[0].ID}, w.s2.ID)
		if err != nil {
			t.Fatal(err)
		}
		if w.revisions() != revisions+1 {
			t.Fatalf("revisions %d -> %d", revisions, w.revisions())
		}
		if len(res.Bundle.ArtifactIDs) != 5 || len(res.Bundle.GraphIDs) != 5 {
			t.Fatalf("bundle %+v", res.Bundle)
		}
		for _, s := range all {
			if !bytes.Equal(w.sourceOf("subjects", s.ID), w.s2.ID) {
				t.Fatal("a Subject stayed")
			}
		}
		for _, a := range arts {
			if !bytes.Equal(w.sourceOf("artifacts", a.ID), w.s2.ID) {
				t.Fatal("an Artifact stayed")
			}
		}
		w.verify()
	})

	t.Run("the last graph leaves a new Default graph", func(t *testing.T) { // AC-2.4
		w := newWorld(t)
		res, _, err := w.move(evidencegraphs.Seed{ArtifactID: w.Artifact.ID}, w.s2.ID)
		if err != nil {
			t.Fatal(err)
		}
		if len(res.DefaultGraphID) != 16 {
			t.Fatal("no default graph id")
		}
		gs, err := evidencegraphs.List(w.C, w.Source.ID)
		if err != nil || len(gs) != 1 || !bytes.Equal(gs[0].ID, res.DefaultGraphID) || gs[0].Name != "Default" || len(gs[0].ArtifactIDs) != 0 || gs[0].Ref == "" {
			t.Fatalf("graphs %+v (%v)", gs, err)
		}
		if _, err := sources.Get(w.C, w.Source.ID); err != nil {
			t.Fatalf("the emptied Source is gone: %v", err)
		}
		if n := w.count(`SELECT COUNT(*) FROM artifacts WHERE source_id = ?`, w.Source.ID); n != 0 {
			t.Fatalf("%d Artifacts left", n)
		}
		w.verify()
	})

	t.Run("the cover leaves with its Artifact", func(t *testing.T) { // AC-2.5
		for _, moves := range []bool{true, false} {
			w := newWorld(t)
			stay := w.art(w.Source, "Stay")
			w.graph(w.Source, "G", stay)
			cover := w.Artifact
			if !moves {
				cover = stay
			}
			w.Run("set_cover", func(tx *database.Tx) ([]rowchange.Change, error) {
				_, ch, err := sources.SetCover(tx, userID, w.Source.ID, sources.CoverModeArtifact, cover.ID)
				return ch, err
			})
			s2Before, _ := sources.Get(w.C, w.s2.ID)
			if _, _, err := w.move(evidencegraphs.Seed{ArtifactID: w.Artifact.ID}, w.s2.ID); err != nil {
				t.Fatal(err)
			}
			s1, _ := sources.Get(w.C, w.Source.ID)
			s2, _ := sources.Get(w.C, w.s2.ID)
			if moves && (s1.CoverMode != sources.CoverModeTypeIcon || len(s1.PrimaryArtifactID) != 0) {
				t.Fatalf("cover stayed: %+v", s1)
			}
			if !moves && (s1.CoverMode != sources.CoverModeArtifact || !bytes.Equal(s1.PrimaryArtifactID, stay.ID)) {
				t.Fatalf("cover left: %+v", s1)
			}
			if s2.CoverMode != s2Before.CoverMode || !bytes.Equal(s2.PrimaryArtifactID, s2Before.PrimaryArtifactID) {
				t.Fatal("the target's cover changed")
			}
			w.verify()
		}
	})

	t.Run("a reification Subject moves with its graph", func(t *testing.T) { // AC-2.9
		w := newWorld(t)
		b := w.cited()
		r := subjectstest.On(t, w.C, userID, b.g1.ID, "source", "Register")
		if _, _, err := w.move(evidencegraphs.Seed{ArtifactID: b.a1.ID}, w.s2.ID); err != nil {
			t.Fatal(err)
		}
		if !bytes.Equal(w.sourceOf("subjects", r.ID), w.s2.ID) {
			t.Fatal("reification stayed")
		}
		w.verify()
	})

	t.Run("a promoted Subject reloads its handle", func(t *testing.T) { // AC-2.12
		w := newWorld(t)
		b := w.cited()
		q := subjectstest.On(t, w.C, userID, b.g1.ID, "person", "Q")
		h := promotetest.Save(t, w.C, userID, promote.Input{SubjectID: q.ID}).Entity.ID
		if _, err := w.C.Graph().Node(h); err != nil {
			t.Fatal(err)
		}
		_, wrote, err := w.move(evidencegraphs.Seed{ArtifactID: b.a1.ID}, w.s2.ID)
		if err != nil {
			t.Fatal(err)
		}
		if !slices.ContainsFunc(wrote.Effects.Handles, func(id []byte) bool { return bytes.Equal(id, h) }) {
			t.Fatalf("handles %x", wrote.Effects.Handles)
		}
		n, err := w.C.Graph().Node(h)
		if err != nil {
			t.Fatal(err)
		}
		if len(n.Members) != 1 || !bytes.Equal(n.Members[0].SourceID, w.s2.ID) {
			t.Fatalf("members %+v", n.Members)
		}
		w.verify()
	})

	t.Run("refusals write nothing", func(t *testing.T) { // AC-2.11
		w := newWorld(t)
		missing := make([]byte, 16)
		missing[0] = 9
		rows := []struct {
			name   string
			user   []byte
			seed   evidencegraphs.Seed
			target []byte
			want   error
		}{
			{"no seed", userID, evidencegraphs.Seed{}, w.s2.ID, sourcemove.ErrInvalid},
			{"two seeds", userID, evidencegraphs.Seed{ArtifactID: w.Artifact.ID, GraphID: w.Graph(w.Source)}, w.s2.ID, sourcemove.ErrInvalid},
			{"no target", userID, evidencegraphs.Seed{ArtifactID: w.Artifact.ID}, nil, sourcemove.ErrInvalid},
			{"same Source", userID, evidencegraphs.Seed{ArtifactID: w.Artifact.ID}, w.Source.ID, sourcemove.ErrInvalid},
			{"missing seed", userID, evidencegraphs.Seed{ArtifactID: missing}, w.s2.ID, sourcemove.ErrNotFound},
			{"missing target", userID, evidencegraphs.Seed{ArtifactID: w.Artifact.ID}, missing, sources.ErrNotFound},
			{"nil user", nil, evidencegraphs.Seed{ArtifactID: w.Artifact.ID}, w.s2.ID, sourcemove.ErrInvalid},
		}
		for _, tt := range rows {
			t.Run(tt.name, func(t *testing.T) {
				before := w.revisions()
				_, _, err := writes.Run(w.C, writes.Op{Action: "move_to_source", UserID: userID}, func(tx *database.Tx) (sourcemove.Result, []rowchange.Change, error) {
					return sourcemove.Move(tx, tt.user, tt.seed, tt.target)
				})
				if !errors.Is(err, tt.want) {
					t.Fatalf("got %v want %v", err, tt.want)
				}
				if w.revisions() != before || !bytes.Equal(w.sourceOf("artifacts", w.Artifact.ID), w.Source.ID) {
					t.Fatal("a refused move wrote")
				}
			})
		}
	})
}

func TestMoveCachesAndSearch(t *testing.T) { // AC-2.7
	w := newWorld(t)
	b := w.cited()
	g := w.C.Graph()
	idx, err := evidencegraphs.IndexOf(g)
	if err != nil || len(idx.OfSource(w.Source.ID)) == 0 {
		t.Fatalf("index %v", err)
	}
	recs, err := sources.RecordsOf(g)
	if err != nil {
		t.Fatal(err)
	}
	if r, _, _ := recs.Artifact(b.a1.ID); !bytes.Equal(r.ID, w.Source.ID) {
		t.Fatal("record before the move")
	}
	if _, _, err := w.move(evidencegraphs.Seed{ArtifactID: b.a1.ID}, w.s2.ID); err != nil {
		t.Fatal(err)
	}
	idx, err = evidencegraphs.IndexOf(w.C.Graph())
	if err != nil {
		t.Fatal(err)
	}
	if got, ok := idx.Graph(b.g1.ID); !ok || !bytes.Equal(got.SourceID, w.s2.ID) {
		t.Fatalf("index graph %+v", got)
	}
	for _, og := range idx.OfSource(w.Source.ID) {
		if bytes.Equal(og.ID, b.g1.ID) {
			t.Fatal("old Source still lists the graph")
		}
	}
	recs, err = sources.RecordsOf(w.C.Graph())
	if err != nil {
		t.Fatal(err)
	}
	if r, _, ok := recs.Artifact(b.a1.ID); !ok || !bytes.Equal(r.ID, w.s2.ID) {
		t.Fatalf("record after the move: %+v", r)
	}
	var subtitle string
	var parent string
	if err := dbtest.MustDB(t, w.C).QueryRow(`SELECT display_subtitle, display_parent_id FROM catalog_search_docs WHERE kind = 'evidence_graph' AND entity_id = ?`, uuid.UUID(b.g1.ID).String()).Scan(&subtitle, &parent); err != nil {
		t.Fatal(err)
	}
	if subtitle != w.s2.Title || parent != uuid.UUID(w.s2.ID).String() {
		t.Fatalf("search document %q %q", subtitle, parent)
	}
	w.verify()
}

// A move names a handle through its Subjects' own changes (membersOf): the
// Artifact's change names none, because observations.requireSameGraph keeps
// every Subject citing a bundled Artifact in the bundle too.
func TestMoveRecomputesHandles(t *testing.T) { // AC-2.8
	w := newWorld(t)
	s3, scan3 := w.NewSource("Third")
	w.credibility(w.Source, "low_trust")
	e1 := w.DatedBirth(w.Source, w.Artifact, 1840)
	h := promotetest.Save(t, w.C, userID, promote.Input{SubjectID: e1.ID}).Entity.ID
	e2 := w.DatedBirth(s3, scan3, 1841)
	promotetest.Save(t, w.C, userID, promote.Input{SubjectID: e2.ID, EntityID: h})
	if _, err := w.C.Graph().Node(h); err != nil {
		t.Fatal(err)
	}
	reasons := func() []string {
		t.Helper()
		rows, err := dbtest.MustDB(t, w.C).Query(`SELECT reason FROM auto_reconciler_values WHERE entity_id = ? AND value_date IS NOT NULL ORDER BY date_lo`, h)
		if err != nil {
			t.Fatal(err)
		}
		defer rows.Close()
		var out []string
		for rows.Next() {
			var r string
			if err := rows.Scan(&r); err != nil {
				t.Fatal(err)
			}
			out = append(out, r)
		}
		return out
	}
	if got := reasons(); !slices.Equal(got, []string{"weak", "kept"}) {
		t.Fatalf("before: %v", got)
	}
	_, wrote, err := w.move(evidencegraphs.Seed{ArtifactID: w.Artifact.ID}, w.s2.ID)
	if err != nil {
		t.Fatal(err)
	}
	if !slices.ContainsFunc(wrote.Effects.Handles, func(id []byte) bool { return bytes.Equal(id, h) }) {
		t.Fatalf("handles %x", wrote.Effects.Handles)
	}
	if got := reasons(); !slices.Equal(got, []string{"kept", "kept"}) {
		t.Fatalf("after: %v", got)
	}
	w.verify()
}

func TestMergeByMoving(t *testing.T) { // AC-2.10
	w := newWorld(t)
	a2 := w.art(w.Source, "A2")
	w.graph(w.Source, "G2", a2)
	for _, a := range []artifacts.Artifact{w.Artifact, a2} {
		if _, _, err := w.move(evidencegraphs.Seed{ArtifactID: a.ID}, w.s2.ID); err != nil {
			t.Fatal(err)
		}
	}
	gs, err := evidencegraphs.List(w.C, w.Source.ID)
	if err != nil || len(gs) != 1 || gs[0].Name != "Default" {
		t.Fatalf("graphs %+v (%v)", gs, err)
	}
	if _, err := writes.RunChanges(w.C, writes.Op{Action: "delete_source", UserID: userID}, func(tx *database.Tx) ([]rowchange.Change, error) {
		return sources.Delete(tx, userID, w.Source.ID)
	}); err != nil {
		t.Fatal(err)
	}
	if _, err := sources.Get(w.C, w.Source.ID); !errors.Is(err, sources.ErrNotFound) {
		t.Fatalf("Source still there: %v", err)
	}
	w.verify()
}

// Every table with a foreign key to sources decides whether its rows move with
// a bundle or stay with the Source. A table added later must be listed.
func TestSourceKeysAreClassified(t *testing.T) { // D-18
	moves := map[string]bool{"artifacts.source_id": true, "evidence_graphs.source_id": true, "subjects.source_id": true}
	stays := map[string]bool{
		"source_notes.source_id": true, "source_metadata.source_id": true,
		"source_credibility_assessments.source_id": true, "source_metadata_layout.source_id": true,
	}
	n := 0
	for _, fk := range catalogmodel.FKs {
		if fk.To != "sources" {
			continue
		}
		n++
		key := fk.From + "." + fk.Column
		if !moves[key] && !stays[key] {
			t.Errorf("%s references sources and is in neither the moves nor the stays list of sourcemove", key)
		}
	}
	if n != len(moves)+len(stays) {
		t.Errorf("%d foreign keys to sources, %d classified", n, len(moves)+len(stays))
	}
}
