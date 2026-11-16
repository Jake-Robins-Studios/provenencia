package citationformat_test

import (
	"errors"
	"reflect"
	"testing"

	"github.com/google/uuid"

	"github.com/mendahu/provenencia/core/citationformat"
)

var testID = uuid.MustParse("0192f3a4-0000-7000-8000-000000000001")

func toIDs(f citationformat.FieldRef) (citationformat.FieldRef, error) {
	return citationformat.FieldRef{ID: testID}, nil
}

func TestRewriteFields(t *testing.T) {
	round := "{graph.meta.line_number|source.meta.line_number}"
	tpl := mustParse(t, round, "full")
	ids := map[string]uuid.UUID{}
	toID := func(f citationformat.FieldRef) (citationformat.FieldRef, error) {
		id := uuid.New()
		ids[f.Key] = id
		return citationformat.FieldRef{ID: id}, nil
	}
	stored, err := tpl.RewriteFields(toID)
	if err != nil {
		t.Fatal(err)
	}
	if len(ids) != 1 {
		t.Fatalf("to called for %d fields, want 1", len(ids))
	}
	back := mustParse(t, stored, "full")
	got, err := back.RewriteFields(func(f citationformat.FieldRef) (citationformat.FieldRef, error) {
		for k, id := range ids {
			if id == f.ID {
				return citationformat.FieldRef{Key: k}, nil
			}
		}
		return citationformat.FieldRef{}, errors.New("unknown id")
	})
	if err != nil || got != round {
		t.Fatalf("round trip = %q, %v", got, err)
	}

	got, err = mustParse(t, "{source.meta.url}", "full").RewriteFields(toIDs)
	if want := "{source.meta.#0192f3a4-0000-7000-8000-000000000001}"; err != nil || got != want {
		t.Fatalf("got %q, %v", got, err)
	}

	spaced := `\{ x  [{source.meta.a}] *{source.title}* {graph.meta.a|source.meta.a}  \\`
	got, err = mustParse(t, spaced, "full").RewriteFields(func(f citationformat.FieldRef) (citationformat.FieldRef, error) {
		return citationformat.FieldRef{Key: "bb"}, nil
	})
	if want := `\{ x  [{source.meta.bb}] *{source.title}* {graph.meta.bb|source.meta.bb}  \\`; err != nil || got != want {
		t.Fatalf("got %q, %v", got, err)
	}

	boom := errors.New("boom")
	got, err = mustParse(t, "{source.meta.a}", "full").RewriteFields(func(citationformat.FieldRef) (citationformat.FieldRef, error) {
		return citationformat.FieldRef{}, boom
	})
	if got != "" || !errors.Is(err, boom) {
		t.Fatalf("got %q, %v", got, err)
	}
	for _, bad := range []citationformat.FieldRef{{}, {Key: "a", ID: testID}} {
		got, err = mustParse(t, "{source.meta.a}", "full").RewriteFields(func(citationformat.FieldRef) (citationformat.FieldRef, error) {
			return bad, nil
		})
		if got != "" || !errors.Is(err, citationformat.ErrFieldRef) {
			t.Fatalf("answer %+v: got %q, %v", bad, got, err)
		}
	}
	var nilTpl *citationformat.Template
	if got, err := nilTpl.RewriteFields(toIDs); got != "" || err != nil {
		t.Fatalf("nil template: %q, %v", got, err)
	}
}

func TestFields(t *testing.T) {
	tpl := mustParse(t, "{graph.meta.b|source.meta.a}{source.meta.b}{source.meta.a}{source.title}", "full")
	want := []citationformat.FieldRef{{Key: "b"}, {Key: "a"}}
	if got := tpl.Fields(); !reflect.DeepEqual(got, want) {
		t.Fatalf("Fields = %v", got)
	}
	if got := (citationformat.FieldRef{Key: "x"}).Token(); got != "x" {
		t.Errorf("key token = %q", got)
	}
	id := citationformat.FieldRef{ID: testID}
	if got := id.Token(); got != "#0192f3a4-0000-7000-8000-000000000001" || !id.ByID() {
		t.Errorf("id token = %q", got)
	}
}
