package handlers

import (
	"slices"
	"strings"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/api/proto/engine"
	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database/citations"
	"github.com/Jake-Robins-Studios/provenencia/core/depictionvalue/depictionvaluetest"
	"github.com/google/uuid"
)

const (
	renderCensusFull  = "1880 Westmark census, Calder County, Westmark, population schedule, ED 236, piece 1047, fol. 22, p. 14, schedule 9, dwelling 112, family 118, line 14, Ada Robins; digital image, Westmark Heritage (https://example.org/calder/1880 : accessed 12 March 2025); citing county film 7, item 3."
	renderCensusShort = "1880 Westmark census, Calder County, Westmark, ED 236, fol. 22, p. 14, dwell. 112, fam. 118, Ada Robins."
	renderCensusList  = "Calder County, Westmark. 1880 Westmark census, population schedule."
)

// renderWorld is AC-1.1's catalog built by RPC.
type renderWorld struct {
	dir, userID string
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

func newRenderWorld(t *testing.T) renderWorld {
	t.Helper()
	dir, userID, _ := sourceFixture(t)
	ids := fieldIDsByKey(t, dir)
	w := renderWorld{dir: dir, userID: userID, source: seededSourceOfType(t, dir, userID, "census")}
	mustRPC(t, SetSourceDate, &engine.SetSourceDateRequest{
		ProjectDir: dir, UserId: userID, SourceId: w.source, Date: pointDate(1880, 0, 0),
	}, &engine.SetSourceDateResponse{})
	setValues(t, dir, userID, ids, "source", w.source, map[string]string{
		"creator": "Westmark", "jurisdiction": "Calder County, Westmark", "schedule": "population schedule",
		"enumeration_district": "236", "piece": "1047", "folio": "22",
	})
	w.artifact, w.graph = newArtifact(t, dir, userID, w.source, "County film")
	setValues(t, dir, userID, ids, "graph", w.graph, map[string]string{
		"schedule_number": "9", "dwelling_number": "112", "family_number": "118", "line_number": "14", "item": "Ada Robins",
	})
	setValues(t, dir, userID, ids, "artifact", w.artifact, map[string]string{
		"format": "digital image", "provider": "Westmark Heritage", "url": "https://example.org/calder/1880",
		"accessed_date": "12 March 2025", "citing": "county film 7, item 3",
	})
	w.citation = newCitation(t, dir, userID, w.artifact, w.graph, depictionvaluetest.Locator)
	setValues(t, dir, userID, ids, "citation", w.citation, map[string]string{"page": "14"})
	return w
}

func renderCitations(t *testing.T, dir string, ids ...string) (*engine.RenderCitationsResponse, error) {
	t.Helper()
	var out engine.RenderCitationsResponse
	err := rpc(t, RenderCitations, &engine.RenderCitationsRequest{ProjectDir: dir, CitationIds: ids}, &out)
	return &out, err
}

func TestRenderCitations(t *testing.T) {
	w := newRenderWorld(t)

	t.Run("AC-1.1 the census citation", func(t *testing.T) {
		out, err := renderCitations(t, w.dir, w.citation)
		if err != nil {
			t.Fatal(err)
		}
		if len(out.GetCitations()) != 1 {
			t.Fatalf("got %d citations", len(out.GetCitations()))
		}
		got := out.GetCitations()[0]
		t.Logf("full: %s", got.GetFull().GetPlain())
		if got.GetCitationId() != w.citation || got.GetFull().GetPlain() != renderCensusFull || got.GetShort().GetPlain() != renderCensusShort {
			t.Errorf("citation = %v", got)
		}
		runs := got.GetFull().GetRuns()
		if len(runs) != 3 || runs[0].GetItalic() || !runs[1].GetItalic() || runs[1].GetText() != "Westmark Heritage" || runs[2].GetItalic() ||
			runs[0].GetText()+runs[1].GetText()+runs[2].GetText() != renderCensusFull {
			t.Errorf("runs = %v", runs)
		}
		if !slices.Equal(out.GetInputs().GetEvidenceGraphs(), []string{w.graph}) || !slices.Equal(out.GetInputs().GetSources(), []string{w.source}) {
			t.Errorf("inputs = %v", out.GetInputs())
		}
	})

	t.Run("AC-1.2 equal pages group", func(t *testing.T) {
		same := newCitation(t, w.dir, w.userID, w.artifact, w.graph, depictionvaluetest.Locator)
		other := newCitation(t, w.dir, w.userID, w.artifact, w.graph, depictionvaluetest.Locator)
		pageIDs := fieldIDsByKey(t, w.dir)
		setValues(t, w.dir, w.userID, pageIDs, "citation", same, map[string]string{"page": "14"})
		setValues(t, w.dir, w.userID, pageIDs, "citation", other, map[string]string{"page": "15"})
		out, err := renderCitations(t, w.dir, w.citation, same, other)
		if err != nil {
			t.Fatal(err)
		}
		c := out.GetCitations()
		if len(c) != 3 || c[0].GetGroupKey() != c[1].GetGroupKey() || c[0].GetGroupKey() == c[2].GetGroupKey() {
			t.Errorf("group keys %q %q %q", c[0].GetGroupKey(), c[1].GetGroupKey(), c[2].GetGroupKey())
		}
	})

	t.Run("an id that is not in the catalog is left out", func(t *testing.T) {
		absent := uuid.Must(uuid.NewV7()).String()
		out, err := renderCitations(t, w.dir, absent, w.citation)
		if err != nil || len(out.GetCitations()) != 1 || out.GetCitations()[0].GetCitationId() != w.citation {
			t.Fatalf("got %v, %v", out, err)
		}
	})

	runRPC(t, RenderCitations, []rpcTest{{
		name: "a malformed id",
		req:  &engine.RenderCitationsRequest{ProjectDir: w.dir, CitationIds: []string{"nope"}}, wantErr: true, wantErrIs: errInvalidID,
	}})

	t.Run("AC-1.6 unknown and supplied values", func(t *testing.T) {
		var ty engine.CreateSourceTypeResponse
		mustRPC(t, CreateSourceType, &engine.CreateSourceTypeRequest{ProjectDir: w.dir, UserId: w.userID, Label: "Pamphlet"}, &ty)
		formats := setFormats(t, w.dir, w.userID, ty.GetType().GetId(), &engine.CitationFormats{
			Full: "{meta.publisher}; {source.date}; p. {meta.page}.",
		})
		if len(formats.GetDiagnostics()) != 0 {
			t.Fatalf("diagnostics %v", formats.GetDiagnostics())
		}
		publisher := fieldIDsByKey(t, w.dir)["publisher"]
		made := func(title string, publisherText string, publisherMark *engine.ValueMark, date *engine.DateValueInput, dateMark *engine.ValueMark, locatorJSON string) string {
			var src engine.CreateSourceResponse
			mustRPC(t, CreateSource, &engine.CreateSourceRequest{
				ProjectDir: w.dir, UserId: w.userID, SourceTypeId: ty.GetType().GetId(), Title: title,
			}, &src)
			id := src.GetSource().GetId()
			mustRPC(t, SetMetadata, &engine.SetMetadataRequest{
				ProjectDir: w.dir, UserId: w.userID, Owner: &engine.MetadataOwner{Level: "source", Id: id},
				FieldId: publisher, ValueText: publisherText, Mark: publisherMark,
			}, &engine.SetMetadataResponse{})
			mustRPC(t, SetSourceDate, &engine.SetSourceDateRequest{
				ProjectDir: w.dir, UserId: w.userID, SourceId: id, Date: date, Mark: dateMark,
			}, &engine.SetSourceDateResponse{})
			art, graph := newArtifact(t, w.dir, w.userID, id, "Scan")
			return newCitation(t, w.dir, w.userID, art, graph, locatorJSON)
		}
		a := made("A", "", &engine.ValueMark{Unknown: true}, nil, &engine.ValueMark{Unknown: true},
			`{"version":1,"selectors":[{"type":"artifact"}]}`)
		b := made("B", "Ashby Press", &engine.ValueMark{Supplied: true}, qualifiedDate("ABT", 1880, 0, 0), &engine.ValueMark{Supplied: true},
			`{"version":1,"selectors":[{"type":"artifact"}]}`)
		page := fieldIDsByKey(t, w.dir)["page"]
		for _, set := range []struct {
			id, text string
			mark     *engine.ValueMark
		}{{a, "", &engine.ValueMark{Unknown: true}}, {b, "23", &engine.ValueMark{Supplied: true}}} {
			mustRPC(t, SetMetadata, &engine.SetMetadataRequest{
				ProjectDir: w.dir, UserId: w.userID, Owner: &engine.MetadataOwner{Level: "citation", Id: set.id},
				FieldId: page, ValueText: set.text, Mark: set.mark,
			}, &engine.SetMetadataResponse{})
		}
		out, err := renderCitations(t, w.dir, a, b)
		if err != nil || len(out.GetCitations()) != 2 {
			t.Fatalf("got %v, %v", out, err)
		}
		if got := out.GetCitations()[0].GetFull().GetPlain(); got != "n.p.; n.d.; p. unpaginated." {
			t.Errorf("A = %q", got)
		}
		if got := out.GetCitations()[1].GetFull().GetPlain(); got != "[Ashby Press]; [ca. 1880]; p. [23]." {
			t.Errorf("B = %q", got)
		}
	})
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

	t.Run("AC-2.1 the list form of a Source", func(t *testing.T) {
		out, err := preview(&engine.RenderCitationPreviewRequest{Form: "list", Target: &engine.RenderCitationPreviewRequest_SourceId{SourceId: w.source}})
		if err != nil {
			t.Fatal(err)
		}
		if out.GetRender().GetPlain() != renderCensusList || len(out.GetMissing()) != 0 || len(out.GetDiagnostics()) != 0 {
			t.Errorf("got %v", out)
		}
	})
	t.Run("a stored full form of a Citation", func(t *testing.T) {
		out, err := preview(&engine.RenderCitationPreviewRequest{Form: "full", Target: &engine.RenderCitationPreviewRequest_CitationId{CitationId: w.citation}})
		if err != nil || out.GetRender().GetPlain() != renderCensusFull {
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
		bare := seededSourceOfType(t, w.dir, w.userID, "census")
		out, err := preview(&engine.RenderCitationPreviewRequest{
			Form: "full", Format: strp(`{meta.jurisdiction}.`),
			Target: &engine.RenderCitationPreviewRequest_SourceId{SourceId: bare},
		})
		if err != nil {
			t.Fatal(err)
		}
		if len(out.GetMissing()) != 1 || len(out.GetMissing()[0].GetOptions()) != 1 {
			t.Fatalf("missing = %v", out.GetMissing())
		}
		if o := out.GetMissing()[0].GetOptions()[0]; o.GetLevel() != "" || o.GetField().GetKey() != "jurisdiction" {
			t.Errorf("option = %v, want jurisdiction with no level", o)
		}
	})
	t.Run("AC-2.4 a needed field with no value", func(t *testing.T) {
		bare := seededSourceOfType(t, w.dir, w.userID, "census")
		mustRPC(t, SetSourceDate, &engine.SetSourceDateRequest{
			ProjectDir: w.dir, UserId: w.userID, SourceId: bare, Date: pointDate(1880, 0, 0),
		}, &engine.SetSourceDateResponse{})
		out, err := preview(&engine.RenderCitationPreviewRequest{Form: "list", Target: &engine.RenderCitationPreviewRequest_SourceId{SourceId: bare}})
		if err != nil {
			t.Fatal(err)
		}
		if len(out.GetMissing()) != 1 || len(out.GetMissing()[0].GetOptions()) != 1 {
			t.Fatalf("missing = %v", out.GetMissing())
		}
		o := out.GetMissing()[0].GetOptions()[0]
		if o.GetLevel() != "source" || o.GetField().GetKey() != "jurisdiction" || o.GetField().GetLabel() == "" || o.GetBuiltin() != "" {
			t.Errorf("option = %v", o)
		}
	})
	t.Run("AC-2.7 a blank format renders nothing, an absent one the stored form", func(t *testing.T) {
		blank, err := preview(&engine.RenderCitationPreviewRequest{
			Form: "list", Format: strp("   "), Target: &engine.RenderCitationPreviewRequest_SourceId{SourceId: w.source},
		})
		if err != nil || blank.GetRender().GetPlain() != "" || len(blank.GetMissing()) != 0 || len(blank.GetDiagnostics()) != 0 {
			t.Fatalf("blank = %v, %v", blank, err)
		}
		stored, err := preview(&engine.RenderCitationPreviewRequest{
			Form: "list", Target: &engine.RenderCitationPreviewRequest_SourceId{SourceId: w.source},
		})
		if err != nil || stored.GetRender().GetPlain() != renderCensusList {
			t.Fatalf("stored = %v, %v", stored, err)
		}
	})
	t.Run("AC-7.1 a Source target with the full form reads its Citation", func(t *testing.T) {
		out, err := preview(&engine.RenderCitationPreviewRequest{Form: "full", Target: &engine.RenderCitationPreviewRequest_SourceId{SourceId: w.source}})
		if err != nil || out.GetRender().GetPlain() != renderCensusFull {
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
			req: &engine.RenderCitationPreviewRequest{
				ProjectDir: w.dir, Form: "list", Target: &engine.RenderCitationPreviewRequest_SourceId{SourceId: "nope"},
			}, wantErr: true, wantErrIs: errInvalidID,
		},
	})
}

func TestListCitationPlaceholders(t *testing.T) {
	dir, _, _ := sourceFixture(t)
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
		var line *engine.CitationPlaceholder
		var levels []string
		for _, p := range list("full").GetPlaceholders() {
			if len(levels) == 0 || levels[len(levels)-1] != p.GetLevel() {
				levels = append(levels, p.GetLevel())
			}
			if p.GetText() == "{meta.line_number}" {
				line = p
			}
		}
		if !slices.Equal(levels, []string{"source", "artifact", "graph", "citation", ""}) {
			t.Errorf("levels = %v", levels)
		}
		if line == nil || line.GetRef() != "meta.line_number" || line.GetLevel() != "" || line.GetField().GetKey() != "line_number" || line.GetBuiltin() != "" {
			t.Errorf("line = %v", line)
		}
	})

	runRPC(t, ListCitationPlaceholders, []rpcTest{{
		name: "an unknown form",
		req:  &engine.ListCitationPlaceholdersRequest{ProjectDir: dir, Form: "fourth"}, wantErr: true, wantErrIs: citations.ErrInvalid,
	}})
}

