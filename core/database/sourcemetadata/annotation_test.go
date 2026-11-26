package sourcemetadata

import (
	"reflect"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sources"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes/sourcetypestest"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue"
	"github.com/Jake-Robins-Studios/provenencia/core/valuemark"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
	"github.com/Jake-Robins-Studios/provenencia/core/writes"
	"github.com/google/uuid"
)

// chainsOf is the requirements of one full-form text, fields named by id.
func chainsOf(t *testing.T, text string) []citationformat.Requirement {
	t.Helper()
	tpl, diags := citationformat.Parse(text, citationformat.FormFull)
	if tpl == nil {
		t.Fatalf("%q: %v", text, diags)
	}
	return citationformat.Requirements(tpl)
}

func fieldTarget(id uuid.UUID) citationformat.Target {
	return citationformat.Target{Field: citationformat.FieldRef{ID: id}}
}

// listTarget is a field as the list form reads it: at the Source alone.
func listTarget(id uuid.UUID) citationformat.Target {
	return citationformat.Target{Level: citationformat.ListFormLevel, Field: citationformat.FieldRef{ID: id}}
}

// chainsOfForms is the requirements of a full-form and a list-form text.
func chainsOfForms(t *testing.T, full, list string) []citationformat.Requirement {
	t.Helper()
	var tpls []*citationformat.Template
	for _, in := range []struct {
		text string
		form citationformat.Form
	}{{full, citationformat.FormFull}, {list, citationformat.FormList}} {
		if in.text == "" {
			continue
		}
		tpl, diags := citationformat.Parse(in.text, in.form)
		if tpl == nil {
			t.Fatalf("%q: %v", in.text, diags)
		}
		tpls = append(tpls, tpl)
	}
	return citationformat.Requirements(tpls...)
}

func TestNeedsAt(t *testing.T) {
	a, b, p := uuid.New(), uuid.New(), uuid.New()
	tok := func(id uuid.UUID) string { return "#" + id.String() }
	src, gr := vocabkey.LevelSource, vocabkey.LevelGraph
	tests := []struct {
		name    string
		full    string
		list    string
		level   vocabkey.Level
		need    map[uuid.UUID]citationformat.Need
		order   []uuid.UUID
		builtin citationformat.Need // the need of the Source date's chain, "" for none
	}{
		{name: "outside a group is needed", full: "{meta." + tok(a) + "}.", level: src,
			need: map[uuid.UUID]citationformat.Need{a: citationformat.NeedNeeded}, order: []uuid.UUID{a}},
		{name: "inside a group is used", full: "[{meta." + tok(a) + "}]", level: src,
			need: map[uuid.UUID]citationformat.Need{a: citationformat.NeedUsed}, order: []uuid.UUID{a}},
		{name: "a field heads at the graph", full: "{meta." + tok(a) + "}.", level: gr,
			need: map[uuid.UUID]citationformat.Need{a: citationformat.NeedNeeded}, order: []uuid.UUID{a}},
		{name: "a field heads at the artifact", full: "{meta." + tok(a) + "}.", level: vocabkey.LevelArtifact,
			need: map[uuid.UUID]citationformat.Need{a: citationformat.NeedNeeded}, order: []uuid.UUID{a}},
		{name: "a list-form field heads at the Source", list: "{meta." + tok(a) + "}.", level: src,
			need: map[uuid.UUID]citationformat.Need{a: citationformat.NeedNeeded}, order: []uuid.UUID{a}},
		{name: "a list-form field does not head at the graph", list: "{meta." + tok(a) + "}.", level: gr,
			need: map[uuid.UUID]citationformat.Need{}},
		{name: "a full and a list read of one field: needed at the Source", full: "[{meta." + tok(a) + "}]", list: "{meta." + tok(a) + "}", level: src,
			need: map[uuid.UUID]citationformat.Need{a: citationformat.NeedNeeded}, order: []uuid.UUID{a}},
		{name: "a full and a list read of one field: used at the graph", full: "[{meta." + tok(a) + "}]", list: "{meta." + tok(a) + "}", level: gr,
			need: map[uuid.UUID]citationformat.Need{a: citationformat.NeedUsed}, order: []uuid.UUID{a}},
		{name: "a later option is used and no head", full: "{meta." + tok(a) + "|meta." + tok(b) + "}.", level: src,
			need: map[uuid.UUID]citationformat.Need{a: citationformat.NeedNeeded, b: citationformat.NeedUsed}, order: []uuid.UUID{a}},
		{name: "an always-set option makes the chain used", full: "{meta." + tok(a) + "|source.title}", level: src,
			need: map[uuid.UUID]citationformat.Need{a: citationformat.NeedUsed}, order: []uuid.UUID{a}},
		{name: "a built-in head leaves its options used", full: "{source.date|meta." + tok(p) + "}", level: src,
			need: map[uuid.UUID]citationformat.Need{p: citationformat.NeedUsed}, builtin: citationformat.NeedNeeded},
		{name: "the strongest chain wins", full: "[{meta." + tok(a) + "}]{meta." + tok(a) + "}", level: src,
			need: map[uuid.UUID]citationformat.Need{a: citationformat.NeedNeeded}, order: []uuid.UUID{a}},
		{name: "a field named by key is not read", full: "{meta.line_number}.", level: src,
			need: map[uuid.UUID]citationformat.Need{}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ln := needsAt(chainsOfForms(t, tt.full, tt.list), tt.level)
			if !reflect.DeepEqual(ln.need, tt.need) {
				t.Errorf("need = %v, want %v", ln.need, tt.need)
			}
			if !reflect.DeepEqual(ln.order, tt.order) {
				t.Errorf("order = %v, want %v", ln.order, tt.order)
			}
			var builtin citationformat.Need
			for _, ch := range ln.builtinHeads[citationformat.SourceDate] {
				builtin = builtin.Max(ch.Need)
			}
			if builtin != tt.builtin {
				t.Errorf("built-in need = %q, want %q", builtin, tt.builtin)
			}
		})
	}
	t.Run("built-in heads only at the source level", func(t *testing.T) {
		ln := needsAt(chainsOf(t, "{source.date}"), vocabkey.LevelGraph)
		if ln.builtinHeads != nil {
			t.Errorf("builtinHeads = %v at graph", ln.builtinHeads)
		}
	})
}

