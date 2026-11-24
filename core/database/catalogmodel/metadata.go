package catalogmodel

import (
	"fmt"

	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

// MetadataUp is one link from a level's owner table to the owner table of a
// level above it. ToSource marks the link SourcePath follows toward the
// Source: the type read and the audit scope.
type MetadataUp struct {
	Level    vocabkey.Level
	Column   string // owner table column pointing at Level's owner table
	ToSource bool
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
	Ups         []MetadataUp // the levels directly above, nearest first; none for the Source
}

// SourceUp is the up SourcePath follows, nil when none is marked.
func (e MetadataLevelTables) SourceUp() *MetadataUp {
	for i := range e.Ups {
		if e.Ups[i].ToSource {
			return &e.Ups[i]
		}
	}
	return nil
}

// MetadataTables declares every metadata level once. sourcemetadata builds its
// stores, deleteimpact its field-in-use probes and facet releases, and effects
// its Source scopes from this list, so a new level is one entry here plus its
// tables. The order is vocabkey.Levels().
var MetadataTables = []MetadataLevelTables{
	{Level: vocabkey.LevelSource, Kind: KindSource, OwnerTable: "sources", OwnerColumn: "source_id",
		Values: "source_metadata", Layout: "source_metadata_layout"},
	{Level: vocabkey.LevelArtifact, Kind: KindArtifact, OwnerTable: "artifacts", OwnerColumn: "artifact_id",
		Values: "artifact_metadata", Layout: "artifact_metadata_layout",
		Ups: []MetadataUp{{Level: vocabkey.LevelSource, Column: "source_id", ToSource: true}}},
	{Level: vocabkey.LevelGraph, Kind: KindEvidenceGraph, OwnerTable: "evidence_graphs", OwnerColumn: "graph_id",
		Values: "evidence_graph_metadata", Layout: "evidence_graph_metadata_layout",
		Ups: []MetadataUp{{Level: vocabkey.LevelSource, Column: "source_id", ToSource: true}}},
	{Level: vocabkey.LevelCitation, Kind: KindCitation, OwnerTable: "citations", OwnerColumn: "citation_id",
		Values: "citation_metadata", Layout: "citation_metadata_layout",
		Ups: []MetadataUp{{Level: vocabkey.LevelGraph, Column: "graph_id"}, {Level: vocabkey.LevelArtifact, Column: "artifact_id", ToSource: true}}},
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
	for len(e.Ups) > 0 {
		marked := 0
		for _, u := range e.Ups {
			if u.ToSource {
				marked++
			}
		}
		if marked == 0 {
			return nil, fmt.Errorf("catalogmodel: level %s has no up toward the Source", e.Level)
		}
		if marked > 1 {
			return nil, fmt.Errorf("catalogmodel: level %s marks %d ups toward the Source", e.Level, marked)
		}
		if len(path) > len(list) {
			return nil, fmt.Errorf("catalogmodel: level %s has an up cycle", level)
		}
		up := e.SourceUp()
		next, ok := find(up.Level)
		if !ok {
			return nil, fmt.Errorf("catalogmodel: level %s goes up to %s, not in the metadata list", e.Level, up.Level)
		}
		path = append(path, next)
		e = next
	}
	if e.OwnerTable != "sources" {
		return nil, fmt.Errorf("catalogmodel: level %s does not reach sources", level)
	}
	return path, nil
}
