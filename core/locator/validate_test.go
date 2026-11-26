package locator

import (
	"errors"
	"fmt"
	"math"
	"strconv"
	"strings"
	"testing"
	"time"
)

// ringPoints returns n points on a circle of radius 0.4 around (0.5, 0.5),
// counter-clockwise from angle 0.
func ringPoints(n int) []point {
	pts := make([]point, n)
	for i := range pts {
		a := 2 * math.Pi * float64(i) / float64(n)
		pts[i] = point{X: 0.5 + 0.4*math.Cos(a), Y: 0.5 + 0.4*math.Sin(a)}
	}
	return pts
}

// ringRegion returns a region selector object holding an n-point ring.
func ringRegion(n int) string {
	var b strings.Builder
	b.WriteString(`{"type":"region","unit":"normalized","points":[`)
	for i, p := range ringPoints(n) {
		if i > 0 {
			b.WriteString(",")
		}
		fmt.Fprintf(&b, `{"x":%s,"y":%s}`, strconv.FormatFloat(p.X, 'f', 6, 64), strconv.FormatFloat(p.Y, 'f', 6, 64))
	}
	b.WriteString(`]}`)
	return b.String()
}

// paddedArtifactDoc returns a valid artifact-only document of n bytes, padded
// with spaces inside the JSON.
func paddedArtifactDoc(n int) string {
	const base = `{"version":1,"selectors":[{"type":"artifact"}]}`
	return `{"version":1,"selectors":[{"type":"artifact"}` + strings.Repeat(" ", n-len(base)) + `]}`
}

func TestValidateDocCapBeforeCrossing(t *testing.T) {
	doc := document{Version: 1, Selectors: []selectorRaw{{Type: TypeRegion, Unit: "normalized", Points: ringPoints(200_000)}}}
	start := time.Now()
	err := validateDoc(doc)
	elapsed := time.Since(start)
	if !errors.Is(err, ErrInvalid) {
		t.Fatalf("got %v, want ErrInvalid", err)
	}
	if elapsed > 100*time.Millisecond {
		t.Fatalf("took %v, want under 100ms", elapsed)
	}
}

