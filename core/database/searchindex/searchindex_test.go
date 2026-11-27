package searchindex

import (
	"reflect"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/conclusionsummaries"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue/datevaluetest"
	"github.com/Jake-Robins-Studios/provenencia/core/eventtitle"
	"github.com/Jake-Robins-Studios/provenencia/core/namevalue"
	"github.com/Jake-Robins-Studios/provenencia/core/namevalue/namevaluetest"
	"github.com/Jake-Robins-Studios/provenencia/core/valuecompare"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

func TestMigrationCreatesSearchTables(t *testing.T) {
	c, err := database.Create(t.TempDir(), "t.provenencia")
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()
	db, err := c.DB()
	if err != nil {
		t.Fatal(err)
	}
	var version int
	if err := db.QueryRow(`PRAGMA user_version`).Scan(&version); err != nil {
		t.Fatal(err)
	}
	if version < 20 {
		t.Fatalf("user_version %d, want >= 20", version)
	}
	for _, table := range []string{
		"catalog_search_docs",
		"catalog_search_fts",
		"catalog_search_fts_trigram",
		"catalog_search_meta",
	} {
		var name string
		err := db.QueryRow(
			`SELECT name FROM sqlite_master WHERE type IN ('table','view') AND name = ?`,
			table,
		).Scan(&name)
		if err != nil {
			t.Fatalf("missing %s: %v", table, err)
		}
	}
	// FTS5 must accept a write (requires -tags fts5).
	if err := Upsert(db, Document{
		Kind:         KindSourceType,
		EntityID:     "00000000-0000-0000-0000-000000000001",
		DisplayTitle: "Smoke",
		Title:        "Smoke",
		Secondary:    "smoke-key",
	}); err != nil {
		t.Fatalf("fts upsert: %v", err)
	}
	var n int
	if err := db.QueryRow(`SELECT COUNT(*) FROM catalog_search_fts WHERE catalog_search_fts MATCH 'smoke'`).Scan(&n); err != nil {
		t.Fatal(err)
	}
	if n != 1 {
		t.Fatalf("match count %d", n)
	}
	// Trigram index is substring-oriented; three+ chars should hit.
	if err := db.QueryRow(
		`SELECT COUNT(*) FROM catalog_search_fts_trigram WHERE catalog_search_fts_trigram MATCH 'smo'`,
	).Scan(&n); err != nil {
		t.Fatalf("trigram match: %v", err)
	}
	if n != 1 {
		t.Fatalf("trigram match count %d", n)
	}
}

func TestEventMatchTitleCoupleUsesTypeWord(t *testing.T) {
	tests := []struct {
		name  string
		label string
		want  string
	}{
		{name: "marriage", label: "Marriage", want: "Marriage of James and Mary"},
		{name: "engagement", label: "Engagement", want: "Engagement of James and Mary"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := eventMatchTitle(conclusionsummaries.EventSummary{
				Title: eventtitle.Plan{
					Rule: eventtitle.RuleCouple,
					Parts: eventtitle.Parts{
						TypeLabel: tt.label,
						Subjects: []eventtitle.Subject{
							{Name: &namevalue.Value{Form: "James"}},
							{Name: &namevalue.Value{Form: "Mary"}},
						},
					},
				},
			})
			if got != tt.want {
				t.Fatalf("got %q want %q", got, tt.want)
			}
		})
	}
}

func TestMatchTextListsEachAlternateOnce(t *testing.T) {
	place := conclusionsummaries.PlaceSummary{Names: []string{"Montréal", "Ville-Marie"}, Parents: []string{"Québec"}}
	person := conclusionsummaries.PersonSummary{Name: &namevalue.Value{Form: "José Robins"}}
	for _, tt := range []struct {
		name          string
		head          handleHead
		v             handleValues
		wantTitle     string
		wantSecondary []string
	}{
		{
			name: "place", head: handleHead{id: "p", kind: vocabkey.Place},
			v:         handleValues{vocabkey.PropertyToponym: {"Montréal", "Montreal", "Ville-Marie", "Ville Marie"}},
			wantTitle: "Montréal", wantSecondary: []string{"@\tVille-Marie", "Québec"},
		},
		{
			name: "person", head: handleHead{id: "p", kind: vocabkey.Person},
			v:         handleValues{vocabkey.PropertyName: {"José Robins", "Jose Robins", "JOSÉ ROBINS", "Joe Robins"}},
			wantTitle: "José Robins", wantSecondary: []string{"=\tJoe Robins"},
		},
		{
			name: "label reading like the title adds no line", head: handleHead{id: "p", kind: vocabkey.Place, label: "montreal"},
			v:         handleValues{vocabkey.PropertyToponym: {"Montréal", "Montreal", "Ville-Marie", "Ville Marie"}},
			wantTitle: "Montréal", wantSecondary: []string{"@\tVille-Marie", "Québec"},
		},
		{
			name: "a spelling that differs by a word break stays", head: handleHead{id: "p", kind: vocabkey.Place},
			v:         handleValues{vocabkey.PropertyToponym: {"Montréal", "Ville-Marie", "Villemarie"}},
			wantTitle: "Montréal", wantSecondary: []string{"@\tVille-Marie", "@\tVillemarie", "Québec"},
		},
	} {
		t.Run(tt.name, func(t *testing.T) {
			person.Entity.ID, place.Entity.ID = []byte("p"), []byte("p")
			summaries := conclusionsummaries.NewSummaries(
				[]conclusionsummaries.PersonSummary{person}, nil, []conclusionsummaries.PlaceSummary{place})
			title, secondary := matchText(tt.head, []byte("p"), tt.v, summaries)
			if title != tt.wantTitle || !reflect.DeepEqual(secondary, tt.wantSecondary) {
				t.Fatalf("title %q secondary %q, want %q %q", title, secondary, tt.wantTitle, tt.wantSecondary)
			}
		})
	}
}

