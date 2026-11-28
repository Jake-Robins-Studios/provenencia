// Package citationrender renders Citations and Sources through their Source
// type's citation formats, on demand from SQL: a batch of Citations (full and
// short citation, and the inputs the read used) and one form against
// one target with an optional unsaved format. It runs no SQL of its own: it
// reads through the owning packages and answers through
// sourcemetadata.CitationValues, the resolver the metadata boards use too.
package citationrender

import (
	"database/sql"
	"errors"

	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/citations"
	"github.com/Jake-Robins-Studios/provenencia/core/database/graphcache"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
)

const (
	// MaxCitations is the most ids one Render call takes, and the batch RenderAll
	// renders at a time.
	MaxCitations = 2_000
	// MaxBatchBytes is the most text one Render or RenderAll call renders: the
	// sum of the plain text of every full and short citation.
	MaxBatchBytes = 8 << 20
)

// RenderedCitation is one Citation rendered. A Full with no runs means the
// Citation's type has no full format (or it did not parse, or a row it reads is
// missing): the caller shows its own line. Short is empty the same way.
type RenderedCitation struct {
	CitationID []byte
	Full       citationformat.Rendered
	Short      citationformat.Rendered
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
	return render(tx, citationIDs, in, MaxBatchBytes)
}

// RenderAll renders the Citations with the given ids, any number of them, in
// one read transaction: a batch of MaxCitations at a time, in input order, a
// repeated id once, an id with no Citation left out. All the batches share one
// MaxBatchBytes of rendered text; a batch that would pass what is left is left
// out, so the caller's records fall back to their own line. It records in in
// the Evidence graphs and Sources of the Citations it rendered; in must not be
// nil. An id that is not 16 bytes is citations.ErrInvalid. No ids returns nil
// and reads nothing.
func RenderAll(c *database.Catalog, citationIDs [][]byte, in *graphcache.PageInputs) ([]RenderedCitation, error) {
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
	return renderAll(tx, citationIDs, in, MaxCitations, MaxBatchBytes)
}

// renderAll renders the ids a batch at a time, dropping a repeated id (the first
// stays). limit is the bytes of text for the whole call: a batch that render
// refuses as over what is left is left out and spends nothing.
func renderAll(tx *sql.Tx, citationIDs [][]byte, in *graphcache.PageInputs, batch, limit int) ([]RenderedCitation, error) {
	ids := database.UniqueBlobIDs(citationIDs)
	var out []RenderedCitation
	for start := 0; start < len(ids); start += batch {
		got, err := render(tx, ids[start:min(start+batch, len(ids))], in, limit)
		if errors.Is(err, citations.ErrInvalid) {
			continue
		}
		if err != nil {
			return nil, err
		}
		for _, r := range got {
			limit -= size(r.Full) + size(r.Short)
		}
		out = append(out, got...)
	}
	return out, nil
}

// templates are a type's parsed full and short formats; either may be nil.
type templates struct{ full, short *citationformat.Template }

// render renders one batch, citations.ErrInvalid when its text passes limit bytes.
func render(tx *sql.Tx, citationIDs [][]byte, in *graphcache.PageInputs, limit int) ([]RenderedCitation, error) {
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
		total += size(r.Full) + size(r.Short)
		if total > limit {
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
