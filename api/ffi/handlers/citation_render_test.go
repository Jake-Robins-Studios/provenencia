package handlers

import (
	"slices"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/api/proto/engine"
	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database/citations"
	"github.com/google/uuid"
)

const (
	renderCensusFull  = "1880 Westmark census, Calder County, Westmark, population schedule, ED 236, piece 1047, fol. 22, p. 14, schedule 9, dwelling 112, family 118, line 14, Ada Robins; digital image, Westmark Heritage (https://example.org/calder/1880 : accessed 12 March 2025); citing county film 7, item 3."
	renderCensusShort = "1880 Westmark census, Calder County, Westmark, ED 236, fol. 22, p. 14, dwell. 112, fam. 118, Ada Robins."
	renderCensusList  = "Calder County, Westmark. 1880 Westmark census, population schedule."
)

func pageLocatorJSON(label string) string {
	return `{"version":1,"selectors":[{"type":"page","page_label":"` + label + `"}]}`
}

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
	w.citation = newCitation(t, dir, userID, w.artifact, w.graph, pageLocatorJSON("14"))
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
		same := newCitation(t, w.dir, w.userID, w.artifact, w.graph, pageLocatorJSON("14"))
		other := newCitation(t, w.dir, w.userID, w.artifact, w.graph, pageLocatorJSON("15"))
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
		var formats engine.UpdateCitationFormatsResponse
		mustRPC(t, UpdateCitationFormats, &engine.UpdateCitationFormatsRequest{
			ProjectDir: w.dir, UserId: w.userID, TypeId: ty.GetType().GetId(),
			Full: "{source.meta.publisher}; {source.date}; p. {citation.page}.",
		}, &formats)
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
			`{"version":1,"selectors":[{"type":"page","page_unknown":true}]}`)
		b := made("B", "Ashby Press", &engine.ValueMark{Supplied: true}, qualifiedDate("ABT", 1880, 0, 0), &engine.ValueMark{Supplied: true},
			`{"version":1,"selectors":[{"type":"page","page_label":"23","page_supplied":true}]}`)
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
			Form: "full", Format: strp(`{source.meta.nope}.`),
			Target: &engine.RenderCitationPreviewRequest_CitationId{CitationId: w.citation},
		})
		if err != nil {
			t.Fatal(err)
		}
		want := &engine.CitationFormatDiagnostic{Form: "full", Code: string(citationformat.CodeUnknownField), Start: 13, End: 17}
		if len(out.GetDiagnostics()) != 1 || out.GetDiagnostics()[0].String() != want.String() || out.GetRender().GetPlain() != "" || len(out.GetMissing()) != 0 {
			t.Errorf("got %v", out)
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
	runRPC(t, RenderCitationPreview, []rpcTest{
		{
			name: "AC-2.5 no target set",
			req:  &engine.RenderCitationPreviewRequest{ProjectDir: w.dir, Form: "list"}, wantErr: true, wantErrIs: citations.ErrInvalid,
		},
		{
			name: "AC-2.5 a Source target with the full form",
			req: &engine.RenderCitationPreviewRequest{
				ProjectDir: w.dir, Form: "full", Target: &engine.RenderCitationPreviewRequest_SourceId{SourceId: w.source},
			}, wantErr: true, wantErrIs: citations.ErrInvalid,
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

func TestListCitationBuiltins(t *testing.T) {
	var out engine.ListCitationBuiltinsResponse
	mustRPC(t, ListCitationBuiltins, &engine.ListCitationBuiltinsRequest{}, &out)
	want := citationformat.Builtins()
	if len(out.GetBuiltins()) != len(want) || len(want) != 8 {
		t.Fatalf("got %d built-ins, want %d", len(out.GetBuiltins()), len(want))
	}
	for i, b := range want {
		got := out.GetBuiltins()[i]
		var opts []string
		for _, o := range b.Options {
			opts = append(opts, string(o))
		}
		if got.GetLevel() != string(b.Level) || got.GetName() != b.Name || got.GetDate() != b.Date || !slices.Equal(got.GetOptions(), opts) ||
			got.GetAlwaysSet() != b.AlwaysSet || got.GetInListForm() != b.InListForm() || got.GetUnknownText() != b.UnknownText {
			t.Errorf("built-in %d = %v, want %+v", i, got, b)
		}
	}
	date := out.GetBuiltins()[2]
	if date.GetName() != "date" || !date.GetDate() || !slices.Equal(date.GetOptions(), []string{"year", "full"}) || date.GetUnknownText() != "n.d." {
		t.Errorf("source.date = %v", date)
	}
	if page := out.GetBuiltins()[5]; page.GetName() != "page" || page.GetUnknownText() != "unpaginated" {
		t.Errorf("citation.page = %v", page)
	}
	for _, b := range out.GetBuiltins() {
		if b.GetInListForm() != (b.GetLevel() == "source") {
			t.Errorf("%s.%s in_list_form = %v", b.GetLevel(), b.GetName(), b.GetInListForm())
		}
	}
}
