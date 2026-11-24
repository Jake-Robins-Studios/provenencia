package sourcevocab

// Each type's suggested fields, one list per seeded type with any, in order.
// They follow the type's formats (a test derives them): the fields its formats
// read, each once, in the order the formats first read them; nothing else.
var seedSuggestions = []seedSuggestion{
	{TypeKey: "census", FieldKeys: []string{"creator", "jurisdiction", "schedule", "enumeration_district", "subdistrict", "piece", "folio", "schedule_number", "dwelling_number", "family_number", "line_number", "item", "format", "provider", "url", "accessed_date", "citing"}},
	{TypeKey: "birth_certificate", FieldKeys: []string{"jurisdiction", "creator", "document_number", "item", "volume", "entry_number", "format", "provider", "url", "accessed_date", "repository"}},
	{TypeKey: "marriage_certificate", FieldKeys: []string{"jurisdiction", "creator", "document_number", "item", "volume", "entry_number", "format", "provider", "url", "accessed_date", "repository"}},
	{TypeKey: "death_certificate", FieldKeys: []string{"jurisdiction", "creator", "document_number", "item", "volume", "entry_number", "format", "provider", "url", "accessed_date", "repository"}},
	{TypeKey: "church_register", FieldKeys: []string{"creator", "church_location", "volume", "folio", "entry_number", "item", "format", "provider", "url", "accessed_date", "film_number", "item_number", "repository"}},
	{TypeKey: "record_book", FieldKeys: []string{"jurisdiction", "creator", "book", "entry_number", "item", "format", "provider", "url", "accessed_date", "film_number", "repository"}},
	{TypeKey: "passenger_list", FieldKeys: []string{"line_number", "item", "format", "provider", "url", "accessed_date", "citing", "film_publication", "roll"}},
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
	{TypeKey: "book", FieldKeys: []string{"author", "editor", "compiler", "translator", "edition", "volume", "series", "publication_place", "publisher", "format", "provider", "url", "accessed_date"}},
	{TypeKey: "journal_article", FieldKeys: []string{"author", "published_in", "volume", "issue", "page_range"}},
	{TypeKey: "broadcast", FieldKeys: []string{"author", "published_in", "volume", "issue", "page_range"}},
	{TypeKey: "newspaper_item", FieldKeys: []string{"published_in", "publication_place", "column", "format", "provider", "url", "accessed_date"}},
	{TypeKey: "website", FieldKeys: []string{"creator", "format", "site_name", "url", "accessed_date", "item", "citing"}},
	{TypeKey: "statute", FieldKeys: []string{"jurisdiction", "published_in", "volume", "chapter", "section"}},
	{TypeKey: "court_report", FieldKeys: []string{"volume", "published_in", "page_range"}},
}
