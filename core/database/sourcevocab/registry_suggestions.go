package sourcevocab

import (
	"maps"

	"github.com/Jake-Robins-Studios/provenencia/core/citationformat"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
)

// suggestedKeys is the suggestion rule (docs/seeded-vocabulary.md § 2.3)
// applied to a type's formats: the type's fields as one list, each once, in the
// order its formats first read them (the full format, then the list and short
// formats' needed chains the full format does not already meet); nothing is
// appended. A format names no level, so neither does the list. Install has
// already refused a format that does not parse, so a form without a template
// reads nothing.
func suggestedKeys(f sourcetypes.Formats) []string {
	templates, _ := f.Parse()
	var order []string
	read := map[string]bool{}
	// The full format's fields, then the ones the list and the short format
	// need outside any group that the full format does not use.
	full := true
	var fullKeys map[string]bool
	for _, form := range []citationformat.Form{citationformat.FormFull, citationformat.FormList, citationformat.FormShort} {
		for _, req := range citationformat.Requirements(templates[form]) {
			if !full && req.Need != citationformat.NeedNeeded {
				continue
			}
			// A chain is met when one option is suggested, so a later form's
			// chain adds nothing when the full format already uses an option.
			met := false
			for _, target := range req.Targets {
				met = met || (!full && fullKeys[target.Field.Key])
			}
			if met {
				continue
			}
			for _, target := range req.Targets {
				key := target.Field.Key
				if key == "" || read[key] {
					continue
				}
				read[key] = true
				order = append(order, key)
			}
		}
		if full {
			full = false
			fullKeys = maps.Clone(read)
		}
	}
	return order
}

// Each type's suggested fields, one list per seeded type with any, in order.
// They follow the type's formats (a test derives them): the fields its formats
// read, each once, in the order the formats first read them; nothing else.
var seedSuggestions = []seedSuggestion{
	{TypeKey: "census", FieldKeys: []string{"creator", "jurisdiction", "schedule", "enumeration_district", "subdistrict", "piece", "folio", "page", "schedule_number", "dwelling_number", "family_number", "line_number", "item", "format", "provider", "url", "accessed_date", "citing"}},
	{TypeKey: "birth_certificate", FieldKeys: []string{"jurisdiction", "creator", "document_number", "item", "volume", "page", "entry_number", "format", "provider", "url", "accessed_date", "repository"}},
	{TypeKey: "marriage_certificate", FieldKeys: []string{"jurisdiction", "creator", "document_number", "item", "volume", "page", "entry_number", "format", "provider", "url", "accessed_date", "repository"}},
	{TypeKey: "death_certificate", FieldKeys: []string{"jurisdiction", "creator", "document_number", "item", "volume", "page", "entry_number", "format", "provider", "url", "accessed_date", "repository"}},
	{TypeKey: "church_register", FieldKeys: []string{"creator", "church_location", "volume", "page", "folio", "entry_number", "item", "format", "provider", "url", "accessed_date", "film_number", "item_number", "repository"}},
	{TypeKey: "record_book", FieldKeys: []string{"jurisdiction", "creator", "book", "page", "entry_number", "item", "format", "provider", "url", "accessed_date", "film_number", "repository"}},
	{TypeKey: "passenger_list", FieldKeys: []string{"page", "line_number", "item", "format", "provider", "url", "accessed_date", "citing", "film_publication", "roll"}},
	{TypeKey: "case_file", FieldKeys: []string{"jurisdiction", "creator", "case_number", "item", "format", "provider", "url", "accessed_date", "repository"}},
	{TypeKey: "manuscript", FieldKeys: []string{"creator", "item", "collection", "call_number", "box", "folder", "format", "provider", "url", "accessed_date", "repository"}},
	{TypeKey: "government_file", FieldKeys: []string{"item", "collection", "record_group", "format", "provider", "url", "accessed_date", "film_publication", "roll", "repository"}},
	{TypeKey: "cemetery_marker", FieldKeys: []string{"creator", "cemetery_location", "item", "section", "lot", "photographer", "accessed_date"}},
	{TypeKey: "family_bible", FieldKeys: []string{"published_in", "publication_place", "publisher", "item", "holder"}},
	{TypeKey: "photograph", FieldKeys: []string{"medium", "photographer", "studio", "holder"}},
	{TypeKey: "private_papers", FieldKeys: []string{"creator", "item", "holder"}},
	{TypeKey: "dna_match_report", FieldKeys: []string{"testing_company", "kit_number", "match_identifier", "item", "holder"}},
	{TypeKey: "gedcom_file", FieldKeys: []string{"creator", "software", "item", "holder"}},
	{TypeKey: "interview", FieldKeys: []string{"interviewee", "interview_place", "interviewer", "item", "holder"}},
	{TypeKey: "oral_testimony", FieldKeys: []string{"interviewee", "interview_place", "interviewer", "item", "holder"}},
	{TypeKey: "correspondence", FieldKeys: []string{"creator", "written_from", "recipient", "holder"}},
	{TypeKey: "book", FieldKeys: []string{"author", "editor", "compiler", "translator", "edition", "volume", "series", "publication_place", "publisher", "page", "format", "provider", "url", "accessed_date"}},
	{TypeKey: "journal_article", FieldKeys: []string{"author", "published_in", "volume", "issue", "page_range", "page"}},
	{TypeKey: "broadcast", FieldKeys: []string{"author", "published_in", "volume", "issue", "page_range", "page"}},
	{TypeKey: "newspaper_item", FieldKeys: []string{"published_in", "publication_place", "page", "column", "format", "provider", "url", "accessed_date"}},
	{TypeKey: "website", FieldKeys: []string{"creator", "format", "site_name", "url", "accessed_date", "item", "citing"}},
	{TypeKey: "statute", FieldKeys: []string{"jurisdiction", "published_in", "volume", "chapter", "section", "page"}},
	{TypeKey: "court_report", FieldKeys: []string{"volume", "published_in", "page", "page_range"}},
}