func TestValidate(t *testing.T) {
	tests := []struct {
		name    string
		json    string
		wantErr error
	}{
		{
			name: "artifact only",
			json: `{"version":1,"selectors":[{"type":"artifact"}]}`,
		},
		{
			name: "artifact then page then region",
			json: `{"version":1,"selectors":[
				{"type":"artifact"},
				{"type":"page","artifact_page":2},
				{"type":"region","unit":"normalized","points":[
					{"x":0.1,"y":0.1},{"x":0.4,"y":0.1},{"x":0.4,"y":0.3},{"x":0.1,"y":0.3}
				]}
			]}`,
		},
		{
			name: "page only",
			json: `{"version":1,"selectors":[{"type":"page","artifact_page":37}]}`,
		},
		{
			name:    "file page with a printed page",
			json:    `{"version":1,"selectors":[{"type":"page","artifact_page":37,"page_label":"23"}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "printed page only",
			json:    `{"version":1,"selectors":[{"type":"page","page_label":"14"}]}`,
			wantErr: ErrInvalid,
		},
		{
			name: "printed page then region",
			json: `{"version":1,"selectors":[{"type":"artifact"},{"type":"page","page_label":"14"},{"type":"region","unit":"normalized","points":[
				{"x":0.1,"y":0.1},{"x":0.4,"y":0.1},{"x":0.4,"y":0.3},{"x":0.1,"y":0.3}
			]}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "file page with blank printed page",
			json:    `{"version":1,"selectors":[{"type":"page","artifact_page":37,"page_label":""}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "printed page unknown alone",
			json:    `{"version":1,"selectors":[{"type":"page","page_unknown":true}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "file page unknown",
			json:    `{"version":1,"selectors":[{"type":"page","artifact_page":37,"page_unknown":true}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "printed page supplied",
			json:    `{"version":1,"selectors":[{"type":"page","page_label":"23","page_supplied":true}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "file page and printed page supplied",
			json:    `{"version":1,"selectors":[{"type":"page","artifact_page":37,"page_label":"23","page_supplied":true}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "file page, blank label, unknown",
			json:    `{"version":1,"selectors":[{"type":"page","artifact_page":37,"page_label":"  ","page_unknown":true}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "blank label, unknown, no file page",
			json:    `{"version":1,"selectors":[{"type":"page","page_label":"  ","page_unknown":true}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "supplied alone, nothing else",
			json:    `{"version":1,"selectors":[{"type":"page","page_supplied":true}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "unknown false alone",
			json:    `{"version":1,"selectors":[{"type":"page","page_unknown":false}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "supplied false alone",
			json:    `{"version":1,"selectors":[{"type":"page","page_supplied":false}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "unknown not a bool",
			json:    `{"version":1,"selectors":[{"type":"page","page_unknown":"yes"}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "supplied not a bool",
			json:    `{"version":1,"selectors":[{"type":"page","artifact_page":1,"page_supplied":1}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "file page zero with unknown",
			json:    `{"version":1,"selectors":[{"type":"page","artifact_page":0,"page_unknown":true}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "a retired key on a padded page type",
			json:    `{"version":1,"selectors":[{"type":" page ","artifact_page":3,"page_label":"x"}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "a null retired key",
			json:    `{"version":1,"selectors":[{"type":"page","artifact_page":3,"page_label":null}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "a retired key in another case",
			json:    `{"version":1,"selectors":[{"type":"page","artifact_page":3,"Page_Label":"x"}]}`,
			wantErr: ErrInvalid,
		},
		{
			name: "a retired key on an unknown selector type",
			json: `{"version":1,"selectors":[{"type":"time_range","start_ms":0,"page_label":"x"}]}`,
		},
		{
			name: "region rectangle",
			json: `{"version":1,"selectors":[{"type":"region","unit":"normalized","points":[
				{"x":0.1,"y":0.1},{"x":0.5,"y":0.1},{"x":0.5,"y":0.4},{"x":0.1,"y":0.4}
			]}]}`,
		},
		{
			name: "page then region",
			json: `{"version":1,"selectors":[
				{"type":"page","artifact_page":1},
				{"type":"region","unit":"normalized","points":[
					{"x":0.2,"y":0.2},{"x":0.8,"y":0.2},{"x":0.8,"y":0.8},{"x":0.2,"y":0.8}
				]}
			]}`,
		},
		{
			name: "text_quote",
			json: `{"version":1,"selectors":[{"type":"text_quote","exact":"William Robins","prefix":"of ","suffix":" aged"}]}`,
		},
		{
			name: "unknown type preserved",
			json: `{"version":1,"selectors":[{"type":"time_range","start_ms":0,"end_ms":10}]}`,
		},
		{
			name:    "empty",
			json:    "",
			wantErr: ErrInvalid,
		},
		{
			name:    "bad json",
			json:    `{`,
			wantErr: ErrInvalid,
		},
		{
			name:    "wrong version",
			json:    `{"version":2,"selectors":[{"type":"page","artifact_page":1}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "no selectors",
			json:    `{"version":1,"selectors":[]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "artifact not first",
			json:    `{"version":1,"selectors":[{"type":"page","artifact_page":1},{"type":"artifact"}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "page zero",
			json:    `{"version":1,"selectors":[{"type":"page","artifact_page":0}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "page selector with nothing in it",
			json:    `{"version":1,"selectors":[{"type":"page"}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "page selector with a blank printed page and no file page",
			json:    `{"version":1,"selectors":[{"type":"page","page_label":"  "}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "file page zero beside a printed page",
			json:    `{"version":1,"selectors":[{"type":"page","artifact_page":0,"page_label":"4"}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "two page selectors",
			json:    `{"version":1,"selectors":[{"type":"page","artifact_page":1},{"type":"page","artifact_page":2}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "two page selectors, one printed page only",
			json:    `{"version":1,"selectors":[{"type":"page","page_label":"14"},{"type":"page","artifact_page":2}]}`,
			wantErr: ErrInvalid,
		},
		{
			name:    "text_quote blank exact",
			json:    `{"version":1,"selectors":[{"type":"text_quote","exact":"  "}]}`,
			wantErr: ErrInvalid,
		},
		{
			name: "region too few points",
			json: `{"version":1,"selectors":[{"type":"region","unit":"normalized","points":[
				{"x":0.1,"y":0.1},{"x":0.5,"y":0.1}
			]}]}`,
			wantErr: ErrInvalid,
		},
		{
			name: "region wrong unit",
			json: `{"version":1,"selectors":[{"type":"region","unit":"pixels","points":[
				{"x":0.1,"y":0.1},{"x":0.5,"y":0.1},{"x":0.5,"y":0.4}
			]}]}`,
			wantErr: ErrInvalid,
		},
		{
			name: "region closed ring repeated",
			json: `{"version":1,"selectors":[{"type":"region","unit":"normalized","points":[
				{"x":0.1,"y":0.1},{"x":0.5,"y":0.1},{"x":0.5,"y":0.4},{"x":0.1,"y":0.1}
			]}]}`,
			wantErr: ErrInvalid,
		},
		{
			name: "region out of bounds",
			json: `{"version":1,"selectors":[{"type":"region","unit":"normalized","points":[
				{"x":0.1,"y":0.1},{"x":1.5,"y":0.1},{"x":0.5,"y":0.4}
			]}]}`,
			wantErr: ErrInvalid,
		},
		{
			name: "region zero area",
			json: `{"version":1,"selectors":[{"type":"region","unit":"normalized","points":[
				{"x":0.1,"y":0.1},{"x":0.5,"y":0.1},{"x":0.9,"y":0.1}
			]}]}`,
			wantErr: ErrInvalid,
		},
		{
			name: "region at the point cap",
			json: fmt.Sprintf(`{"version":1,"selectors":[%s]}`, ringRegion(MaxRegionPoints)),
		},
		{
			name:    "region over the point cap",
			json:    fmt.Sprintf(`{"version":1,"selectors":[%s]}`, ringRegion(MaxRegionPoints+1)),
			wantErr: ErrInvalid,
		},
		{
			name:    "points over the cap across two region selectors",
			json:    fmt.Sprintf(`{"version":1,"selectors":[{"type":"page","artifact_page":1},%s,%s]}`, ringRegion(129), ringRegion(128)),
			wantErr: ErrInvalid,
		},
		{
			name: "document at the byte cap",
			json: paddedArtifactDoc(MaxDocumentBytes),
		},
		{
			name:    "document over the byte cap",
			json:    paddedArtifactDoc(MaxDocumentBytes + 1),
			wantErr: ErrInvalid,
		},
		{
			name: "region self intersecting bowtie",
			json: `{"version":1,"selectors":[{"type":"region","unit":"normalized","points":[
				{"x":0.1,"y":0.1},{"x":0.9,"y":0.9},{"x":0.1,"y":0.9},{"x":0.9,"y":0.1}
			]}]}`,
			wantErr: ErrInvalid,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := Validate(tt.json)
			if tt.wantErr != nil {
				if !errors.Is(err, tt.wantErr) {
					t.Fatalf("got %v, want %v", err, tt.wantErr)
				}
				return
			}
			if err != nil {
				t.Fatal(err)
			}
		})
	}
}

func TestArtifactPage(t *testing.T) {
	tests := []struct {
		name string
		doc  string
		want int
	}{
		{"printed page only", `{"version":1,"selectors":[{"type":"page","page_label":" 14 "}]}`, 0},
		{"page with label", `{"version":1,"selectors":[{"type":"artifact"},{"type":"page","artifact_page":37,"page_label":" 23 "}]}`, 37},
		{"page without label", `{"version":1,"selectors":[{"type":"page","artifact_page":4}]}`, 4},
		{"artifact selector only", `{"version":1,"selectors":[{"type":"artifact"}]}`, 0},
		{"two page selectors", `{"version":1,"selectors":[{"type":"page","artifact_page":1},{"type":"page","artifact_page":2}]}`, 0},
		{"page selector without artifact_page", `{"version":1,"selectors":[{"type":"page"}]}`, 0},
		{"page above int32", `{"version":1,"selectors":[{"type":"page","artifact_page":4294967333}]}`, 0},
		{"empty", ``, 0},
		{"truncated", `{`, 0},
		{"version 2", `{"version":2,"selectors":[{"type":"page","artifact_page":3}]}`, 0},
		{"over the byte cap", paddedArtifactDoc(MaxDocumentBytes + 1), 0},
		{"unknown alone", `{"version":1,"selectors":[{"type":"page","page_unknown":true}]}`, 0},
		{"file page, label, supplied", `{"version":1,"selectors":[{"type":"artifact"},{"type":"page","artifact_page":37,"page_label":" 23 ","page_supplied":true}]}`, 37},
		{"stored label with unknown", `{"version":1,"selectors":[{"type":"page","page_label":"23","page_unknown":true}]}`, 0},
		{"stored supplied without a label", `{"version":1,"selectors":[{"type":"page","artifact_page":4,"page_supplied":true}]}`, 4},
		{"a non-bool mark beside a file page", `{"version":1,"selectors":[{"type":"page","artifact_page":5,"page_unknown":"yes"}]}`, 5},
		{"page above int32 with unknown", `{"version":1,"selectors":[{"type":"page","artifact_page":3000000000,"page_unknown":true}]}`, 0},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := ArtifactPage(tt.doc); got != tt.want {
				t.Fatalf("ArtifactPage = %d; want %d", got, tt.want)
			}
		})
	}
}
