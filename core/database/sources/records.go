package sources

import (
	"database/sql"
	"errors"
	"reflect"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/effects"
	"github.com/Jake-Robins-Studios/provenencia/core/database/graphcache"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcecredibilitygrades"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sqlbatch"
	"github.com/Jake-Robins-Studios/provenencia/core/datevalue"
	"github.com/Jake-Robins-Studios/provenencia/core/valuemark"
)

// Record is a Source's words and its date, held once: every answer that names
// a Source composes them from here.
type Record struct {
	ID           []byte
	Ref          string
	Title        string
	SourceTypeID []byte
	// CredibilityKey is the key of the Source's credibility grade, "" with no
	// assessment. Credibility is that grade's order relative to the default.
	CredibilityKey string
	Credibility    int
	// ArtifactLabels maps each Artifact id to its label as stored. Never nil.
	// The held RecordIndex owns the map; readers treat it as read-only.
	ArtifactLabels map[string]string
	// Date is the Source's own date, nil when undated, when its row is gone or
	// when it is marked unknown (settleDate). Read-only, like ArtifactLabels.
	Date *datevalue.Value
}

// RecordIndex holds every Source's Record and finds the Source of an Artifact.
// It has no order; a reader treats it as read-only.
type RecordIndex struct {
	bySource         map[string]Record
	sourceOfArtifact map[string]string
}

// Source returns the Record of the Source with this id.
func (x *RecordIndex) Source(id []byte) (Record, bool) {
	r, ok := x.bySource[string(id)]
	return r, ok
}

// Artifact returns the Record of the Artifact's Source and the Artifact's label.
func (x *RecordIndex) Artifact(id []byte) (Record, string, bool) {
	sid, ok := x.sourceOfArtifact[string(id)]
	if !ok {
		return Record{}, "", false
	}
	r, ok := x.bySource[sid]
	if !ok {
		return Record{}, "", false
	}
	return r, r.ArtifactLabels[string(id)], true
}

var sqlRecordSources = `SELECT s.id, s.ref, s.title, s.source_type_id, s.date_value_id, COALESCE(sg.key, ''), ` +
	sourcecredibilitygrades.RelativeOrderColumn + `
		FROM sources s
		` + sourcecredibilitygrades.RelativeOrderJoins("s.id")

const sqlRecordArtifacts = `SELECT id, source_id, label FROM artifacts`

// Records is the Source records entry: one Record per Source, built on the
// first read of an open catalog and patched from the source_records read (effects.ReadSourceRecords).
// Apply patches the held index in place and reports that with Patched, not Set.
var Records graphcache.Whole[*RecordIndex]

func init() {
	Records = graphcache.RegisterWhole(graphcache.WholeEntry[*RecordIndex]{
		Name:     "sources.records",
		Lifetime: graphcache.LifeGraph,
		Build: func(g *graphcache.Graph) (*RecordIndex, error) {
			recs, err := loadRecords(g, nil)
			if err != nil {
				return nil, err
			}
			return newRecordIndex(recs), nil
		},
		Apply: func(g *graphcache.Graph, w graphcache.Whole[*RecordIndex], _ [][]byte, set effects.Set) error {
			ids := set.IDsOf(effects.ReadSourceRecords)
			if len(ids) == 0 {
				return nil
			}
			idx, ok, err := w.Get(g)
			if err != nil || !ok {
				return err
			}
			fresh, err := loadRecords(g, ids)
			if err != nil {
				return err
			}
			// Every named Source leaves before any returns, so an Artifact that
			// moved between two named Sources keeps its new mapping.
			for _, id := range ids {
				if old, ok := idx.bySource[string(id)]; ok {
					for aid := range old.ArtifactLabels {
						delete(idx.sourceOfArtifact, aid)
					}
					delete(idx.bySource, string(id))
				}
			}
			for _, id := range ids {
				if rec, ok := fresh[string(id)]; ok {
					idx.bySource[string(id)] = rec
					for aid := range rec.ArtifactLabels {
						idx.sourceOfArtifact[aid] = string(id)
					}
				}
			}
			w.Patched(g, nil)
			return nil
		},
		Check: func(g *graphcache.Graph, stored *RecordIndex) error {
			recs, err := loadRecords(g, nil)
			if err != nil {
				return err
			}
			want := newRecordIndex(recs)
			if !reflect.DeepEqual(stored.bySource, want.bySource) ||
				!reflect.DeepEqual(stored.sourceOfArtifact, want.sourceOfArtifact) {
				return errors.New("sources: the stored Source records do not match the sources table")
			}
			return nil
		},
	})
}

// RecordsOf returns the Source records of an open catalog's graph, building
// them on the first read; see database.ReadWhole for a write's or a nil graph.
func RecordsOf(g *graphcache.Graph) (*RecordIndex, error) {
	return database.ReadWhole(Records, g)
}

func newRecordIndex(recs map[string]Record) *RecordIndex {
	x := &RecordIndex{bySource: recs, sourceOfArtifact: map[string]string{}}
	for sid, r := range recs {
		for aid := range r.ArtifactLabels {
			x.sourceOfArtifact[aid] = sid
		}
	}
	return x
}

// loadRecords reads the Records of the Sources with these ids, or of every
// Source when ids is nil. A Source with no row is absent from the result.
func loadRecords(q database.Querier, ids [][]byte) (map[string]Record, error) {
	out := map[string]Record{}
	dateIDs := map[string][]byte{}
	scanSource := func(rows *sql.Rows) error {
		var r Record
		var dateID []byte
		if err := rows.Scan(&r.ID, &r.Ref, &r.Title, &r.SourceTypeID, &dateID, &r.CredibilityKey, &r.Credibility); err != nil {
			return err
		}
		r.ArtifactLabels = map[string]string{}
		out[string(r.ID)] = r
		dateIDs[string(r.ID)] = dateID
		return nil
	}
	scanArtifact := func(rows *sql.Rows) error {
		var aid, sid []byte
		var label string
		if err := rows.Scan(&aid, &sid, &label); err != nil {
			return err
		}
		if r, ok := out[string(sid)]; ok {
			r.ArtifactLabels[string(aid)] = label
		}
		return nil
	}
	if ids == nil {
		if err := sqlbatch.Scan(q, sqlRecordSources, nil, scanSource); err != nil {
			return nil, err
		}
		if err := sqlbatch.Scan(q, sqlRecordArtifacts, nil, scanArtifact); err != nil {
			return nil, err
		}
		return out, fillRecordDates(q, out, dateIDs)
	}
	if err := sqlbatch.Query(q, sqlRecordSources+` WHERE s.id IN (`, `)`, nil, ids, scanSource); err != nil {
		return nil, err
	}
	if err := sqlbatch.Query(q, sqlRecordArtifacts+` WHERE source_id IN (`, `)`, nil, ids, scanArtifact); err != nil {
		return nil, err
	}
	return out, fillRecordDates(q, out, dateIDs)
}

// fillRecordDates sets Date on each record from one batched read of the date
// rows its Source holds, through settleDate; the mark is not kept.
func fillRecordDates(q database.Querier, out map[string]Record, dateIDs map[string][]byte) error {
	ids := make([][]byte, 0, len(dateIDs))
	for _, id := range dateIDs {
		ids = append(ids, id)
	}
	dates, err := lookupDates(q, ids)
	if err != nil {
		return err
	}
	for sid, r := range out {
		r.Date, _ = settleDate(dates, dateIDs[sid], valuemark.Mark{})
		out[sid] = r
	}
	return nil
}