// TestRenderSeededPage is bar 13: on a new project the seeded page field
// answers nearest-first at the Citation and the graph, a locator's printed
// page answers when no level holds a value, and an unknown mark prints the
// field's unknown text.
func TestRenderSeededPage(t *testing.T) {
	w := newRenderWorld(t)
	ids := fieldIDsByKey(t, w.dir)
	newspaper := func() string {
		src := seededSourceOfType(t, w.dir, w.userID, "newspaper_item")
		mustRPC(t, SetSourceDate, &engine.SetSourceDateRequest{
			ProjectDir: w.dir, UserId: w.userID, SourceId: src, Date: pointDate(1880, 6, 14),
		}, &engine.SetSourceDateResponse{})
		setValues(t, w.dir, w.userID, ids, "source", src, map[string]string{"published_in": "Calder Valley Gazette"})
		return src
	}
	plain := func(t *testing.T, id string) (string, string) {
		t.Helper()
		out, err := renderCitations(t, w.dir, id)
		if err != nil {
			t.Fatal(err)
		}
		c := out.GetCitations()[0]
		return c.GetFull().GetPlain(), c.GetGroupKey()
	}
	const gazette = `"newspaper_item," Calder Valley Gazette, 14 June 1880, `

	t.Run("AC-1.1 and AC-1.5 each Citation holds its own page", func(t *testing.T) {
		src := newspaper()
		art, graph := newArtifact(t, w.dir, w.userID, src, "Issue PDF")
		first := newCitation(t, w.dir, w.userID, art, graph, depictionvaluetest.Locator)
		second := newCitation(t, w.dir, w.userID, art, graph, depictionvaluetest.Locator)
		setValues(t, w.dir, w.userID, ids, "citation", first, map[string]string{"page": "2", "column": "4"})
		setValues(t, w.dir, w.userID, ids, "citation", second, map[string]string{"page": "7", "column": "1"})
		p1, k1 := plain(t, first)
		p2, k2 := plain(t, second)
		if p1 != gazette+"p. 2, col. 4." || p2 != gazette+"p. 7, col. 1." || k1 == k2 {
			t.Errorf("plains %q %q, group keys %q %q", p1, p2, k1, k2)
		}
		third := newCitation(t, w.dir, w.userID, art, graph, depictionvaluetest.Locator)
		mustRPC(t, SetMetadata, &engine.SetMetadataRequest{
			ProjectDir: w.dir, UserId: w.userID, Owner: &engine.MetadataOwner{Level: "citation", Id: third},
			FieldId: ids["page"], Mark: &engine.ValueMark{Unknown: true},
		}, &engine.SetMetadataResponse{})
		if p3, _ := plain(t, third); p3 != gazette+"p. unpaginated." {
			t.Errorf("unknown page = %q", p3)
		}
	})

	t.Run("AC-1.2 a clipping's page is typed once on its graph", func(t *testing.T) {
		src := newspaper()
		art, graph := newArtifact(t, w.dir, w.userID, src, "Clipping")
		setValues(t, w.dir, w.userID, ids, "graph", graph, map[string]string{"page": "3", "column": "2"})
		var keys []string
		for range 5 {
			p, k := plain(t, newCitation(t, w.dir, w.userID, art, graph, depictionvaluetest.Locator))
			if p != gazette+"p. 3, col. 2." {
				t.Errorf("plain = %q", p)
			}
			keys = append(keys, k)
		}
		for _, k := range keys[1:] {
			if k != keys[0] {
				t.Errorf("group keys %q differ", keys)
			}
		}
	})

	t.Run("AC-1.3 a Citation's own page answers", func(t *testing.T) {
		cit := newCitation(t, w.dir, w.userID, w.artifact, w.graph, depictionvaluetest.Locator)
		setValues(t, w.dir, w.userID, ids, "citation", cit, map[string]string{"line_number": "21", "page": "15"})
		want := strings.NewReplacer("p. 14,", "p. 15,", "line 14,", "line 21,").Replace(renderCensusFull)
		if got, _ := plain(t, cit); got != want {
			t.Errorf("citation = %q, want %q", got, want)
		}
		if got, _ := plain(t, w.citation); got != renderCensusFull {
			t.Errorf("w.citation = %q", got)
		}
	})
}
