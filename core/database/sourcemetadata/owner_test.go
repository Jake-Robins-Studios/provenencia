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
