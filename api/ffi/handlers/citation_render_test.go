package handlers

import (
	"slices"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/api/proto/engine"
	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/citationrender"
	"github.com/Jake-Robins-Studios/provenencia/core/database/citations"
	"github.com/Jake-Robins-Studios/provenencia/core/depictionvalue/depictionvaluetest"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/google/uuid"
)

// The render tests use a researcher's own type, fields and formats, so they
// test the engine and not the product seed: a seed edit changes no test here.
const (
	renderFormatFull  = `{meta.ledger}[, {meta.entrant}][, leaf {meta.leaf}]; *{meta.keeper}*, {source.date:year}.`
	renderFormatShort = `{meta.ledger}[, leaf {meta.leaf}].`
	renderFormatList  = `{meta.ledger}, {source.date:year}.`

	renderFull  = "Calder ledger, Ada Robins, leaf 14; Westmark Archive, 1880."
	renderShort = "Calder ledger, leaf 14."
	renderList  = "Calder ledger, 1880."
)

// renderWorld is a project with one researcher type ("Register") and a Source
// of it: the ledger and keeper on the Source, the entrant on the graph, the
// leaf on the Citation.
type renderWorld struct {
	dir, userID string
	typeID      string
	fields      map[string]string // every field's id by key
	source      string
	artifact    string
	graph       string
	citation    string
}

func setValues(t *testing.T, dir, userID string, ids map[string]string, level, id string, values map[string]string) {
	t.Helper()
	for key, text := range values {
		mustRPC(t, SetMetadata, &engine.SetMetadataRequest{
			ProjectDir: dir, UserId: userID, Owner: &engine.MetadataOwner{Level: level, Id: id},
			FieldId: ids[key], ValueText: text,
		}, &engine.SetMetadataResponse{})
	}
}

func setMark(t *testing.T, dir, userID, fieldID, level, id, text string, mark *engine.ValueMark) {
	t.Helper()
	mustRPC(t, SetMetadata, &engine.SetMetadataRequest{
		ProjectDir: dir, UserId: userID, Owner: &engine.MetadataOwner{Level: level, Id: id},
		FieldId: fieldID, ValueText: text, Mark: mark,
	}, &engine.SetMetadataResponse{})
}

// setUnknownText sets what a value of a researcher text field prints when
// it is marked unknown.
func setUnknownText(t *testing.T, dir, userID, fieldID, label, unknown string) {
	t.Helper()
	mustRPC(t, UpdateMetadataField, &engine.UpdateMetadataFieldRequest{
		ProjectDir: dir, UserId: userID, FieldId: fieldID, Label: label, DataType: "text", UnknownText: &unknown,
	}, &engine.UpdateMetadataFieldResponse{})
}

func newArtifact(t *testing.T, dir, userID, sourceID, label string) (artifactID, graphID string) {
	t.Helper()
	var art engine.CreateArtifactResponse
	mustRPC(t, CreateArtifact, &engine.CreateArtifactRequest{ProjectDir: dir, UserId: userID, SourceId: sourceID, Label: label}, &art)
	artifactID = art.GetArtifact().GetId()
	return artifactID, graphLinking(t, dir, artifactID)
}

func newCitation(t *testing.T, dir, userID, artifactID, graphID, locatorJSON string) string {
	t.Helper()
	var cit engine.CreateCitationWithObservationsResponse
	mustRPC(t, CreateCitationWithObservations, &engine.CreateCitationWithObservationsRequest{
		ProjectDir: dir, UserId: userID, ArtifactId: artifactID, GraphId: graphID, LocatorJson: locatorJSON,
	}, &cit)
	return cit.GetCitation().GetId()
}

// newSource creates a Source of the world's type, dated 1880 unless date is nil.
func (w renderWorld) newSource(t *testing.T, title string, date *engine.DateValueInput) string {
	t.Helper()
	var src engine.CreateSourceResponse
	mustRPC(t, CreateSource, &engine.CreateSourceRequest{
		ProjectDir: w.dir, UserId: w.userID, SourceTypeId: w.typeID, Title: title,
	}, &src)
	id := src.GetSource().GetId()
	if date != nil {
		mustRPC(t, SetSourceDate, &engine.SetSourceDateRequest{
			ProjectDir: w.dir, UserId: w.userID, SourceId: id, Date: date,
		}, &engine.SetSourceDateResponse{})
	}
	return id
}

