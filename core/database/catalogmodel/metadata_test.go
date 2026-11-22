package catalogmodel_test

import (
	"slices"
	"strings"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database/catalogmodel"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

func tableOf(name string) (catalogmodel.Table, bool) {
	for _, t := range catalogmodel.Tables {
		if t.Name == name {
			return t, true
		}
	}
	return catalogmodel.Table{}, false
}

func hasFK(from, col, to string) bool {
	for _, fk := range catalogmodel.FKs {
		if fk.From == from && fk.Column == col && fk.To == to {
			return true
		}
	}
	return false
}

func TestMetadataTables(t *testing.T) {
	var levels []vocabkey.Level
	for _, e := range catalogmodel.MetadataTables {
		levels = append(levels, e.Level)
	}
	if !slices.Equal(levels, vocabkey.MetadataLevels()) {
		t.Fatalf("levels = %v, want %v", levels, vocabkey.MetadataLevels())
	}
	byLevel := map[vocabkey.Level]catalogmodel.MetadataLevelTables{}
	for _, e := range catalogmodel.MetadataTables {
		byLevel[e.Level] = e
	}
	for _, e := range catalogmodel.MetadataTables {
		t.Run(string(e.Level), func(t *testing.T) {
			owner, ok := tableOf(e.OwnerTable)
			if !ok || owner.Kind != e.Kind {
				t.Errorf("owner table %s: in Tables = %v, kind %q, want %q", e.OwnerTable, ok, owner.Kind, e.Kind)
			}
			for _, name := range []string{e.Values, e.Layout} {
				if _, ok := tableOf(name); !ok {
					t.Errorf("%s not in Tables", name)
				}
				if !hasFK(name, e.OwnerColumn, e.OwnerTable) {
					t.Errorf("no FK %s.%s to %s", name, e.OwnerColumn, e.OwnerTable)
				}
				if !hasFK(name, "field_id", "source_metadata_fields") {
					t.Errorf("no FK %s.field_id to source_metadata_fields", name)
				}
			}
			if e.Up != nil {
				up, ok := byLevel[e.Up.Level]
				if !ok || !hasFK(e.OwnerTable, e.Up.Column, up.OwnerTable) {
					t.Errorf("no FK %s.%s to the %s owner table", e.OwnerTable, e.Up.Column, e.Up.Level)
				}
			}
		})
	}
}

func TestSourcePath(t *testing.T) {
	citation := catalogmodel.MetadataLevelTables{
		Level: vocabkey.LevelCitation, Kind: catalogmodel.KindCitation, OwnerTable: "citations", OwnerColumn: "citation_id",
		Values: "citation_metadata", Layout: "citation_metadata_layout",
		Up: &catalogmodel.MetadataUp{Level: vocabkey.LevelArtifact, Column: "artifact_id"},
	}
	shipped := catalogmodel.MetadataTables
	withCitation := append(slices.Clone(shipped), citation)
	missingUp := append(slices.Clone(shipped), catalogmodel.MetadataLevelTables{
		Level: vocabkey.LevelCitation, Kind: catalogmodel.KindCitation, OwnerTable: "citations", OwnerColumn: "citation_id",
		Values: "x", Layout: "y", Up: &catalogmodel.MetadataUp{Level: "nowhere", Column: "artifact_id"},
	})
	cycle := append(slices.Clone(shipped[:1]),
		catalogmodel.MetadataLevelTables{Level: "a", Up: &catalogmodel.MetadataUp{Level: "b", Column: "b_id"}},
		catalogmodel.MetadataLevelTables{Level: "b", Up: &catalogmodel.MetadataUp{Level: "a", Column: "a_id"}})
	notSources := []catalogmodel.MetadataLevelTables{{Level: "a", OwnerTable: "artifacts"}}

	tests := []struct {
		name    string
		list    []catalogmodel.MetadataLevelTables
		level   vocabkey.Level
		want    []vocabkey.Level
		wantErr string
	}{
		{"source", shipped, vocabkey.LevelSource, []vocabkey.Level{"source"}, ""},
		{"artifact", shipped, vocabkey.LevelArtifact, []vocabkey.Level{"artifact", "source"}, ""},
		{"graph", shipped, vocabkey.LevelGraph, []vocabkey.Level{"graph", "source"}, ""},
		{"citation", withCitation, vocabkey.LevelCitation, []vocabkey.Level{"citation", "artifact", "source"}, ""},
		{"missing level", shipped, vocabkey.LevelCitation, nil, "level citation not in the metadata list"},
		{"missing up level", missingUp, vocabkey.LevelCitation, nil, "level citation goes up to nowhere, not in the metadata list"},
		{"cycle", cycle, "a", nil, "level a has an up cycle"},
		{"root not sources", notSources, "a", nil, "level a does not reach sources"},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			path, err := catalogmodel.SourcePath(tc.list, tc.level)
			if tc.wantErr != "" {
				if err == nil || !strings.Contains(err.Error(), tc.wantErr) {
					t.Fatalf("err = %v, want containing %q", err, tc.wantErr)
				}
				return
			}
			if err != nil {
				t.Fatal(err)
			}
			var got []vocabkey.Level
			for _, e := range path {
				got = append(got, e.Level)
			}
			if !slices.Equal(got, tc.want) {
				t.Fatalf("path = %v, want %v", got, tc.want)
			}
		})
	}
}
