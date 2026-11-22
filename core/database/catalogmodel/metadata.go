package catalogmodel

import (
	"fmt"

	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

// MetadataUp is the owner table's one link that leads toward the Source: the
// level it reaches, and the owner table's column that points at that level's
// owner table.
type MetadataUp struct {
	Level  vocabkey.Level
	Column string // owner table column pointing at Level's owner table
}

// MetadataLevelTables is one metadata level's tables. Every metadata table
// names its field in a field_id column, and every owner table carries a ref
// column; neither varies by level.
type MetadataLevelTables struct {
	Level       vocabkey.Level
	Kind        Kind // the owner table's kind
	OwnerTable  string
	OwnerColumn string // in Values and Layout
	Values      string
	Layout      string
	Up          *MetadataUp // nil for the Source
}

// MetadataTables declares every metadata level once. sourcemetadata builds its
// stores, deleteimpact its field-in-use probes and facet releases, and effects
// its Source scopes from this list, so a new level is one entry here plus its
// tables. The order is vocabkey.MetadataLevels().
var MetadataTables = []MetadataLevelTables{
	{Level: vocabkey.LevelSource, Kind: KindSource, OwnerTable: "sources", OwnerColumn: "source_id",
		Values: "source_metadata", Layout: "source_metadata_layout"},
	{Level: vocabkey.LevelArtifact, Kind: KindArtifact, OwnerTable: "artifacts", OwnerColumn: "artifact_id",
		Values: "artifact_metadata", Layout: "artifact_metadata_layout",
		Up: &MetadataUp{Level: vocabkey.LevelSource, Column: "source_id"}},
	{Level: vocabkey.LevelGraph, Kind: KindEvidenceGraph, OwnerTable: "evidence_graphs", OwnerColumn: "graph_id",
		Values: "evidence_graph_metadata", Layout: "evidence_graph_metadata_layout",
		Up: &MetadataUp{Level: vocabkey.LevelSource, Column: "source_id"}},
}

// SourcePath returns the entries from level up to the Source, both included.
// It errors when level or an up level is not in list, when the chain cycles,
// or when the chain ends at an owner table other than sources.
func SourcePath(list []MetadataLevelTables, level vocabkey.Level) ([]MetadataLevelTables, error) {
	find := func(l vocabkey.Level) (MetadataLevelTables, bool) {
		for _, e := range list {
			if e.Level == l {
				return e, true
			}
		}
		return MetadataLevelTables{}, false
	}
	e, ok := find(level)
	if !ok {
		return nil, fmt.Errorf("catalogmodel: level %s not in the metadata list", level)
	}
	path := []MetadataLevelTables{e}
	for e.Up != nil {
		if len(path) > len(list) {
			return nil, fmt.Errorf("catalogmodel: level %s has an up cycle", level)
		}
		next, ok := find(e.Up.Level)
		if !ok {
			return nil, fmt.Errorf("catalogmodel: level %s goes up to %s, not in the metadata list", e.Level, e.Up.Level)
		}
		path = append(path, next)
		e = next
	}
	if e.OwnerTable != "sources" {
		return nil, fmt.Errorf("catalogmodel: level %s does not reach sources", level)
	}
	return path, nil
}
