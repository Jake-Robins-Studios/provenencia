package sourcevocab

import (
	"slices"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

// TestSuggestedKeys tests the suggestion rule (docs/seeded-vocabulary.md
// § 2.3) on synthetic formats, not on the seed's entries.
func TestSuggestedKeys(t *testing.T) {
	tests := []struct {
		name    string
		formats sourcetypes.Formats
		want    []string
	}{
		{
			name:    "the full format's fields come in first-read order, optional ones included",
			formats: sourcetypes.Formats{Full: `{meta.b}[, {meta.a}], {meta.c}`},
			want:    []string{"b", "a", "c"},
		},
		{
			name:    "a needed field of the list format the full format lacks is appended",
			formats: sourcetypes.Formats{Full: `{meta.a}`, List: `{meta.a}, {meta.z}`},
			want:    []string{"a", "z"},
		},
		{
			name:    "a needed field of the short format the full format lacks is appended",
			formats: sourcetypes.Formats{Full: `{meta.a}`, Short: `{meta.y}`},
			want:    []string{"a", "y"},
		},
		{
			name:    "a chain the full format already meets adds nothing",
			formats: sourcetypes.Formats{Full: `{meta.a}`, List: `{meta.a|meta.z}`},
			want:    []string{"a"},
		},
		{
			name:    "a field read by two formats appears once",
			formats: sourcetypes.Formats{Full: `{meta.a}`, List: `{meta.z}`, Short: `{meta.z}`},
			want:    []string{"a", "z"},
		},
		{
			name:    "an optional field only in the list or short format adds nothing",
			formats: sourcetypes.Formats{Full: `{meta.a}`, List: `{meta.a}[, {meta.z}]`, Short: `[{meta.y}]`},
			want:    []string{"a"},
		},
		{
			name:    "built-ins name no field",
			formats: sourcetypes.Formats{Full: `{source.title}, {meta.a}[ ({source.date:full})]`, List: `{source.title}`},
			want:    []string{"a"},
		},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			if got := suggestedKeys(tc.formats); !slices.Equal(got, tc.want) {
				t.Fatalf("suggestedKeys = %v, want %v", got, tc.want)
			}
		})
	}
}

// vocabkey names the seeded metadata fields code reads by key; the seed stays
// the source of truth for what exists.
func TestFieldKeysMatchSeed(t *testing.T) {
	seeded := map[string]bool{}
	for _, f := range seedFields {
		seeded[f.Key] = true
	}
	for _, key := range []string{vocabkey.FieldPage} {
		if !seeded[key] {
			t.Errorf("vocabkey field %q is not a seeded metadata field", key)
		}
	}
}
