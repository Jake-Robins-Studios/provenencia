package citationrender

import (
	"errors"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database/citations"
	"github.com/Jake-Robins-Studios/provenencia/core/database/databasetest"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcemetadata"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sources"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue/datevaluetest"
	"github.com/Jake-Robins-Studios/provenencia/core/valuemark"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

// optionKeys is each missing entry's options as "level.key" or "level:builtin".
func optionKeys(missing [][]sourcemetadata.Alternative) [][]string {
	out := make([][]string, len(missing))
	for i, opts := range missing {
		for _, o := range opts {
			if o.Field != nil {
				out[i] = append(out[i], string(o.Level)+"."+o.Field.Key)
			} else {
				out[i] = append(out[i], string(o.Level)+":"+o.Builtin)
			}
		}
	}
	return out
}

func strp(s string) *string { return &s }

func TestRenderPreview(t *testing.T) {
	w := newCensus(t)
	// bare is a dated census Source with no values and no Citations.
	bare := w.source(w.typ.ID, "Bare census")
	w.setDate(bare.ID, datevaluetest.YMD(1880, 0, 0), valuemark.Mark{})
	absentSource, absentCitation := databasetest.BenchID(1, 777), databasetest.BenchID(4, 777)

	tests := []struct {
		name         string
		in           PreviewInput
		wantPlain    string
		wantMissing  [][]string
		wantDiagCode citationformat.DiagnosticCode
		wantDiagAt   citationformat.Span
		wantErr      error
	}{
		{name: "AC-2.1 the list form of a Source",
			in:        PreviewInput{Form: citationformat.FormList, Target: Target{SourceID: w.src.ID}},
			wantPlain: censusList},
		{name: "a Citation target takes the list form",
			in:        PreviewInput{Form: citationformat.FormList, Target: Target{CitationID: w.citation}},
			wantPlain: censusList},
		{name: "a Citation target takes the stored full form",
			in:        PreviewInput{Form: citationformat.FormFull, Target: Target{CitationID: w.citation}},
			wantPlain: censusFull},
		{name: "AC-2.2 an unsaved format",
			in: PreviewInput{Form: citationformat.FormFull, Target: Target{CitationID: w.citation},
				Format: strp(`{source.meta.jurisdiction}, line {graph.meta.line_number}.`)},
			wantPlain: "Calder County, Westmark, line 14."},
		{name: "AC-2.3 an unknown field",
			in: PreviewInput{Form: citationformat.FormFull, Target: Target{CitationID: w.citation},
				Format: strp(`{source.meta.nope}.`)},
			wantDiagCode: citationformat.CodeUnknownField, wantDiagAt: citationformat.Span{Start: 13, End: 17}},
		{name: "AC-2.4 a needed field with no value",
			in:          PreviewInput{Form: citationformat.FormList, Target: Target{SourceID: bare.ID}},
			wantPlain:   ". 1880 census.",
			wantMissing: [][]string{{"source.jurisdiction"}}},
		{name: "a chain empty on both levels lists both options",
			in: PreviewInput{Form: citationformat.FormFull, Target: Target{CitationID: w.citation},
				Format: strp(`{graph.meta.piece|source.meta.volume}.`)},
			wantPlain:   ".",
			wantMissing: [][]string{{"graph.piece", "source.volume"}}},
		{name: "AC-2.5 a Source target with the full form",
			in: PreviewInput{Form: citationformat.FormFull, Target: Target{SourceID: w.src.ID}}, wantErr: citations.ErrInvalid},
		{name: "both targets",
			in:      PreviewInput{Form: citationformat.FormList, Target: Target{SourceID: w.src.ID, CitationID: w.citation}},
			wantErr: citations.ErrInvalid},
		{name: "neither target",
			in: PreviewInput{Form: citationformat.FormList}, wantErr: citations.ErrInvalid},
		{name: "an unknown form",
			in:      PreviewInput{Form: "fourth", Target: Target{CitationID: w.citation}},
			wantErr: citations.ErrInvalid},
		{name: "a target id of the wrong length",
			in:      PreviewInput{Form: citationformat.FormList, Target: Target{SourceID: []byte{1}}},
			wantErr: citations.ErrInvalid},
		{name: "AC-2.6 a Source that is not there",
			in:      PreviewInput{Form: citationformat.FormList, Target: Target{SourceID: absentSource}},
			wantErr: sources.ErrNotFound},
		{name: "AC-2.6 a Citation that is not there",
			in:      PreviewInput{Form: citationformat.FormFull, Target: Target{CitationID: absentCitation}},
			wantErr: citations.ErrNotFound},
		{name: "AC-2.7 a blank unsaved format",
			in: PreviewInput{Form: citationformat.FormFull, Target: Target{CitationID: w.citation}, Format: strp("   ")}},
		{name: "a choice naming a field of another key",
			in: PreviewInput{Form: citationformat.FormFull, Target: Target{CitationID: w.citation},
				Format:  strp(`{source.meta.folio}.`),
				Choices: []sourcetypes.FieldChoice{{Key: "folio", FieldID: w.fieldID("piece")}}},
			wantErr: sourcetypes.ErrInvalid},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := RenderPreview(w.c, tt.in)
			if tt.wantErr != nil {
				if !errors.Is(err, tt.wantErr) {
					t.Fatalf("err = %v, want %v", err, tt.wantErr)
				}
				return
			}
			if err != nil {
				t.Fatal(err)
			}
			if got.Rendered.Plain() != tt.wantPlain {
				t.Errorf("render = %q, want %q", got.Rendered.Plain(), tt.wantPlain)
			}
			if gotKeys := optionKeys(got.Missing); !equalKeys(gotKeys, tt.wantMissing) {
				t.Errorf("missing = %v, want %v", gotKeys, tt.wantMissing)
			}
			if tt.wantDiagCode == "" {
				if len(got.Diagnostics) != 0 {
					t.Errorf("diagnostics = %+v, want none", got.Diagnostics)
				}
				return
			}
			if len(got.Diagnostics) != 1 || got.Diagnostics[0].Form != tt.in.Form ||
				got.Diagnostics[0].Code != tt.wantDiagCode || got.Diagnostics[0].Span != tt.wantDiagAt {
				t.Errorf("diagnostics = %+v, want %s at %+v", got.Diagnostics, tt.wantDiagCode, tt.wantDiagAt)
			}
		})
	}

	t.Run("a missing option's field carries its label", func(t *testing.T) {
		got, err := RenderPreview(w.c, PreviewInput{Form: citationformat.FormList, Target: Target{SourceID: bare.ID}})
		if err != nil || len(got.Missing) != 1 || len(got.Missing[0]) != 1 {
			t.Fatalf("got %+v, %v", got, err)
		}
		o := got.Missing[0][0]
		if o.Level != vocabkey.LevelSource || o.Field == nil || o.Field.Key != "jurisdiction" || o.Field.Label == "" {
			t.Errorf("option = %+v", o)
		}
	})
}

func equalKeys(a, b [][]string) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if len(a[i]) != len(b[i]) {
			return false
		}
		for j := range a[i] {
			if a[i][j] != b[i][j] {
				return false
			}
		}
	}
	return true
}