func newRenderWorld(t *testing.T) renderWorld {
	t.Helper()
	dir, userID, _ := sourceFixture(t)
	w := renderWorld{dir: dir, userID: userID}
	for _, f := range []struct{ label, unknown string }{
		{"Ledger", ""}, {"Keeper", ""}, {"Entrant", ""}, {"Leaf", "unfoliated"}, {"Press", "n.p."},
	} {
		id := newUserField(t, dir, userID, f.label)
		if f.unknown != "" {
			setUnknownText(t, dir, userID, id, f.label, f.unknown)
		}
	}
	w.fields = fieldIDsByKey(t, dir)
	var ty engine.CreateSourceTypeResponse
	mustRPC(t, CreateSourceType, &engine.CreateSourceTypeRequest{ProjectDir: dir, UserId: userID, Label: "Register"}, &ty)
	w.typeID = ty.GetType().GetId()
	formats := setFormats(t, dir, userID, w.typeID, &engine.CitationFormats{
		Full: renderFormatFull, Short: renderFormatShort, List: renderFormatList,
	})
	if len(formats.GetDiagnostics()) != 0 {
		t.Fatalf("diagnostics %v", formats.GetDiagnostics())
	}
	w.source = w.newSource(t, "Calder register", pointDate(1880, 0, 0))
	setValues(t, dir, userID, w.fields, "source", w.source, map[string]string{"ledger": "Calder ledger", "keeper": "Westmark Archive"})
	w.artifact, w.graph = newArtifact(t, dir, userID, w.source, "Ledger scan")
	setValues(t, dir, userID, w.fields, "graph", w.graph, map[string]string{"entrant": "Ada Robins"})
	w.citation = newCitation(t, dir, userID, w.artifact, w.graph, depictionvaluetest.Locator)
	setValues(t, dir, userID, w.fields, "citation", w.citation, map[string]string{"leaf": "14"})
	return w
}

// resolvedValues answers each target with the text it was given.
type resolvedValues map[citationformat.Target]citationformat.Value

func (v resolvedValues) Resolve(t citationformat.Target) citationformat.Value { return v[t] }

// TestRenderedCitationsProto: a rendered Citation's wire form carries its id, the runs of its full and
// short forms with the italic run marked, and the plain text of both. Rendering itself is core's test.
func TestRenderedCitationsProto(t *testing.T) {
	title := citationformat.Target{Level: vocabkey.LevelSource, Builtin: "title"}
	resolver := resolvedValues{title: {Text: "Calder register"}}
	parse := func(text string, form citationformat.Form) *citationformat.Template {
		t.Helper()
		tpl, diags := citationformat.Parse(text, form)
		if len(diags) > 0 {
			t.Fatalf("Parse(%q) = %v", text, diags)
		}
		return tpl
	}
	id := []byte{0: 7, 15: 9}
	got := renderedCitationsProto([]citationrender.RenderedCitation{{
		CitationID: id,
		Full:       citationformat.Render(parse("*Ancestry*, {source.title}", citationformat.FormFull), resolver),
		Short:      citationformat.Render(parse("{source.title}", citationformat.FormShort), resolver),
	}})
	if len(got) != 1 || got[0].GetCitationId() != database.UUIDString(id) {
		t.Fatalf("got %v", got)
	}
	full, short := got[0].GetFull(), got[0].GetShort()
	if full.GetPlain() != "Ancestry, Calder register" || len(full.GetRuns()) != 2 ||
		full.GetRuns()[0].GetText() != "Ancestry" || !full.GetRuns()[0].GetItalic() ||
		full.GetRuns()[1].GetText() != ", Calder register" || full.GetRuns()[1].GetItalic() {
		t.Errorf("full = %v", full)
	}
	if short.GetPlain() != "Calder register" || len(short.GetRuns()) != 1 || short.GetRuns()[0].GetItalic() {
		t.Errorf("short = %v", short)
	}
}

