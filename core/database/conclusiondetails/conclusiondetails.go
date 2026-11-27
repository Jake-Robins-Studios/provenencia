// Package conclusiondetails composes the detail of one canonical handle from
// the catalog graph. For every Property its members' records speak to, it
// returns the state, every auto-reconciled value (displayed or not, with its
// reason), and the auto-reconciler's outcome for each Observation it
// considered, joined to the record's Source: the records a detail page's provenance sheet shows.
//
// Field values are the node's auto-reconciler ranks, and the sheet's reconciler
// half (reason, value rank, denied by, vote) is the node's outcome rows. Term
// labels come from the graph vocabulary. A record is three cached pieces
// composed with no SQL: the node's outcome row, the Observation and its
// Subject from the graph's records (graphfill.RecordsOf, which carry the
// Observation's Citation words), and the Source record (sources.RecordsOf). A
// Property no record mentions isn't returned. Pictures are listed apart from the
// fields, earliest first (gallery.Of over the node). Which empty fields a page
// still shows is the page's choice. Go returns structures; the app formats text.
// Reconciliation Claims are never in these tables: when they ship, a
// composer lays an accepted claim over the auto-reconciled value here.
// A Person's life rows read other handles' fields through PersonDerivedRows,
// composed by the same steps. A place row reads the event–place link's place
// end, each record as its Place's toponym. Each read records what it was built
// from in the caller's graphcache.PageInputs.
package conclusiondetails

