// Package citationrender renders Citations and Sources through their Source
// type's citation formats, on demand from SQL: a batch of Citations (full and
// short citation, group key, and the inputs the read used) and one form against
// one target with an optional unsaved format. It runs no SQL of its own: it
// reads through the owning packages and answers through
// sourcemetadata.CitationValues, the resolver the metadata boards use too.
package citationrender

import (
	"crypto/sha256"
	"database/sql"
	"encoding/binary"
	"encoding/hex"

	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/citations"
	"github.com/Jake-Robins-Studios/provenencia/core/database/graphcache"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
)

const (
	// MaxCitations is the most ids one Render call takes.
	MaxCitations = 2_000
	// MaxBatchBytes is the most text one Render call renders: the sum of the
	// plain text of every full and short citation.
	MaxBatchBytes = 8 << 20
)

// RenderedCitation is one Citation rendered. A Full with no runs means the
// Citation's type has no full format (or it did not parse, or a row it reads is
// missing): the caller shows its own line. Short is empty the same way.
type RenderedCitation struct {
	CitationID []byte
	Full       citationformat.Rendered
	Short      citationformat.Rendered
	// GroupKey is equal for Citations whose full citations render the same.
	GroupKey string
}

// Render renders the Citations with the given ids in one read transaction, in
// input order, a repeated id once; an id with no Citation is left out. It
// records in in the Evidence graphs and Sources of the Citations it found; in
// must not be nil. More than MaxCitations ids, an id that is not 16 bytes, or
// more than MaxBatchBytes of rendered text is citations.ErrInvalid. No ids
// returns nil and reads nothing.
func Render(c *database.Catalog, citationIDs [][]byte, in *graphcache.PageInputs) ([]RenderedCitation, error) {
	if len(citationIDs) > MaxCitations {
		return nil, citations.ErrInvalid
	}
	for _, id := range citationIDs {
		if len(id) != 16 {
			return nil, citations.ErrInvalid
		}
	}
	if len(citationIDs) == 0 {
		return nil, nil
	}
	db, err := c.DB()
	if err != nil {
		return nil, err
	}
	tx, err := db.Begin()
	if err != nil {
		return nil, err
	}
	defer func() { _ = tx.Rollback() }()
	return render(tx, citationIDs, in)
}

// templates are a type's parsed full and short formats; either may be nil.
type templates struct{ full, short *citationformat.Template }

func render(tx *sql.Tx, citationIDs [][]byte, in *graphcache.PageInputs) ([]RenderedCitation, error) {
	subs, err := loadCitations(tx, citationIDs)
	if err != nil {
		return nil, err
	}
	for _, s := range subs {
		in.AddEvidenceGraphs(s.cited.GraphID)
		if s.cited.SourceID != nil {
			in.AddSources(s.cited.SourceID)
		}
	}

	var typeIDs [][]byte
	for _, s := range subs {
		if id := s.typeID(); id != nil {
			typeIDs = append(typeIDs, id)
		}
	}
	stored, err := sourcetypes.StoredFormatsTx(tx, typeIDs)
	if err != nil {
		return nil, err
	}
	byType := make(map[string]templates, len(stored))
	var all []*citationformat.Template
	for id, formats := range stored {
		parsed, _ := formats.Parse()
		t := templates{full: parsed[citationformat.FormFull], short: parsed[citationformat.FormShort]}
		byType[id] = t
		all = append(all, t.full, t.short)
	}
	if err := fillValues(tx, subs, all); err != nil {
		return nil, err
	}

	out := make([]RenderedCitation, 0, len(subs))
	total := 0
	for _, s := range subs {
		r := RenderedCitation{CitationID: s.cited.ID}
		if t, ok := byType[string(s.typeID())]; ok {
			if t.full != nil {
				r.Full = citationformat.Render(t.full, s.values)
			}
			if t.short != nil {
				r.Short = citationformat.Render(t.short, s.values)
			}
		}
		r.GroupKey = groupKey(s.cited.ID, r.Full)
		total += size(r.Full) + size(r.Short)
		if total > MaxBatchBytes {
			return nil, citations.ErrInvalid
		}
		out = append(out, r)
	}
	return out, nil
}

// size is the bytes of text in r.
func size(r citationformat.Rendered) int {
	n := 0
	for _, run := range r.Runs {
		n += len(run.Text)
	}
	return n
}

// groupKey is equal for Citations whose full citations render the same. A
// Citation with a full citation gets "full:" and the hex SHA-256 over each run
// in order: one byte for its style (1 italic, 0 plain), the text's length as an
// unsigned varint, then the text, so no text can fake a run boundary. A
// Citation with none gets "citation:" and its id, so each stands alone.
func groupKey(id []byte, full citationformat.Rendered) string {
	if len(full.Runs) == 0 {
		return "citation:" + database.UUIDString(id)
	}
	h := sha256.New()
	var buf []byte
	for _, run := range full.Runs {
		style := byte(0)
		if run.Italic {
			style = 1
		}
		buf = append(buf[:0], style)
		buf = binary.AppendUvarint(buf, uint64(len(run.Text)))
		h.Write(buf)
		h.Write([]byte(run.Text))
	}
	return "full:" + hex.EncodeToString(h.Sum(nil))
}