func TestAnnotate(t *testing.T) {
	a := uuid.New()
	tok := "#" + a.String()
	field := metadatafields.Field{ID: a[:], Key: "line_number", Label: "Line", UnknownText: "n.l."}
	fields := map[string]metadatafields.Field{string(a[:]): field}
	oneField := chainsOf(t, "{meta."+tok+"}.")
	head := fieldTarget(a)
	row := func(text string, mark valuemark.Mark) map[string]Row {
		return map[string]Row{string(a[:]): {FieldID: a[:], ValueText: text, Mark: mark}}
	}
	y := 1890
	dated := datevalue.Value{Kind: datevalue.KindPoint, StartYear: &y}
	// values builds the resolver of a board: the owner's own rows, the
	// Source's rows and the Source's date.
	values := func(owner vocabkey.Level, own, source map[string]Row, date *citationformat.Value) CitationValues {
		v := CitationValues{
			Rows:   map[vocabkey.Level]map[string]Row{vocabkey.LevelSource: source},
			Fields: fields,
		}
		v.Rows[owner] = own
		if date != nil {
			v.Builtins = map[citationformat.Target]citationformat.Value{citationformat.SourceDate: *date}
		}
		return v
	}
	gr, art, src := vocabkey.LevelGraph, vocabkey.LevelArtifact, vocabkey.LevelSource

	tests := []struct {
		name   string
		chains []citationformat.Requirement
		owner  vocabkey.Level
		values CitationValues
		want   Annotation
	}{
		{name: "the Source answers a graph's head", chains: oneField, owner: gr,
			values: values(gr, nil, row("14", valuemark.Mark{}), nil),
			want:   Annotation{Need: citationformat.NeedNeeded, MetElsewhere: true}},
		{name: "the Source answers an Artifact's head", chains: oneField, owner: art,
			values: values(art, nil, row("14", valuemark.Mark{}), nil),
			want:   Annotation{Need: citationformat.NeedNeeded, MetElsewhere: true}},
		{name: "the Source value is unknown", chains: oneField, owner: gr,
			values: values(gr, nil, row("", valuemark.Mark{Unknown: true}), nil),
			want:   Annotation{Need: citationformat.NeedNeeded, MetElsewhere: true}},
		{name: "nothing answers", chains: oneField, owner: gr,
			values: values(gr, nil, nil, nil),
			want:   Annotation{Need: citationformat.NeedNeeded}},
		{name: "the head's own value does not answer for it", chains: oneField, owner: gr,
			values: values(gr, row("9", valuemark.Mark{}), nil, nil),
			want:   Annotation{Need: citationformat.NeedNeeded}},
		{name: "a Source head answered on the Source is not elsewhere", chains: oneField, owner: src,
			values: values(src, row("9", valuemark.Mark{}), nil, nil),
			want:   Annotation{Need: citationformat.NeedNeeded}},
		{name: "a list-form head on the Source is not met by the Source's own value", chains: chainsOfForms(t, "", "{meta."+tok+"}."), owner: src,
			values: values(src, row("9", valuemark.Mark{}), nil, nil),
			want:   Annotation{Need: citationformat.NeedNeeded}},
		{name: "a built-in tail answers", chains: chainsOf(t, "{meta."+tok+"|source.date}."), owner: gr,
			values: values(gr, nil, nil, &citationformat.Value{Date: &dated}),
			want: Annotation{Need: citationformat.NeedNeeded, MetElsewhere: true,
				Alternatives: []Alternative{{Level: src, Builtin: "date"}}}},
		{name: "a used head carries no answer", chains: chainsOf(t, "[{meta."+tok+"}]"), owner: gr,
			values: values(gr, nil, nil, nil),
			want:   Annotation{Need: citationformat.NeedUsed}},
		{name: "a head no format reads is none", chains: nil, owner: gr, values: values(gr, nil, nil, nil)},
		{name: "a later option with no row is left out", chains: chainsOf(t, "{meta."+tok+"|meta.#"+uuid.NewString()+"}."), owner: gr,
			values: values(gr, nil, nil, nil),
			want:   Annotation{Need: citationformat.NeedNeeded}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ln := needsAt(tt.chains, tt.owner)
			if got := annotate(ln, head, tt.values, tt.values.Without(tt.owner), fields); !reflect.DeepEqual(got, tt.want) {
				t.Errorf("annotation\n got %+v\nwant %+v", got, tt.want)
			}
		})
	}

	t.Run("the Source date head", func(t *testing.T) {
		chains := chainsOf(t, "{source.date:year}.")
		ln := needsAt(chains, src)
		for name, date := range map[string]*citationformat.Value{"undated": nil, "dated": {Date: &dated}} {
			v := values(src, nil, nil, date)
			got := annotate(ln, citationformat.SourceDate, v, v.Without(src), fields)
			if got.Need != citationformat.NeedNeeded || got.MetElsewhere {
				t.Errorf("%s = %+v", name, got)
			}
		}
	})
}