import (
	"bytes"
	"fmt"
	"slices"
	"sort"

	"github.com/Jake-Robins-Studios/provenencia/core/apperr"
	"github.com/Jake-Robins-Studios/provenencia/core/autoreconcile"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/canonicalentities"
	"github.com/Jake-Robins-Studios/provenencia/core/database/conclusionsummaries"
	"github.com/Jake-Robins-Studios/provenencia/core/database/gallery"
	"github.com/Jake-Robins-Studios/provenencia/core/database/graphcache"
	"github.com/Jake-Robins-Studios/provenencia/core/database/graphfill"
	"github.com/Jake-Robins-Studios/provenencia/core/database/observations"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sources"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue"
	"github.com/Jake-Robins-Studios/provenencia/core/namevalue"
	"github.com/Jake-Robins-Studios/provenencia/core/propertymeta"
	"github.com/Jake-Robins-Studios/provenencia/core/valuecodec"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

// ErrNotFound is returned for an unknown or merged handle.
var ErrNotFound = apperr.New(apperr.CodeConclusionDetailsNotFound, apperr.KindUser)

// Value is one Property value. Exactly the field for the value type is set.
type Value struct {
	propertymeta.Scalar
	TermID    []byte
	TermKey   string
	TermLabel string
	// TermOrigin is the term's origin: its key is the product's only when this is vocabkey.OriginProvenencia.
	TermOrigin string
	Date       *datevalue.Value
	Name       *namevalue.Value
}

// ReconciledValue is one auto-reconciled value of a Property.
type ReconciledValue struct {
	Rank    int // 1 = first displayed
	Value   Value
	Support int    // distinct Sources
	Against int    // negative records that match it
	Reason  string // "kept" when displayed, else why not
}

// Displayed reports whether the value is one of the displayed values.
func (v ReconciledValue) Displayed() bool { return v.Reason == string(autoreconcile.ReasonKept) }

// Outcome is what the auto-reconciler did with one Observation, with the
// evidence it weighed.
type Outcome struct {
	ObservationID  []byte
	ObservationRef string
	Reason         string
	ValueRank      int                // the value it went into; 0 for none
	GroupRank      int                // the displayed value it counts under; 0 for none
	DeniedBy       []byte             // the negative Observation, for "denied"
	Vote           autoreconcile.Vote // the majority that beat it, for "outvoted"
	Recorded       Value              // what the record said
	SubjectID      []byte
	SubjectRef     string
	GraphID        []byte // the Evidence graph of the Observation's Subject
	CitationID     []byte
	ArtifactID     []byte
	SourceID       []byte
	SourceTitle    string
	ArtifactLabel  string // "" = none
	CitationLabel  string // "" = none
	ArtifactPage   int    // the Citation locator's page; 0 = none
	PageLabel      string // its printed label; "" = none
	CredibilityKey string // "" = no assessment (standard)
	// Provenance is the evidence as the auto-reconciler weighed it, relative
	// to the default grades; Provenance.Weak says whether it is weak, and
	// each part says why.
	Provenance autoreconcile.Provenance
}

// Field is one Property of the handle.
type Field struct {
	PropertyID  []byte
	PropertyKey string
	Label       string
	ValueType   string
	State       autoreconcile.State // read off the displayed values
	cardinality string
	Values      []ReconciledValue // rank order; a multiple date field's in date order (autoreconcile.SortKey), ties by rank
	Outcomes    []Outcome         // by group rank (none last), value rank (none last), then Observation id
}

// PictureTile is one picture a gallery shows: its image, and the outcome of
// its earliest gallery record, which the tile opens.
type PictureTile struct {
	ImageFileID []byte
	Record      Outcome
	Preferred   bool // the handle's chosen portrait or thumbnail (S10-39)
	Leads       bool // the picture the header leads with (gallery.Picture.Leads)
}

// Detail is one handle's detail.
type Detail struct {
	Entity      canonicalentities.Entity
	MemberCount int // accepted members
	Fields      []Field
	Pictures    []PictureTile // earliest recorded first
}

// Handle returns the graph node of one unmerged handle. A nil catalog or
// graph, a malformed id, and an unknown or merged handle are ErrNotFound. It
// records the handle on in.
func Handle(c *database.Catalog, entityID []byte, in *graphcache.PageInputs) (*graphcache.Node, error) {
	if c == nil || c.Graph() == nil || len(entityID) != 16 {
		return nil, ErrNotFound
	}
	n, err := in.Node(entityID)
	if err != nil {
		return nil, err
	}
	if n == nil || n.Merged {
		return nil, ErrNotFound
	}
	return n, nil
}

// ForEntity composes the detail of one unmerged handle.
func ForEntity(c *database.Catalog, entityID []byte, in *graphcache.PageInputs) (Detail, error) {
	n, err := Handle(c, entityID, in)
	if err != nil {
		return Detail{}, err
	}
	d := Detail{Entity: canonicalentities.FromNode(n), MemberCount: len(n.AcceptedMembers())}
	vocab, err := c.Graph().Vocabulary()
	if err != nil {
		return Detail{}, err
	}
	galleryProps := gallery.PropertyIDs(vocab)
	tiles := gallery.Of(n, galleryProps)
	leads := map[string]bool{}
	for _, l := range tiles {
		leads[string(l.ObservationIDs[0])] = true
	}
	var leadRows []graphcache.Outcome
	for _, prop := range galleryProps {
		for _, row := range n.Outcomes[string(prop)] {
			if leads[string(row.ObservationID)] {
				leadRows = append(leadRows, row)
			}
		}
	}
	fields, leadOutcomes, err := fieldsOf(c.Graph(), vocab, []*graphcache.Node{n}, leadRows, nil, in)
	if err != nil {
		return Detail{}, err
	}
	d.Fields = fields[string(entityID)]
	for _, l := range tiles {
		if o, ok := leadOutcomes[string(l.ObservationIDs[0])]; ok {
			d.Pictures = append(d.Pictures, PictureTile{ImageFileID: l.ImageFileID, Record: o, Preferred: l.Preferred, Leads: l.Leads})
		}
	}
	return d, nil
}

// fieldsOf composes the fields of several handles at once, keyed by entity
// id: the one composition every page's fields come from. A nil or merged
// node, or a repeated id, is skipped. It also returns the outcomes of the
// Observations of leadRows (a gallery's earliest records, the node's own
// outcome rows), which belong to no field. only nil composes each node's
// page fields: every Property but depiction and subject-valued ones. Non-nil,
// it names the Properties to compose (any value type but depiction) under
// each node's id; a node it does not name has no field. The graphs and Sources
// of the records it composes are recorded on in.
func fieldsOf(g *graphcache.Graph, v graphcache.Vocabulary, nodes []*graphcache.Node, leadRows []graphcache.Outcome, only map[string]map[string]bool, in *graphcache.PageInputs) (map[string][]Field, map[string]Outcome, error) {
	var use []*graphcache.Node
	seen := map[string]bool{}
	for _, n := range nodes {
		if n == nil || n.Merged || seen[string(n.ID)] {
			continue
		}
		seen[string(n.ID)] = true
		use = append(use, n)
	}
	out := map[string][]Field{}
	if len(use) == 0 {
		return out, map[string]Outcome{}, nil
	}
	ordered, byProp, err := loadProperties(g, use, only)
	if err != nil {
		return nil, nil, err
	}
	for _, n := range use {
		if err := attachValues(g, n, byProp[string(n.ID)]); err != nil {
			return nil, nil, err
		}
	}
	// The rows to compose: each field's outcome rows, then the leads (no field).
	type want struct {
		f   *Field // nil for a lead
		row graphcache.Outcome
	}
	var wanted []want
	var rows []graphcache.Outcome
	for _, n := range use {
		for prop, f := range byProp[string(n.ID)] {
			for _, row := range n.Outcomes[prop] {
				wanted = append(wanted, want{f, row})
				rows = append(rows, row)
			}
		}
	}
	for _, row := range leadRows {
		wanted = append(wanted, want{nil, row})
		rows = append(rows, row)
	}
	reader, err := newRecordReader(g, v, use, rows, in)
	if err != nil {
		return nil, nil, err
	}
	// A lead's Recorded value has no Date or Name: a depiction Observation has none.
	leadOutcomes := map[string]Outcome{}
	for _, w := range wanted {
		o, ok, err := reader.outcome(w.row)
		if err != nil {
			return nil, nil, err
		}
		switch {
		case !ok: // a row the records cannot place is dropped
		case w.f == nil:
			leadOutcomes[string(o.ObservationID)] = o
		default:
			w.f.Outcomes = append(w.f.Outcomes, o)
		}
	}
	for id, fs := range ordered {
		for _, f := range fs {
			finish(f)
			out[id] = append(out[id], *f)
		}
	}
	return out, leadOutcomes, nil
}

// finish reads a field's state off its values and orders its outcomes.
func finish(f *Field) {
	orderDates(f)
	f.State = state(f.Values, f.cardinality)
	displayed := map[int]bool{}
	for _, v := range f.Values {
		if v.Displayed() {
			displayed[v.Rank] = true
		}
	}
	for i := range f.Outcomes {
		o := &f.Outcomes[i]
		o.GroupRank = 0
		counts := autoreconcile.Reason(o.Reason).IntoValue()
		if counts && displayed[o.ValueRank] {
			o.GroupRank = o.ValueRank
		}
	}
	// A value's place in Values: its rank, unless orderDates moved it.
	place := make(map[int]int, len(f.Values))
	for i, v := range f.Values {
		place[v.Rank] = i + 1
	}
	at := func(rank int) int {
		if p, ok := place[rank]; ok {
			return p
		}
		return rank
	}
	less := func(a, b int) (decided, before bool) {
		if (a == 0) != (b == 0) {
			return true, b == 0
		}
		if a != b {
			return true, a < b
		}
		return false, false
	}
	sort.SliceStable(f.Outcomes, func(i, j int) bool {
		if d, b := less(at(f.Outcomes[i].GroupRank), at(f.Outcomes[j].GroupRank)); d {
			return b
		}
		if d, b := less(at(f.Outcomes[i].ValueRank), at(f.Outcomes[j].ValueRank)); d {
			return b
		}
		return string(f.Outcomes[i].ObservationID) < string(f.Outcomes[j].ObservationID)
	})
}

// orderDates puts a multiple date field's values in date order
// (autoreconcile.SortKey, a value with no key last, ties by rank). Rank on each
// value is unchanged: the wire matches records to values by it.
func orderDates(f *Field) {
	if f.cardinality != propertymeta.CardinalityMultiple || f.ValueType != propertymeta.ValueTypeDate {
		return
	}
	type keyed struct {
		v   ReconciledValue
		key string
		ok  bool
	}
	ks := make([]keyed, len(f.Values))
	for i, v := range f.Values {
		k, ok := autoreconcile.SortKey(f.ValueType, autoreconcile.Value{Date: v.Value.Date})
		ks[i] = keyed{v, k, ok}
	}
	sort.SliceStable(ks, func(i, j int) bool {
		a, b := ks[i], ks[j]
		if a.ok != b.ok {
			return a.ok
		}
		if a.ok && a.key != b.key {
			return a.key < b.key
		}
		return a.v.Rank < b.v.Rank
	})
	for i := range ks {
		f.Values[i] = ks[i].v
	}
}

// state reads a field's state off its displayed values, by the same rule as
// autoreconcile.Result.State. Several displayed values on a multiple Property
// are all true, so the state is multiple rather than mixed.
func state(values []ReconciledValue, cardinality string) autoreconcile.State {
	var shown []ReconciledValue
	for _, v := range values {
		if v.Displayed() {
			shown = append(shown, v)
		}
	}
	switch {
	case len(shown) == 0:
		return autoreconcile.StateEmpty
	case len(shown) > 1:
		if cardinality == propertymeta.CardinalityMultiple {
			return autoreconcile.StateMultiple
		}
		return autoreconcile.StateMixed
	case shown[0].Support > 1:
		return autoreconcile.StateMerged
	default:
		return autoreconcile.StateSingle
	}
}

// loadProperties lists each node's fields in its kind's binding order, and
// the same fields by entity id then property id. A node's fields are the
// Properties its outcome rows name, narrowed by only (see fieldsOf).
func loadProperties(g *graphcache.Graph, nodes []*graphcache.Node, only map[string]map[string]bool) (map[string][]*Field, map[string]map[string]*Field, error) {
	v, err := g.Vocabulary()
	if err != nil {
		return nil, nil, err
	}
	props := v.PropertiesByID()
	ordered := map[string][]*Field{}
	byProp := map[string]map[string]*Field{}
	for _, n := range nodes {
		ids := make([]string, 0, len(n.Outcomes))
		for id := range n.Outcomes {
			if only != nil && !only[string(n.ID)][id] {
				continue
			}
			ids = append(ids, id)
		}
		// Ties in the type order keep a fixed order: the Properties' id bytes.
		sort.Strings(ids)
		var got []*Field
		for _, id := range ids {
			p, ok := props[id]
			if !ok || p.ValueType == propertymeta.ValueTypeDepiction || (only == nil && p.ValueType == propertymeta.ValueTypeSubject) {
				continue
			}
			got = append(got, &Field{
				PropertyID: append([]byte(nil), p.ID...), PropertyKey: p.Key, Label: p.Label,
				ValueType: p.ValueType, cardinality: p.Cardinality,
			})
		}
		if len(got) == 0 {
			continue
		}
		order := v.TypeOrder(n.SubjectTypeID)
		sort.SliceStable(got, func(i, j int) bool {
			return vocabkey.CompareByOrder(order, vocabkey.PropertyKey(got[i].PropertyKey), vocabkey.PropertyKey(got[j].PropertyKey)) < 0
		})
		ordered[string(n.ID)] = got
		byProp[string(n.ID)] = map[string]*Field{}
		for _, f := range got {
			byProp[string(n.ID)][string(f.PropertyID)] = f
		}
	}
	return ordered, byProp, nil
}

func attachValues(g *graphcache.Graph, n *graphcache.Node, byProp map[string]*Field) error {
	vocab, err := g.Vocabulary()
	if err != nil {
		return err
	}
	terms := vocab.TermsByID()
	for prop, ranks := range n.Values {
		f, ok := byProp[prop]
		if !ok {
			continue // a depiction Property, or one the outcomes no longer name
		}
		for _, rank := range ranks {
			value, err := valueOf(rank.Scalar, rank.TermID, nil, rank.Date, nil, rank.Name, terms)
			if err != nil {
				return err
			}
			v := ReconciledValue{
				Rank: rank.Rank, Reason: rank.Reason,
				Support: rank.Support, Against: rank.Against, Value: value,
			}
			f.Values = append(f.Values, v)
		}
	}
	return nil
}

// valueOf decodes a recorded or ranked value: the scalar, the term with its
// label from terms, and the stored date and name blobs, whose ids are the rows'
// (nil for a node's value, which has no row id).
func valueOf(s propertymeta.Scalar, termID, dateID, date, nameID, name []byte, terms map[string]graphcache.VocabTerm) (Value, error) {
	v := Value{Scalar: s, TermID: append([]byte(nil), termID...)}
	if t, ok := terms[string(termID)]; ok {
		v.TermKey, v.TermLabel, v.TermOrigin = t.Key, t.Label, t.Origin
	}
	if len(date) > 0 {
		d, err := valuecodec.UnmarshalDate(date)
		if err != nil {
			return Value{}, err
		}
		d.ID = append([]byte(nil), dateID...)
		v.Date = &d
	}
	if len(name) > 0 {
		n, err := valuecodec.UnmarshalName(name)
		if err != nil {
			return Value{}, err
		}
		n.ID = append([]byte(nil), nameID...)
		v.Name = &n
	}
	return v, nil
}

// recordReader composes an Outcome from the node's outcome row, the graph's
// Subject record and the Source record.
type recordReader struct {
	recs    *sources.RecordIndex
	graphs  map[string]*graphfill.GraphRecords // by graph id
	graphOf map[string][]byte                  // Subject id -> graph id
	// credibility is the Source's grade of each member Subject, as the node
	// carries it (graphcache.Member.Credibility).
	credibility map[string]int
	terms       map[string]graphcache.VocabTerm
	toponym     []byte
	toponyms    map[string]string // value Subject id -> first toponym
	in          *graphcache.PageInputs
}

// newRecordReader holds the records of every graph the rows' Subjects are on,
// found among the members of nodes: one fill, and the Source records. The
// graphs are recorded on in as they are asked for, and each Source an outcome
// composes as it is read.
func newRecordReader(g *graphcache.Graph, v graphcache.Vocabulary, nodes []*graphcache.Node, rows []graphcache.Outcome, in *graphcache.PageInputs) (*recordReader, error) {
	r := &recordReader{
		graphOf:     map[string][]byte{},
		credibility: map[string]int{},
		terms:       v.TermsByID(),
		toponym:     v.PropertyID(vocabkey.PropertyToponym, vocabkey.OriginProvenencia),
		toponyms:    map[string]string{},
		in:          in,
	}
	for _, n := range nodes {
		for _, m := range n.Members {
			r.graphOf[string(m.SubjectID)] = m.GraphID
			r.credibility[string(m.SubjectID)] = m.Credibility
		}
	}
	var graphIDs [][]byte
	for _, row := range rows {
		if len(row.SubjectID) == 0 {
			continue
		}
		if graph, ok := r.graphOf[string(row.SubjectID)]; ok {
			graphIDs = append(graphIDs, graph)
		}
	}
	var err error
	if r.graphs, err = graphfill.RecordsOf(g, database.UniqueBlobIDs(graphIDs), in); err != nil {
		return nil, err
	}
	if r.recs, err = sources.RecordsOf(g); err != nil {
		return nil, err
	}
	return r, nil
}

// outcome composes the outcome of one row, and false when the records cannot
// place it (no Subject, a Subject on no member's graph, an Observation not on
// the graph).
func (r *recordReader) outcome(row graphcache.Outcome) (Outcome, bool, error) {
	if len(row.SubjectID) == 0 {
		return Outcome{}, false, nil
	}
	graph, ok := r.graphOf[string(row.SubjectID)]
	if !ok {
		return Outcome{}, false, nil
	}
	records := r.graphs[string(graph)]
	subject, obs, ok := records.Observation(row.ObservationID)
	if !ok {
		return Outcome{}, false, nil
	}
	src, label, found := r.recs.Artifact(obs.ArtifactID)
	if !found {
		return Outcome{}, false, fmt.Errorf("conclusiondetails: Artifact %x has no Source record", obs.ArtifactID)
	}
	r.in.AddSources(src.ID)
	recorded, err := valueOf(obs.Scalar, obs.TermID, obs.DateID, obs.Date, obs.NameID, obs.Name, r.terms)
	if err != nil {
		return Outcome{}, false, err
	}
	if len(obs.ValueSubjectID) > 0 {
		// A record on an event–place link's place end holds a Place: it reads
		// as that Place's first toponym (D-21).
		text, done := r.toponyms[string(obs.ValueSubjectID)]
		if !done {
			if place, ok := records.Subject(obs.ValueSubjectID); ok {
				text = observations.FirstTextOf(place.Observations, r.toponym)
			}
			r.toponyms[string(obs.ValueSubjectID)] = text
		}
		recorded.Text, recorded.HasText = text, text != ""
	}
	return Outcome{
		ObservationID:  append([]byte(nil), row.ObservationID...),
		ObservationRef: obs.Ref,
		Reason:         row.Reason,
		ValueRank:      row.ValueRank,
		DeniedBy:       row.DeniedBy, // the node's rows are cloned at load
		Vote:           autoreconcile.Vote{Support: row.VoteSupport, Of: row.VoteOf},
		Recorded:       recorded,
		SubjectID:      subject.Subject.ID,
		SubjectRef:     subject.Subject.Ref,
		GraphID:        records.GraphID,
		CitationID:     obs.CitationID,
		ArtifactID:     obs.ArtifactID,
		SourceID:       src.ID,
		SourceTitle:    src.Title,
		ArtifactLabel:  label,
		CitationLabel:  obs.CitationLabel,
		ArtifactPage:   obs.ArtifactPage,
		PageLabel:      obs.PageLabel,
		CredibilityKey: src.CredibilityKey,
		Provenance:     autoreconcile.Provenance{Credibility: r.credibility[string(row.SubjectID)], Uncertain: row.Uncertain},
	}, true, nil
}

// DerivedRowKind names a Person life row.
type DerivedRowKind string

const (
	DerivedRowBirthDate  DerivedRowKind = "birth_date"
	DerivedRowBirthPlace DerivedRowKind = "birth_place"
	DerivedRowDeathDate  DerivedRowKind = "death_date"
	DerivedRowDeathPlace DerivedRowKind = "death_place"
)

// OwnerField is the field a derived row reads off the entity that owns it.
// Event is the owner's summary when the owner is an Event. Place is the Place
// a place row's owner (an event–place link's association) holds on its place
// end, with its own toponyms; nil for every other owner.
type OwnerField struct {
	Entity canonicalentities.Entity
	Event  *conclusionsummaries.EventSummary
	Place  *conclusionsummaries.ChainedPlace
	Field  Field
}

// DerivedRow is one life row's records: one entry per owner, in the order
// the row lists them (the lead event first; place links in the summary's order).
type DerivedRow struct {
	Kind   DerivedRowKind
	Owners []OwnerField
}

// PersonDerivedRows returns the records behind a Person's birth date, birth
// place, death date and death place rows, in that order. The owners come from
// the Person's summary row. A row with no owners is not returned. An owner
// merged or gone, or without the field the row reads, is dropped. It records
// on in each owner it reads and the place a place owner holds.
func PersonDerivedRows(c *database.Catalog, personID []byte, in *graphcache.PageInputs) ([]DerivedRow, error) {
	if c == nil || c.Graph() == nil || len(personID) != 16 {
		return nil, nil
	}
	people, err := conclusionsummaries.PersonsByIDs(c, [][]byte{personID})
	if err != nil {
		return nil, err
	}
	if len(people) == 0 {
		return nil, nil
	}
	birth, death := people[0].Birth.Owners, people[0].Death.Owners
	lists := []struct {
		kind   DerivedRowKind
		owners []conclusionsummaries.FieldOwner
		events bool // the owners are Events, so each carries its summary
	}{
		{DerivedRowBirthDate, birth.Dates, true}, {DerivedRowBirthPlace, birth.Places, false},
		{DerivedRowDeathDate, death.Dates, true}, {DerivedRowDeathPlace, death.Places, false},
	}
	var all, eventIDs [][]byte
	for _, l := range lists {
		for _, o := range l.owners {
			all = append(all, o.ID)
			if o.Place != nil {
				in.AddHandles(o.Place.Entity.ID)
			}
			if l.events {
				eventIDs = append(eventIDs, o.ID)
			}
		}
	}
	ids := database.UniqueBlobIDs(all)
	if len(ids) == 0 {
		return nil, nil
	}
	g := c.Graph()
	if err := g.Nodes(ids); err != nil {
		return nil, err
	}
	nodes := make([]*graphcache.Node, 0, len(ids))
	nodeOf := map[string]*graphcache.Node{}
	for _, id := range ids {
		n, err := in.Node(id)
		if err != nil {
			return nil, err
		}
		nodes = append(nodes, n)
		nodeOf[string(id)] = n
	}
	v, err := g.Vocabulary()
	if err != nil {
		return nil, err
	}
	only := map[string]map[string]bool{}
	for _, l := range lists {
		for _, o := range l.owners {
			if only[string(o.ID)] == nil {
				only[string(o.ID)] = map[string]bool{}
			}
			only[string(o.ID)][string(o.PropertyID)] = true
		}
	}
	fields, _, err := fieldsOf(g, v, nodes, nil, only, in)
	if err != nil {
		return nil, err
	}
	summaries, err := conclusionsummaries.EventsByIDs(c, database.UniqueBlobIDs(eventIDs))
	if err != nil {
		return nil, err
	}
	eventOf := map[string]*conclusionsummaries.EventSummary{}
	for i := range summaries {
		eventOf[string(summaries[i].Entity.ID)] = &summaries[i]
	}
	var out []DerivedRow
	for _, l := range lists {
		row := DerivedRow{Kind: l.kind}
		for _, o := range l.owners {
			node := nodeOf[string(o.ID)]
			for _, f := range fields[string(o.ID)] {
				if !bytes.Equal(f.PropertyID, o.PropertyID) {
					continue
				}
				owner := OwnerField{Entity: canonicalentities.FromNode(node), Place: copyPlace(o.Place), Field: f}
				ownerVerdict(o, &owner.Field)
				if l.events {
					owner.Event = eventOf[string(o.ID)]
				}
				row.Owners = append(row.Owners, owner)
				break
			}
		}
		if len(row.Owners) > 0 {
			out = append(out, row)
		}
	}
	return out, nil
}

// ownerVerdict lays what a vote did to an owner over its field: with the
// owner's Reason set, every outcome that was kept or folded in the field takes
// the owner's Reason and Vote, and a folded one reads as plain "folded" (its
// value rank is 0, so no value is named). With Reason empty it changes nothing.
// The field's outcomes are copied first, so nothing shared is written.
func ownerVerdict(owner conclusionsummaries.FieldOwner, f *Field) {
	if owner.Reason == "" {
		return
	}
	f.Outcomes = slices.Clone(f.Outcomes)
	for i := range f.Outcomes {
		o := &f.Outcomes[i]
		if o.Reason != string(autoreconcile.ReasonKept) && o.Reason != string(autoreconcile.ReasonFolded) {
			continue
		}
		o.Reason, o.Vote = string(owner.Reason), owner.Vote
		if owner.Reason == autoreconcile.ReasonFolded {
			o.ValueRank = 0
		}
	}
}

// copyPlace is a copy of p that shares no slice with it, so nothing outside the
// summary row points into the row. A place owner holds an entity and its names,
// never parents, so Parents is not cloned.
func copyPlace(p *conclusionsummaries.ChainedPlace) *conclusionsummaries.ChainedPlace {
	if p == nil {
		return nil
	}
	out := *p
	out.Names = slices.Clone(p.Names)
	return &out
}