func TestRenderCitationPreview(t *testing.T) {
	w := newRenderWorld(t)
	preview := func(req *engine.RenderCitationPreviewRequest) (*engine.RenderCitationPreviewResponse, error) {
		t.Helper()
		req.ProjectDir = w.dir
		var out engine.RenderCitationPreviewResponse
		err := rpc(t, RenderCitationPreview, req, &out)
		return &out, err
	}
	strp := func(s string) *string { return &s }
	source := func(id string) *engine.RenderCitationPreviewRequest_SourceId {
		return &engine.RenderCitationPreviewRequest_SourceId{SourceId: id}
	}

	t.Run("AC-2.1 the list form of a Source", func(t *testing.T) {
		out, err := preview(&engine.RenderCitationPreviewRequest{Form: "list", Target: source(w.source)})
		if err != nil {
			t.Fatal(err)
		}
		if out.GetRender().GetPlain() != renderList || len(out.GetMissing()) != 0 || len(out.GetDiagnostics()) != 0 {
			t.Errorf("got %v", out)
		}
	})
	t.Run("a stored full form of a Citation", func(t *testing.T) {
		out, err := preview(&engine.RenderCitationPreviewRequest{Form: "full", Target: &engine.RenderCitationPreviewRequest_CitationId{CitationId: w.citation}})
		if err != nil || out.GetRender().GetPlain() != renderFull {
			t.Fatalf("got %v, %v", out, err)
		}
	})
	t.Run("AC-2.3 an unknown field", func(t *testing.T) {
		out, err := preview(&engine.RenderCitationPreviewRequest{
			Form: "full", Format: strp(`{meta.nope}.`),
			Target: &engine.RenderCitationPreviewRequest_CitationId{CitationId: w.citation},
		})
		if err != nil {
			t.Fatal(err)
		}
		want := &engine.CitationFormatDiagnostic{Form: "full", Code: string(citationformat.CodeUnknownField), Start: 6, End: 10}
		if len(out.GetDiagnostics()) != 1 || out.GetDiagnostics()[0].String() != want.String() || out.GetRender().GetPlain() != "" || len(out.GetMissing()) != 0 {
			t.Errorf("got %v", out)
		}
	})
	t.Run("a needed field read nearest-first has no level in a missing option", func(t *testing.T) {
		bare := w.newSource(t, "Bare", nil)
		out, err := preview(&engine.RenderCitationPreviewRequest{Form: "full", Format: strp(`{meta.ledger}.`), Target: source(bare)})
		if err != nil {
			t.Fatal(err)
		}
		if len(out.GetMissing()) != 1 || len(out.GetMissing()[0].GetOptions()) != 1 {
			t.Fatalf("missing = %v", out.GetMissing())
		}
		if o := out.GetMissing()[0].GetOptions()[0]; o.GetLevel() != "" || o.GetField().GetKey() != "ledger" {
			t.Errorf("option = %v, want ledger with no level", o)
		}
	})
	t.Run("AC-2.4 a needed field with no value", func(t *testing.T) {
		bare := w.newSource(t, "Bare", pointDate(1880, 0, 0))
		out, err := preview(&engine.RenderCitationPreviewRequest{Form: "list", Target: source(bare)})
		if err != nil {
			t.Fatal(err)
		}
		if len(out.GetMissing()) != 1 || len(out.GetMissing()[0].GetOptions()) != 1 {
			t.Fatalf("missing = %v", out.GetMissing())
		}
		o := out.GetMissing()[0].GetOptions()[0]
		if o.GetLevel() != "source" || o.GetField().GetKey() != "ledger" || o.GetField().GetLabel() != "Ledger" || o.GetBuiltin() != "" {
			t.Errorf("option = %v", o)
		}
	})
	t.Run("AC-2.7 a blank format renders nothing, an absent one the stored form", func(t *testing.T) {
		blank, err := preview(&engine.RenderCitationPreviewRequest{Form: "list", Format: strp("   "), Target: source(w.source)})
		if err != nil || blank.GetRender().GetPlain() != "" || len(blank.GetMissing()) != 0 || len(blank.GetDiagnostics()) != 0 {
			t.Fatalf("blank = %v, %v", blank, err)
		}
		stored, err := preview(&engine.RenderCitationPreviewRequest{Form: "list", Target: source(w.source)})
		if err != nil || stored.GetRender().GetPlain() != renderList {
			t.Fatalf("stored = %v, %v", stored, err)
		}
	})
	t.Run("AC-7.1 a Source target with the full form reads its Citation", func(t *testing.T) {
		out, err := preview(&engine.RenderCitationPreviewRequest{Form: "full", Target: source(w.source)})
		if err != nil || out.GetRender().GetPlain() != renderFull {
			t.Fatalf("got %v, %v", out, err)
		}
	})
	t.Run("AC-7.3 no target and a format that does not parse", func(t *testing.T) {
		out, err := preview(&engine.RenderCitationPreviewRequest{Form: "full", Format: strp(`[`)})
		if err != nil {
			t.Fatal(err)
		}
		want := &engine.CitationFormatDiagnostic{Form: "full", Code: string(citationformat.CodeUnclosedGroup), Start: 0, End: 1}
		if len(out.GetDiagnostics()) != 1 || out.GetDiagnostics()[0].String() != want.String() || out.GetRender().GetPlain() != "" {
			t.Errorf("got %v", out)
		}
	})
	runRPC(t, RenderCitationPreview, []rpcTest{
		{
			name: "AC-2.5 no target and no format",
			req:  &engine.RenderCitationPreviewRequest{ProjectDir: w.dir, Form: "list"}, wantErr: true, wantErrIs: citations.ErrInvalid,
		},
		{
			name: "AC-2.6 a Citation that is not there",
			req: &engine.RenderCitationPreviewRequest{
				ProjectDir: w.dir, Form: "full",
				Target: &engine.RenderCitationPreviewRequest_CitationId{CitationId: uuid.Must(uuid.NewV7()).String()},
			}, wantErr: true, wantErrIs: citations.ErrNotFound,
		},
		{
			name: "a target id that is not a UUID",
			req:  &engine.RenderCitationPreviewRequest{ProjectDir: w.dir, Form: "list", Target: source("nope")}, wantErr: true, wantErrIs: errInvalidID,
		},
	})
}