func TestCitationValues(t *testing.T) {
	f := metadatafields.Field{UnknownText: "n.l."}
	got := CitationValue(Row{ValueText: "14", Mark: valuemark.Mark{Supplied: true}}, f)
	want := citationformat.Value{Text: "14", Mark: valuemark.Mark{Supplied: true}, UnknownText: "n.l."}
	if got != want {
		t.Errorf("CitationValue = %+v, want %+v", got, want)
	}
	y := 1890
	d := datevalue.Value{Kind: datevalue.KindPoint, StartYear: &y}
	date := sources.CitationDate(sources.Source{Date: &d, DateMark: valuemark.Mark{Supplied: true}})
	if date.Date != &d || date.Mark != (valuemark.Mark{Supplied: true}) || date.Text != "" {
		t.Errorf("CitationDate = %+v", date)
	}
	if got := sources.CitationDate(sources.Source{DateMark: valuemark.Mark{Unknown: true}}); got.Date != nil || !got.Mark.Unknown {
		t.Errorf("CitationDate of an unknown date = %+v", got)
	}
}

func TestCitationValuesNearest(t *testing.T) {
	a := uuid.New()
	gr, src := vocabkey.LevelGraph, vocabkey.LevelSource
	row := func(l vocabkey.Level, text string, mark valuemark.Mark) Row {
		return Row{FieldID: a[:], ValueText: text, Mark: mark, Owner: Owner{Level: l, ID: []byte(string(l))}}
	}
	at := func(rows ...Row) CitationValues {
		v := CitationValues{Rows: map[vocabkey.Level]map[string]Row{}}
		for _, r := range rows {
			if v.Rows[r.Owner.Level] == nil {
				v.Rows[r.Owner.Level] = map[string]Row{}
			}
			v.Rows[r.Owner.Level][string(a[:])] = r
		}
		return v
	}
	tests := []struct {
		name      string
		values    CitationValues
		wantLevel vocabkey.Level
		wantText  string
		wantOK    bool
	}{
		{"the graph's row over the Source's", at(row(gr, "14", valuemark.Mark{}), row(src, "9", valuemark.Mark{})), gr, "14", true},
		{"the Source's row alone", at(row(src, "9", valuemark.Mark{})), src, "9", true},
		{"no row at any level", at(), "", "", false},
		{"an unknown row with no text answers", at(row(gr, "", valuemark.Mark{Unknown: true}), row(src, "9", valuemark.Mark{})), gr, "", true},
		{"without the graph", at(row(gr, "14", valuemark.Mark{}), row(src, "9", valuemark.Mark{})).Without(gr), src, "9", true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, ok := tt.values.Nearest(a)
			if ok != tt.wantOK || got.Owner.Level != tt.wantLevel || got.ValueText != tt.wantText {
				t.Errorf("Nearest = %+v, %v; want level %q text %q ok %v", got, ok, tt.wantLevel, tt.wantText, tt.wantOK)
			}
		})
	}
}

