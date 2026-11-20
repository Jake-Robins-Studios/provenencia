package citationrender

import (
	"database/sql"
	"strconv"

	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database/citations"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcemetadata"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sources"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
	"github.com/Jake-Robins-Studios/provenencia/core/locator"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

// subject is what one Citation, or one Source alone, renders from. A Citation
// whose graph, Source or type row is missing has a nil source (or an empty
// typeLabel): it has no format to render.
type subject struct {
	cited     *citations.Cited
	source    *sources.Source
	typeLabel string
	page      locator.PageRef
	values    sourcemetadata.CitationValues
}

// typeID is the id of the subject's Source type; nil when it has no Source.
func (s *subject) typeID() []byte {
	if s.source == nil {
		return nil
	}
	return s.source.SourceTypeID
}

// builtin is the target of the built-in called name at level.
func builtin(level vocabkey.Level, name string) citationformat.Target {
	return citationformat.Target{Level: level, Builtin: name}
}

// loadCitations reads the Citations with the given ids, then their Sources and
// the Sources' types, in a fixed number of queries per 500 ids. It returns one
// subject per Citation found, in input order, a repeated id once. The
// citation's Source is its graph's: a Citation never leaves its graph.
func loadCitations(tx *sql.Tx, ids [][]byte) ([]*subject, error) {
	cited, err := citations.ListCitedTx(tx, ids)
	if err != nil {
		return nil, err
	}
	var subs []*subject
	var sourceIDs [][]byte
	seen := make(map[string]bool, len(cited))
	for _, id := range ids {
		c, ok := cited[string(id)]
		if !ok || seen[string(id)] {
			continue
		}
		seen[string(id)] = true
		subs = append(subs, &subject{cited: &c, page: locator.Page(c.LocatorJSON)})
		if c.SourceID != nil {
			sourceIDs = append(sourceIDs, c.SourceID)
		}
	}
	srcs, err := sources.GetManyTx(tx, sourceIDs)
	if err != nil {
		return nil, err
	}
	for _, s := range subs {
		if src, ok := srcs[string(s.cited.SourceID)]; ok {
			s.source = &src
		}
	}
	return subs, labelTypes(tx, subs)
}

// loadSource reads one Source and its type as a subject with no Citation. A
// Source that is not in the catalog is sources.ErrNotFound.
func loadSource(tx *sql.Tx, id []byte) (*subject, error) {
	srcs, err := sources.GetManyTx(tx, [][]byte{id})
	if err != nil {
		return nil, err
	}
	src, ok := srcs[string(id)]
	if !ok {
		return nil, sources.ErrNotFound
	}
	s := &subject{source: &src}
	return s, labelTypes(tx, []*subject{s})
}

// labelTypes sets each subject's type label from one read of the types.
func labelTypes(tx *sql.Tx, subs []*subject) error {
	var typeIDs [][]byte
	for _, s := range subs {
		if id := s.typeID(); id != nil {
			typeIDs = append(typeIDs, id)
		}
	}
	types, err := sourcetypes.GetManyTx(tx, typeIDs)
	if err != nil {
		return err
	}
	for _, s := range subs {
		s.typeLabel = types[string(s.typeID())].Label
	}
	return nil
}

// ownerKey names one owner of stored values.
type ownerKey struct {
	level vocabkey.Level
	id    string
}

// fillValues sets each subject's values: the stored values of its Source and,
// for a Citation, of its Artifact and graph, the field rows the templates name,
// and the built-ins (D-2). Only the fields the templates name by id are read.
func fillValues(tx *sql.Tx, subs []*subject, templates []*citationformat.Template) error {
	var fieldIDs [][]byte
	for _, t := range templates {
		for _, f := range t.Fields() {
			if f.ByID() {
				fieldIDs = append(fieldIDs, f.ID[:])
			}
		}
	}
	fields, err := metadatafields.MapByIDsTx(tx, fieldIDs)
	if err != nil {
		return err
	}

	var owners []sourcemetadata.Owner
	seen := map[ownerKey]bool{}
	add := func(level vocabkey.Level, id []byte) {
		k := ownerKey{level, string(id)}
		if id == nil || seen[k] {
			return
		}
		seen[k] = true
		owners = append(owners, sourcemetadata.Owner{Level: level, ID: id})
	}
	for _, s := range subs {
		if s.source != nil {
			add(vocabkey.LevelSource, s.source.ID)
		}
		if s.cited != nil {
			add(vocabkey.LevelArtifact, s.cited.ArtifactID)
			add(vocabkey.LevelGraph, s.cited.GraphID)
		}
	}
	rows, err := sourcemetadata.ListByOwnersTx(tx, owners)
	if err != nil {
		return err
	}
	byOwner := map[ownerKey]map[string]sourcemetadata.Row{}
	for _, r := range rows {
		k := ownerKey{r.Owner.Level, string(r.Owner.ID)}
		if byOwner[k] == nil {
			byOwner[k] = map[string]sourcemetadata.Row{}
		}
		byOwner[k][string(r.FieldID)] = r
	}

	for _, s := range subs {
		v := sourcemetadata.CitationValues{
			Rows:     map[vocabkey.Level]map[string]sourcemetadata.Row{},
			Fields:   fields,
			Builtins: map[citationformat.Target]citationformat.Value{},
		}
		if s.source != nil {
			v.Rows[vocabkey.LevelSource] = byOwner[ownerKey{vocabkey.LevelSource, string(s.source.ID)}]
			v.Builtins[builtin(vocabkey.LevelSource, "title")] = citationformat.Value{Text: s.source.Title}
			v.Builtins[builtin(vocabkey.LevelSource, "type")] = citationformat.Value{Text: s.typeLabel}
			v.Builtins[builtin(vocabkey.LevelSource, "date")] = sources.CitationDate(*s.source)
		}
		if c := s.cited; c != nil {
			v.Rows[vocabkey.LevelArtifact] = byOwner[ownerKey{vocabkey.LevelArtifact, string(c.ArtifactID)}]
			v.Rows[vocabkey.LevelGraph] = byOwner[ownerKey{vocabkey.LevelGraph, string(c.GraphID)}]
			v.Builtins[builtin(vocabkey.LevelArtifact, "label")] = citationformat.Value{Text: c.ArtifactLabel}
			v.Builtins[builtin(vocabkey.LevelGraph, "name")] = citationformat.Value{Text: c.GraphName}
			v.Builtins[builtin(vocabkey.LevelCitation, "page")] = citationformat.Value{Text: s.page.Label, Mark: s.page.Mark}
			if s.page.ArtifactPage > 0 {
				v.Builtins[builtin(vocabkey.LevelCitation, "image")] = citationformat.Value{Text: strconv.Itoa(s.page.ArtifactPage)}
			}
			v.Builtins[builtin(vocabkey.LevelCitation, "label")] = citationformat.Value{Text: c.Label}
		}
		s.values = v
	}
	return nil
}