func TestFoldedSpelling(t *testing.T) {
	for _, tt := range []struct {
		raw  string
		want string
		ok   bool
	}{
		{"Søby", "soby", true},
		{"Montréal", "", false},
		{"Straße", "strasse", true},
		{"O'Brien", "obrien", true},
		{"D’Arcy", "darcy", true},
		{"1,200", "", false},
		{"scan.pdf", "", false},
		{"St.", "", false},
		{"soby", "", false},
	} {
		got, ok := FoldedSpelling(tt.raw)
		if got != tt.want || ok != tt.ok {
			t.Errorf("FoldedSpelling(%q) = (%q, %v), want (%q, %v)", tt.raw, got, ok, tt.want, tt.ok)
		}
	}
}

func TestFoldedWords(t *testing.T) {
	for _, tt := range []struct {
		texts []string
		want  string
	}{
		{[]string{"Ærøskøbing Havn"}, "aeroskobing"},
		{[]string{"Straße Straße"}, "strasse"},
		{[]string{"St. Søby"}, "soby"},
		{[]string{"Łask", "Søby", "Łask"}, "lask soby"},
		{[]string{""}, ""},
	} {
		if got := foldedWords(tt.texts...); got != tt.want {
			t.Errorf("foldedWords(%q) = %q, want %q", tt.texts, got, tt.want)
		}
	}
}

func TestMatchTextDropsAlternateTheFoldedColumnCovers(t *testing.T) {
	place := conclusionsummaries.PlaceSummary{Names: []string{"Søby", "Soby"}}
	place.Entity.ID = []byte("p")
	summaries := conclusionsummaries.NewSummaries(nil, nil, []conclusionsummaries.PlaceSummary{place})
	title, secondary := matchText(handleHead{id: "p", kind: vocabkey.Place}, []byte("p"), handleValues{}, summaries)
	if title != "Søby" || len(secondary) != 0 {
		t.Fatalf("title %q secondary %q", title, secondary)
	}
}

func TestMatchTextCarriesFoldedInNicknames(t *testing.T) {
	for _, tt := range []struct {
		form string
		v    handleValues
		want []string
	}{
		{"Thomas Smith", handleValues{vocabkey.PropertyName: {"Thomas Smith", "Tomas Smyth"}},
			[]string{"=\tTomas Smyth", "~\tthom", "~\tthos", "~\ttom", "~\ttommy"}},
		{"Tom Smith", handleValues{}, []string{"~\ttommy"}},
		{"Hannah Smith", handleValues{}, []string{"~\tanna", "~\tnan", "~\tnanny"}},
		{"Smith", handleValues{}, nil},
	} {
		t.Run(tt.form, func(t *testing.T) {
			person := conclusionsummaries.PersonSummary{Name: namevaluetest.Western(tt.form)}
			person.Entity.ID = []byte("p")
			summaries := conclusionsummaries.NewSummaries([]conclusionsummaries.PersonSummary{person}, nil, nil)
			_, secondary := matchText(handleHead{id: "p", kind: vocabkey.Person}, []byte("p"), tt.v, summaries)
			if !reflect.DeepEqual(secondary, tt.want) {
				t.Fatalf("secondary %q, want %q", secondary, tt.want)
			}
		})
	}
}

// An Event's search text follows its date line: the dating's two dates, not
// every as-of the event records.
func TestEventSecondaryIndexesDating(t *testing.T) {
	ymd := datevaluetest.YMD
	asOfs := func(ds ...*datevalue.Value) conclusionsummaries.EventSummary {
		var samples []datevalue.Value
		for _, d := range ds {
			samples = append(samples, *d)
		}
		return conclusionsummaries.EventSummary{Dating: valuecompare.DatingOf(nil, nil, nil, samples)}
	}
	if got := eventMatchSecondary(asOfs(ymd(1990, 1, 10), ymd(2015, 2, 10))); !reflect.DeepEqual(got, []string{"1990-01-10", "2015-02-10"}) {
		t.Errorf("two as-ofs indexed %q", got)
	}
	if got := eventMatchSecondary(asOfs(ymd(1990, 0, 0), ymd(2003, 0, 0), ymd(2015, 0, 0))); !reflect.DeepEqual(got, []string{"1990", "2015"}) {
		t.Errorf("three as-ofs indexed %q, want the middle year absent", got)
	}
	dated := conclusionsummaries.EventSummary{Dating: valuecompare.DatingOf(ymd(1849, 0, 0), nil, nil, nil)}
	if got := eventMatchSecondary(dated); !reflect.DeepEqual(got, []string{"1849"}) {
		t.Errorf("a date indexed %q", got)
	}
	if ProjectionVersion != 13 {
		t.Errorf("ProjectionVersion = %d, want 13", ProjectionVersion)
	}
}
