package catalogmodel_test

import (
	"fmt"
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
	if !slices.Equal(levels, vocabkey.Levels()) {
		t.Fatalf("levels = %v, want %v", levels, vocabkey.Levels())
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
			for _, u := range e.Ups {
				up, ok := byLevel[u.Level]
				if !ok || !hasFK(e.OwnerTable, u.Column, up.OwnerTable) {
					t.Errorf("no FK %s.%s to the %s owner table", e.OwnerTable, u.Column, u.Level)
				}
			}
		})
	}
	if err := upsOrderErr(catalogmodel.MetadataTables); err != nil {
		t.Errorf("shipped list: %v", err)
	}
	swapped := slices.Clone(catalogmodel.MetadataTables)
	for i, e := range swapped {
		if e.Level == vocabkey.LevelCitation {
			e.Ups = []catalogmodel.MetadataUp{e.Ups[1], e.Ups[0]}
			swapped[i] = e
		}
	}
	if err := upsOrderErr(swapped); err == nil || !strings.Contains(err.Error(), "citation") {
		t.Errorf("ups [artifact, graph] error = %v, want one naming citation", err)
	}
	if err := ancestorsErr(catalogmodel.MetadataTables); err != nil {
		t.Errorf("shipped list: %v", err)
	}
	deep := append(slices.Clone(catalogmodel.MetadataTables), catalogmodel.MetadataLevelTables{
		Level: "deep", OwnerTable: "deeps",
		Ups: []catalogmodel.MetadataUp{{Level: vocabkey.LevelCitation, Column: "citation_id", ToSource: true}},
	})
	if err := ancestorsErr(deep); err == nil || !strings.Contains(err.Error(), "deep") || !strings.Contains(err.Error(), "graph") {
		t.Errorf("a level below the Citation: error = %v, want one naming deep and graph", err)
	}
}

// ancestorsErr checks that every level reachable above an entry through its
// ups, however far, is one of its direct ups or the Source (the end of its
// SourcePath): sourcemetadata finds an owner's ancestors from its up columns
// and its Source alone.
func ancestorsErr(list []catalogmodel.MetadataLevelTables) error {
	byLevel := map[vocabkey.Level]catalogmodel.MetadataLevelTables{}
	for _, e := range list {
		byLevel[e.Level] = e
	}
	for _, e := range list {
		path, err := catalogmodel.SourcePath(list, e.Level)
		if err != nil {
			return err
		}
		source := path[len(path)-1].Level
		direct := map[vocabkey.Level]bool{source: true}
		for _, u := range e.Ups {
			direct[u.Level] = true
		}
		seen := map[vocabkey.Level]bool{}
		stack := []vocabkey.Level{e.Level}
		for len(stack) > 0 {
			l := stack[len(stack)-1]
			stack = stack[:len(stack)-1]
			for _, u := range byLevel[l].Ups {
				if seen[u.Level] {
					continue
				}
				seen[u.Level] = true
				if !direct[u.Level] {
					return fmt.Errorf("level %s: ancestor %s is neither one of its ups nor the Source", e.Level, u.Level)
				}
				stack = append(stack, u.Level)
			}
		}
	}
	return nil
}

// upsOrderErr checks that each entry's ups sit after the entry's own level in
// vocabkey.NearestFirst(), at strictly increasing positions.
func upsOrderErr(list []catalogmodel.MetadataLevelTables) error {
	order := vocabkey.NearestFirst()
	for _, e := range list {
		prev := slices.Index(order, e.Level)
		for _, u := range e.Ups {
			pos := slices.Index(order, u.Level)
			if pos <= prev {
				return fmt.Errorf("level %s: up %s is not nearer the Source than %s in NearestFirst", e.Level, u.Level, order[prev])
			}
			prev = pos
		}
	}
	return nil
}

func TestSourcePath(t *testing.T) {
	shipped := catalogmodel.MetadataTables
	citationWith := func(ups ...catalogmodel.MetadataUp) []catalogmodel.MetadataLevelTables {
		out := slices.Clone(shipped)
		for i, e := range out {
			if e.Level == vocabkey.LevelCitation {
				e.Ups = ups
				out[i] = e
			}
		}
		return out
	}
	toGraph := catalogmodel.MetadataUp{Level: vocabkey.LevelGraph, Column: "graph_id"}
	toArtifact := catalogmodel.MetadataUp{Level: vocabkey.LevelArtifact, Column: "artifact_id"}
	unmarked := citationWith(toGraph, toArtifact)
	bothMarked := citationWith(
		catalogmodel.MetadataUp{Level: vocabkey.LevelGraph, Column: "graph_id", ToSource: true},
		catalogmodel.MetadataUp{Level: vocabkey.LevelArtifact, Column: "artifact_id", ToSource: true})
	missingUp := citationWith(catalogmodel.MetadataUp{Level: "nowhere", Column: "artifact_id", ToSource: true})
	cycle := append(slices.Clone(shipped[:1]),
		catalogmodel.MetadataLevelTables{Level: "a", Ups: []catalogmodel.MetadataUp{{Level: "b", Column: "b_id", ToSource: true}}},
		catalogmodel.MetadataLevelTables{Level: "b", Ups: []catalogmodel.MetadataUp{{Level: "a", Column: "a_id", ToSource: true}}})
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
		{"citation", shipped, vocabkey.LevelCitation, []vocabkey.Level{"citation", "artifact", "source"}, ""},
		{"missing level", shipped, "nowhere", nil, "level nowhere not in the metadata list"},
		{"no up toward the Source", unmarked, vocabkey.LevelCitation, nil, "level citation has no up toward the Source"},
		{"two ups toward the Source", bothMarked, vocabkey.LevelCitation, nil, "level citation marks 2 ups toward the Source"},
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