func TestCitationValuesResolve(t *testing.T) {
	a := uuid.New()
	loaded := metadatafields.Field{ID: a[:], Key: "line_number", UnknownText: "n.l."}
	b := uuid.New()
	y := 1890
	dated := citationformat.Value{Date: &datevalue.Value{Kind: datevalue.KindPoint, StartYear: &y}}
	gr, art, src := vocabkey.LevelGraph, vocabkey.LevelArtifact, vocabkey.LevelSource
	rows := func(text string, mark valuemark.Mark) map[string]Row {
		return map[string]Row{string(a[:]): {FieldID: a[:], ValueText: text, Mark: mark}}
	}
	supplied := valuemark.Mark{Supplied: true}
	build := func(rows map[vocabkey.Level]map[string]Row) CitationValues {
		return CitationValues{
			Rows:     rows,
			Fields:   map[string]metadatafields.Field{string(a[:]): loaded},
			Builtins: map[citationformat.Target]citationformat.Value{citationformat.SourceDate: dated},
		}
	}
	tests := []struct {
		name   string
		values CitationValues
		target citationformat.Target
		want   citationformat.Value
	}{
		{"the graph's value over the Source's", build(map[vocabkey.Level]map[string]Row{gr: rows("14", supplied), src: rows("9", supplied)}),
			fieldTarget(a), citationformat.Value{Text: "14", Mark: supplied, UnknownText: "n.l."}},
		{"the Artifact's value over the Source's", build(map[vocabkey.Level]map[string]Row{art: rows("A", supplied), src: rows("S", supplied)}),
			fieldTarget(a), citationformat.Value{Text: "A", Mark: supplied, UnknownText: "n.l."}},
		{"the Source's value alone", build(map[vocabkey.Level]map[string]Row{src: rows("9", supplied)}),
			fieldTarget(a), citationformat.Value{Text: "9", Mark: supplied, UnknownText: "n.l."}},
		{"an unknown row at the graph stops the walk", build(map[vocabkey.Level]map[string]Row{gr: rows("", valuemark.Mark{Unknown: true}), src: rows("9", supplied)}),
			fieldTarget(a), citationformat.Value{Mark: valuemark.Mark{Unknown: true}, UnknownText: "n.l."}},
		{"a whitespace row at the graph stops the walk", build(map[vocabkey.Level]map[string]Row{gr: rows(" ", supplied), src: rows("9", supplied)}),
			fieldTarget(a), citationformat.Value{Text: " ", Mark: supplied, UnknownText: "n.l."}},
		{"a list target reads the Source alone", build(map[vocabkey.Level]map[string]Row{gr: rows("9", supplied)}),
			listTarget(a), citationformat.Value{}},
		{"a list target reads the Source's row", build(map[vocabkey.Level]map[string]Row{gr: rows("9", supplied), src: rows("S", supplied)}),
			listTarget(a), citationformat.Value{Text: "S", Mark: supplied, UnknownText: "n.l."}},
		{"a field with no row at any level", build(map[vocabkey.Level]map[string]Row{src: {string(b[:]): {FieldID: b[:], ValueText: "x"}}}),
			fieldTarget(a), citationformat.Value{}},
		{"a field whose row did not load answers with no unknown text", build(map[vocabkey.Level]map[string]Row{src: {string(b[:]): {FieldID: b[:], ValueText: "x"}}}),
			fieldTarget(b), citationformat.Value{Text: "x"}},
		{"a field named by key", build(map[vocabkey.Level]map[string]Row{src: rows("9", supplied)}),
			citationformat.Target{Field: citationformat.FieldRef{Key: "line_number"}}, citationformat.Value{}},
		{"a built-in that is set", build(nil), citationformat.SourceDate, dated},
		{"a built-in that is not", build(nil), citationformat.CitationImage, citationformat.Value{}},
		{"without the graph", build(map[vocabkey.Level]map[string]Row{gr: rows("14", supplied), src: rows("9", supplied)}).Without(gr),
			fieldTarget(a), citationformat.Value{Text: "9", Mark: supplied, UnknownText: "n.l."}},
		{"without the Source", build(map[vocabkey.Level]map[string]Row{src: rows("9", supplied)}).Without(src),
			fieldTarget(a), citationformat.Value{}},
		{"without the Source leaves no Source date", build(nil).Without(src), citationformat.SourceDate, citationformat.Value{}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := tt.values.Resolve(tt.target); got != tt.want {
				t.Errorf("Resolve = %+v, want %+v", got, tt.want)
			}
		})
	}
	t.Run("Without copies", func(t *testing.T) {
		v := build(map[vocabkey.Level]map[string]Row{src: rows("9", supplied)})
		_ = v.Without(src)
		if _, ok := v.Rows[src]; !ok || len(v.Builtins) != 1 {
			t.Errorf("Without changed its receiver: %+v", v)
		}
	})
}