func TestListCitationPlaceholders(t *testing.T) {
	dir, userID, _ := sourceFixture(t)
	newUserField(t, dir, userID, "Leaf")
	const leafKey = "leaf"
	list := func(form string) *engine.ListCitationPlaceholdersResponse {
		t.Helper()
		var out engine.ListCitationPlaceholdersResponse
		mustRPC(t, ListCitationPlaceholders, &engine.ListCitationPlaceholdersRequest{ProjectDir: dir, Form: form}, &out)
		return &out
	}

	t.Run("the list form reads the Source only", func(t *testing.T) {
		out := list("list")
		if len(out.GetPlaceholders()) < 4 {
			t.Fatalf("got %d rows", len(out.GetPlaceholders()))
		}
		var texts []string
		for _, p := range out.GetPlaceholders()[:4] {
			texts = append(texts, p.GetText())
		}
		if want := []string{"{source.title}", "{source.type}", "{source.date}", "{source.date:year}"}; !slices.Equal(texts, want) {
			t.Errorf("built-ins = %v, want %v", texts, want)
		}
		for i, p := range out.GetPlaceholders() {
			// A built-in has its level; a field row has none.
			if want := map[bool]string{true: "source", false: ""}[i < 4]; p.GetLevel() != want {
				t.Errorf("%s at level %q, want %q", p.GetText(), p.GetLevel(), want)
			}
		}
	})

	t.Run("the full form lists the four levels, then each field once", func(t *testing.T) {
		var leaf *engine.CitationPlaceholder
		var levels []string
		for _, p := range list("full").GetPlaceholders() {
			if len(levels) == 0 || levels[len(levels)-1] != p.GetLevel() {
				levels = append(levels, p.GetLevel())
			}
			if p.GetText() == "{meta."+leafKey+"}" {
				leaf = p
			}
		}
		if !slices.Equal(levels, []string{"source", "artifact", "graph", "citation", ""}) {
			t.Errorf("levels = %v", levels)
		}
		if leaf == nil || leaf.GetRef() != "meta."+leafKey || leaf.GetLevel() != "" || leaf.GetField().GetKey() != leafKey || leaf.GetBuiltin() != "" {
			t.Errorf("leaf = %v", leaf)
		}
	})

	runRPC(t, ListCitationPlaceholders, []rpcTest{{
		name: "an unknown form",
		req:  &engine.ListCitationPlaceholdersRequest{ProjectDir: dir, Form: "fourth"}, wantErr: true, wantErrIs: citations.ErrInvalid,
	}})
}
