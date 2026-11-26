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
	cited        *citations.Cited
	source       *sources.Source
	typeLabel    string
	artifactPage int
	values       sourcemetadata.CitationValues
}

// owners lists the records whose metadata the subject reads: a Citation and
// the owners above it (sourcemetadata.OwnersAbove), each only when it has an
// id; a Source alone, its Source.
func (s *subject) owners() []sourcemetadata.Owner {
	var sourceID []byte
	if s.source != nil {
		sourceID = s.source.ID
	}
	if s.cited == nil {
		if sourceID == nil {
			return nil
		}
		return []sourcemetadata.Owner{{Level: vocabkey.LevelSource, ID: sourceID}}
	}
	var out []sourcemetadata.Owner
	if s.cited.ID != nil {
		out = append(out, sourcemetadata.Owner{Level: vocabkey.LevelCitation, ID: s.cited.ID})
	}
	return append(out, sourcemetadata.OwnersAbove(vocabkey.LevelCitation, map[vocabkey.Level][]byte{
		vocabkey.LevelGraph:    s.cited.GraphID,
		vocabkey.LevelArtifact: s.cited.ArtifactID,
	}, sourceID)...)
}

// typeID is the id of the subject's Source type; nil when it has no Source.
func (s *subject) typeID() []byte {
	if s.source == nil {
		return nil
	}
	return s.source.SourceTypeID
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
		subs = append(subs, &subject{cited: &c, artifactPage: locator.ArtifactPage(c.LocatorJSON)})
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

// fillValues sets each subject's values: the stored values of its Source and,
// for a Citation, of its Artifact, graph and itself, the field rows the templates name,
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
	for _, s := range subs {
		owners = append(owners, s.owners()...)
	}
	rows, err := sourcemetadata.ListByOwnersTx(tx, owners)
	if err != nil {
		return err
	}
	byOwner := sourcemetadata.GroupByOwner(rows)

	for _, s := range subs {
		v := sourcemetadata.ValuesOf(byOwner, s.owners(), fields)
		if s.source != nil {
			v.Builtins[citationformat.SourceTitle] = citationformat.Value{Text: s.source.Title}
			v.Builtins[citationformat.SourceType] = citationformat.Value{Text: s.typeLabel}
			v.Builtins[citationformat.SourceDate] = sources.CitationDate(*s.source)
		}
		if c := s.cited; c != nil {
			v.Builtins[citationformat.ArtifactLabel] = citationformat.Value{Text: c.ArtifactLabel}
			v.Builtins[citationformat.GraphName] = citationformat.Value{Text: c.GraphName}
			if s.artifactPage > 0 {
				v.Builtins[citationformat.CitationImage] = citationformat.Value{Text: strconv.Itoa(s.artifactPage)}
			}
			v.Builtins[citationformat.CitationLabel] = citationformat.Value{Text: c.Label}
		}
		s.values = v
	}
	return nil
}
