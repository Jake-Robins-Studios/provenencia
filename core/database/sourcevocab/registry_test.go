package sourcevocab

import (
	"slices"
	"testing"

	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database/metadatafields"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

// unreadFields are the two seeded fields no seeded format reads:
// database_title and record_id (there for researchers' own formats).
var unreadFields = []string{"database_title", "record_id"}

func mustParseForm(t *testing.T, typeKey, text string, form citationformat.Form) *citationformat.Template {
	t.Helper()
	tpl, diags := citationformat.Parse(text, form)
	if len(diags) > 0 {
		t.Fatalf("%s %s: %v", typeKey, form, diags)
	}
	return tpl
}

// derivedSuggestions is the suggestion rule applied to a type's formats: the
// type's fields as one list, each once, in the order its formats first read
// them (the full format, then the list and short formats' needed chains the
// full format does not already meet); nothing is appended. A format names no level, so neither does the
// list.
func derivedSuggestions(t *testing.T, st seedType) []string {
	t.Helper()
	return suggestedKeys(st.Formats)
}

func TestSeedSuggestionsFollowFormats(t *testing.T) {
	types := map[string]seedType{}
	for _, st := range seedTypes {
		types[st.Key] = st
	}
	fields := map[string]bool{}
	for _, f := range seedFields {
		fields[f.Key] = true
	}
	seen := map[string]bool{}
	got := map[string][]string{}
	for _, s := range seedSuggestions {
		id := s.TypeKey
		if seen[id] {
			t.Errorf("%s appears twice", id)
		}
		seen[id] = true
		if _, ok := types[s.TypeKey]; !ok {
			t.Errorf("%s names an unknown type", id)
		}
		if len(s.FieldKeys) == 0 {
			t.Errorf("%s has no field", id)
		}
		for _, key := range s.FieldKeys {
			if !fields[key] {
				t.Errorf("%s names unknown field %s", id, key)
			}
		}
		got[s.TypeKey] = s.FieldKeys
	}
	for _, st := range seedTypes {
		want := derivedSuggestions(t, st)
		if !slices.Equal(got[st.Key], want) {
			t.Errorf("%s suggests %v, its formats give %v in order", st.Key, got[st.Key], want)
		}
	}
	if census := got["census"]; len(census) != 18 || census[0] != "creator" || census[len(census)-1] != "citing" {
		t.Errorf("census suggests %v, want 18 fields, creator first and citing last", census)
	}
}

func TestSeedFieldsAreRead(t *testing.T) {
	keys := map[string]bool{}
	for _, f := range seedFields {
		if keys[f.Key] {
			t.Errorf("field %s is seeded twice", f.Key)
		}
		keys[f.Key] = true
		if f.Label == "" || f.Description == "" {
			t.Errorf("field %s lacks a label or description", f.Key)
		}
		wantType := metadatafields.DataTypeText
		if f.Key == "url" {
			wantType = metadatafields.DataTypeURL
		}
		if f.DataType != wantType {
			t.Errorf("field %s has data type %s, want %s", f.Key, f.DataType, wantType)
		}
		wantUnknown := map[string]string{"publication_place": "n.p.", "publisher": "n.p.", "page": "unpaginated"}[f.Key]
		if f.UnknownText != wantUnknown {
			t.Errorf("field %s has unknown text %q, want %q", f.Key, f.UnknownText, wantUnknown)
		}
	}
	read := map[string]bool{}
	for _, st := range seedTypes {
		for _, form := range citationformat.Forms() {
			tpl := mustParseForm(t, st.Key, st.Formats.Text(form), form)
			for _, f := range tpl.Fields() {
				read[f.Key] = true
			}
		}
	}
	for key := range read {
		if !keys[key] {
			t.Errorf("a seeded format reads %s, which is not seeded", key)
		}
	}
	for _, f := range seedFields {
		if !read[f.Key] && !slices.Contains(unreadFields, f.Key) {
			t.Errorf("field %s is read by no seeded format", f.Key)
		}
		if read[f.Key] && slices.Contains(unreadFields, f.Key) {
			t.Errorf("field %s is in unreadFields but a seeded format reads it", f.Key)
		}
	}
}

func TestSeedTypes(t *testing.T) {
	keys := map[string]bool{}
	for _, st := range seedTypes {
		if keys[st.Key] {
			t.Errorf("type %s is seeded twice", st.Key)
		}
		keys[st.Key] = true
		if st.Label == "" || st.Description == "" {
			t.Errorf("type %s lacks a label or description", st.Key)
		}
		if _, ok := sourcetypes.ValidIconKeys[st.IconKey]; !ok {
			t.Errorf("type %s has unknown icon %q", st.Key, st.IconKey)
		}
		for _, form := range citationformat.Forms() {
			if st.Formats.Text(form) == "" {
				t.Errorf("type %s has no %s format", st.Key, form)
				continue
			}
			tpl := mustParseForm(t, st.Key, st.Formats.Text(form), form)
			if form != citationformat.FormList {
				continue
			}
			for _, req := range citationformat.Requirements(tpl) {
				for _, target := range req.Targets {
					if target.Level != vocabkey.LevelSource {
						t.Errorf("type %s list format reads the %s level", st.Key, target.Level)
					}
				}
			}
		}
	}
}

// TestSeededFormatsNeedOnlySuggestedFields: a field a type's formats read
// outside any group is one a Source of that type must have, so the type page
// has to offer it: at least one option of each such requirement is suggested
// at its level.
func TestSeededFormatsNeedOnlySuggestedFields(t *testing.T) {
	suggested := map[string]bool{}
	for _, s := range seedSuggestions {
		for _, key := range s.FieldKeys {
			suggested[s.TypeKey+"/"+key] = true
		}
	}
	for _, st := range seedTypes {
		var tpls []*citationformat.Template
		for _, form := range citationformat.Forms() {
			tpls = append(tpls, mustParseForm(t, st.Key, st.Formats.Text(form), form))
		}
		for _, req := range citationformat.Requirements(tpls...) {
			if req.Need != citationformat.NeedNeeded {
				continue
			}
			var options []string
			met, hasField := false, false
			for _, target := range req.Targets {
				if target.Field.Key == "" {
					continue
				}
				hasField = true
				id := st.Key + "/" + target.Field.Key
				options = append(options, id)
				met = met || suggested[id]
			}
			if hasField && !met {
				t.Errorf("%s: a format needs one of %v, none suggested", st.Key, options)
			}
		}
	}
}

// TestSeedPlaceFields: each seeded type that names a place suggests the field
// that says what the place is. Only the government records, whose place is
// the area whose office keeps them, use jurisdiction.
func TestSeedPlaceFields(t *testing.T) {
	want := map[string]string{
		"census":               "jurisdiction",
		"birth_certificate":    "jurisdiction",
		"marriage_certificate": "jurisdiction",
		"death_certificate":    "jurisdiction",
		"record_book":          "jurisdiction",
		"case_file":            "jurisdiction",
		"statute":              "jurisdiction",
		"newspaper_item":       "publication_place",
		"church_register":      "church_location",
		"cemetery_marker":      "cemetery_location",
		"interview":            "interview_place",
		"oral_testimony":       "interview_place",
		"correspondence":       "written_from",
	}
	for _, s := range seedSuggestions {
		key, ok := want[s.TypeKey]
		if ok && !slices.Contains(s.FieldKeys, key) {
			t.Errorf("type %s suggests %v, want %s among them", s.TypeKey, s.FieldKeys, key)
		}
		if key != "jurisdiction" && slices.Contains(s.FieldKeys, "jurisdiction") {
			t.Errorf("type %s suggests jurisdiction, which only government records use", s.TypeKey)
		}
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