func TestAppendOptions(t *testing.T) {
	a, b := uuid.New(), uuid.New()
	field := metadatafields.Field{ID: a[:], Key: "line_number"}
	fields := map[string]metadatafields.Field{string(a[:]): field}
	date := citationformat.Target{Level: vocabkey.LevelSource, Builtin: "date"}
	targets := []citationformat.Target{
		date,
		fieldTarget(a),
		fieldTarget(b),
		{Field: citationformat.FieldRef{Key: "line_number"}},
		citationformat.CitationImage,
	}
	seen := map[citationformat.Target]bool{citationformat.CitationImage: true}
	got := AppendOptions(nil, seen, targets, fields)
	want := []Alternative{
		{Level: vocabkey.LevelSource, Builtin: "date"},
		{Field: &field},
	}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("AppendOptions\n got %+v\nwant %+v", got, want)
	}
	if !seen[date] || !seen[fieldTarget(a)] {
		t.Errorf("seen = %v, want every target marked", seen)
	}
	if again := AppendOptions(nil, seen, targets, fields); len(again) != 0 {
		t.Errorf("second call = %+v, want none: every target was seen", again)
	}
}

// TestCitationPages reads a Citation's own Page and nothing above it: the text
// and mark as a citation prints them, never the graph's Page, and a researcher's
// own field of the key never outranks the seed's.
func TestCitationPages(t *testing.T) {
	setPage := func(t *testing.T, c *database.Catalog, userID []byte, o Owner, in Input) {
		t.Helper()
		if _, _, err := runSetOwner(c, userID, o, in); err != nil {
			t.Fatal(err)
		}
	}
	// world is a seeded catalog with one Source, a graph and a Citation.
	world := func(t *testing.T) (c *database.Catalog, userID []byte, page metadatafields.Field, cit, graph Owner) {
		t.Helper()
		c, userID = seededWorld(t)
		var err error
		page, err = metadatafields.Lookup(c, vocabkey.FieldPage, vocabkey.OriginProvenencia)
		if err != nil {
			t.Fatal(err)
		}
		src := newSource(t, c, userID, seededType(t, c, "newspaper_item").ID, "Gazette")
		cit = newLevelOwner(t, c, userID, src, vocabkey.LevelCitation)
		graph = newLevelOwner(t, c, userID, src, vocabkey.LevelGraph)
		return c, userID, page, cit, graph
	}
	pages := func(t *testing.T, c *database.Catalog, ids ...[]byte) map[string]string {
		t.Helper()
		db, err := c.DB()
		if err != nil {
			t.Fatal(err)
		}
		got, err := CitationPages(db, ids)
		if err != nil {
			t.Fatal(err)
		}
		return got
	}
	tests := []struct {
		name string
		run  func(t *testing.T, c *database.Catalog, userID []byte, page metadatafields.Field, cit, graph Owner) string
		want string
	}{
		{"own value", func(t *testing.T, c *database.Catalog, u []byte, page metadatafields.Field, cit, _ Owner) string {
			setPage(t, c, u, cit, Input{FieldID: page.ID, ValueText: "14"})
			return pages(t, c, cit.ID)[string(cit.ID)]
		}, "14"},
		{"unknown prints the field's unknown text", func(t *testing.T, c *database.Catalog, u []byte, page metadatafields.Field, cit, _ Owner) string {
			setPage(t, c, u, cit, Input{FieldID: page.ID, Mark: valuemark.Mark{Unknown: true}})
			return pages(t, c, cit.ID)[string(cit.ID)]
		}, "unpaginated"},
		{"supplied prints in brackets", func(t *testing.T, c *database.Catalog, u []byte, page metadatafields.Field, cit, _ Owner) string {
			setPage(t, c, u, cit, Input{FieldID: page.ID, ValueText: "14", Mark: valuemark.Mark{Supplied: true}})
			return pages(t, c, cit.ID)[string(cit.ID)]
		}, "[14]"},
		{"the graph's Page is not read", func(t *testing.T, c *database.Catalog, u []byte, page metadatafields.Field, cit, graph Owner) string {
			setPage(t, c, u, graph, Input{FieldID: page.ID, ValueText: "2"})
			return pages(t, c, cit.ID)[string(cit.ID)]
		}, ""},
		{"a researcher's field of the key never outranks the seed's", func(t *testing.T, c *database.Catalog, u []byte, page metadatafields.Field, cit, _ Owner) string {
			var mine metadatafields.Field
			_, err := writes.RunChanges(c, writes.Op{Action: "create_metadata_field", UserID: u},
				func(tx *database.Tx) ([]rowchange.Change, error) {
					var ch []rowchange.Change
					var err error
					mine, ch, err = metadatafields.Create(tx, "Page", metadatafields.DataTypeText, "")
					return ch, err
				})
			if err != nil {
				t.Fatal(err)
			}
			setPage(t, c, u, cit, Input{FieldID: mine.ID, ValueText: "99"})
			setPage(t, c, u, cit, Input{FieldID: page.ID, ValueText: "14"})
			return pages(t, c, cit.ID)[string(cit.ID)]
		}, "14"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c, userID, page, cit, graph := world(t)
			if got := tt.run(t, c, userID, page, cit, graph); got != tt.want {
				t.Errorf("page = %q, want %q", got, tt.want)
			}
		})
	}
	t.Run("no page field", func(t *testing.T) {
		c, userID := emptyWorld(t)
		typeID, err := sourcetypestest.Upsert(c, sourcetypes.Type{
			Key: "gazette", Origin: vocabkey.OriginProvenencia, Label: "Gazette", IconKey: "type_certificate",
		})
		if err != nil {
			t.Fatal(err)
		}
		src := newSource(t, c, userID, typeID, "Gazette")
		cit := newLevelOwner(t, c, userID, src, vocabkey.LevelCitation)
		if got := pages(t, c, cit.ID); len(got) != 0 {
			t.Errorf("pages = %v, want none", got)
		}
	})
}
