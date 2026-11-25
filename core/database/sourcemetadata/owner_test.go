package sourcemetadata

import (
	"reflect"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

func TestGroupByOwner(t *testing.T) {
	src := Owner{Level: vocabkey.LevelSource, ID: []byte("same-id")}
	art := Owner{Level: vocabkey.LevelArtifact, ID: []byte("same-id")}
	none := Owner{Level: vocabkey.LevelGraph, ID: []byte("other")}
	rows := []Row{
		{Owner: src, FieldID: []byte("f1"), ValueText: "a"},
		{Owner: src, FieldID: []byte("f2"), ValueText: "b"},
		{Owner: art, FieldID: []byte("f1"), ValueText: "c"},
	}
	g := GroupByOwner(rows)
	if got := g.Of(src); len(got) != 2 || got["f1"].ValueText != "a" || got["f2"].ValueText != "b" {
		t.Errorf("source rows = %v", got)
	}
	if got := g.Of(art); len(got) != 1 || got["f1"].ValueText != "c" {
		t.Errorf("artifact rows = %v", got)
	}
	if got := g.Of(none); got == nil || !reflect.DeepEqual(got, map[string]Row{}) {
		t.Errorf("owner with no rows = %#v, want empty map", got)
	}
}

func TestOwnersAbove(t *testing.T) {
	src := []byte("source-id-123456")
	art := []byte("artifact-id-1234")
	gr := []byte("graph-id-1234567")
	o := func(l vocabkey.Level, id []byte) Owner { return Owner{Level: l, ID: id} }
	tests := []struct {
		name     string
		level    vocabkey.Level
		upIDs    map[vocabkey.Level][]byte
		sourceID []byte
		want     []Owner
	}{
		{"a Citation", vocabkey.LevelCitation, map[vocabkey.Level][]byte{vocabkey.LevelGraph: gr, vocabkey.LevelArtifact: art}, src,
			[]Owner{o(vocabkey.LevelGraph, gr), o(vocabkey.LevelArtifact, art), o(vocabkey.LevelSource, src)}},
		{"a Citation with no graph id", vocabkey.LevelCitation, map[vocabkey.Level][]byte{vocabkey.LevelArtifact: art}, src,
			[]Owner{o(vocabkey.LevelArtifact, art), o(vocabkey.LevelSource, src)}},
		{"an Artifact whose up is the Source", vocabkey.LevelArtifact, map[vocabkey.Level][]byte{vocabkey.LevelSource: src}, src,
			[]Owner{o(vocabkey.LevelSource, src)}},
		{"a Source", vocabkey.LevelSource, nil, src, nil},
		{"a level that keeps no metadata", "page", nil, src, nil},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			if got := OwnersAbove(tc.level, tc.upIDs, tc.sourceID); !reflect.DeepEqual(got, tc.want) {
				t.Fatalf("OwnersAbove = %v, want %v", got, tc.want)
			}
		})
	}
}
