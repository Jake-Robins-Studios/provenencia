package sourcevocab

import (
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
)

// Declarative provenencia seed registry (create-time starter for new catalogs):
// began as the citation vocabulary of the Spike 15 map, section 6.8. The types
// and their formats live here; the fields are in registry_fields.go, and Install derives
// the suggestions from the formats (registry_suggestions.go).

// seedType is one Source type. Formats name fields by key; Install stores them
// by id through sourcetypes.ToStored.
type seedType struct {
	Key, Label, Description, IconKey string
	Formats                          sourcetypes.Formats
}

// seedField is one metadata field. UnknownText is what a citation shows when a
// researcher marks the value unknown ("" for none).
type seedField struct {
	Key, Label, DataType, Description, UnknownText string
}

// copyLayer is the online copy a researcher viewed: "database title," format,
// *provider* (url : accessed date), each part when set. Every format that prints
// a copy uses it.
const copyLayer = `[; ["{meta.database_title}," ]{meta.format}, *{meta.provider}*][ ({meta.url}[ : accessed {meta.accessed_date}])]`

// certificateFormats is the one pattern of the three civil certificates: word
// is the certificate in a note ("birth certificate") and plural opens its list
// entry ("Birth certificates").
func certificateFormats(word, plural string) sourcetypes.Formats {
	return sourcetypes.Formats{
		Full:  `{meta.jurisdiction}, [{meta.creator}, ]` + word + `[ no. {meta.document_number}][ ({source.date:full})][, {meta.item}][, vol. {meta.volume}][, p. {meta.page}][, entry {meta.entry_number}]` + copyLayer + `[; {meta.repository}].`,
		Short: `{meta.jurisdiction}, [{meta.creator}, ]` + word + `[ no. {meta.document_number}][, {meta.item}].`,
		List:  `{meta.jurisdiction}.[ {meta.creator}.] ` + plural + `.[ {meta.repository}.]`,
	}
}

// journalArticleFormats is shared by the journal article and the broadcast
// (there published_in is the programme and publisher the network).
var journalArticleFormats = sourcetypes.Formats{
	Full:  `{meta.author}, "{source.title}," *{meta.published_in}*[ {meta.volume}][, no. {meta.issue}][ ({source.date:full})][: {meta.page_range}][, specifically {meta.page}].`,
	Short: `{meta.author}, "{meta.short_title|source.title}"[, {meta.page}].`,
	List:  `{meta.author_sort|meta.author}. "{source.title}." *{meta.published_in}*[ {meta.volume}][, no. {meta.issue}][ ({source.date:full})][: {meta.page_range}].`,
}

var seedTypes = []seedType{
	{
		Key: "census", Label: "Census",
		Description: "A population, agricultural or other schedule from a government census.",
		IconKey:     "type_census",
		Formats: sourcetypes.Formats{
			Full:  `{source.date:year} [{meta.creator} ]census, {meta.jurisdiction}[, {meta.schedule}][, ED {meta.enumeration_district}][, sub-district {meta.subdistrict}][, piece {meta.piece}][, fol. {meta.folio}][, p. {meta.page}][, schedule {meta.schedule_number}][, dwelling {meta.dwelling_number}][, family {meta.family_number}][, line {meta.line_number}][, {meta.item}]` + copyLayer + `[; citing {meta.citing}].`,
			Short: `{source.date:year} [{meta.creator} ]census, {meta.jurisdiction}[, ED {meta.enumeration_district}][, sub-district {meta.subdistrict}][, fol. {meta.folio}][, p. {meta.page}][, dwell. {meta.dwelling_number}][, fam. {meta.family_number}][, {meta.item}].`,
			List:  `{meta.jurisdiction}. {source.date:year} [{meta.creator} ]census[, {meta.schedule}].`,
		},
	},
	{
		Key: "birth_certificate", Label: "Birth certificate",
		Description: "A civil certificate or register entry of a birth.",
		IconKey:     "type_certificate",
		Formats:     certificateFormats("birth certificate", "Birth certificates"),
	},
	{
		Key: "marriage_certificate", Label: "Marriage certificate",
		Description: "A civil certificate or register entry of a marriage.",
		IconKey:     "type_certificate",
		Formats:     certificateFormats("marriage certificate", "Marriage certificates"),
	},
	{
		Key: "death_certificate", Label: "Death certificate",
		Description: "A civil certificate or register entry of a death.",
		IconKey:     "type_certificate",
		Formats:     certificateFormats("death certificate", "Death certificates"),
	},
	{
		Key: "church_register", Label: "Church register",
		Description: "A parish register, church book or bishop's transcript of baptisms, marriages and burials.",
		IconKey:     "type_scroll",
		Formats: sourcetypes.Formats{
			Full:  `{meta.creator}[ ({meta.church_location})], *{source.title}*[, vol. {meta.volume}][, p. {meta.page}][, fol. {meta.folio}][, no. {meta.entry_number}][, {meta.item}]` + copyLayer + `[; film {meta.film_number}[, item {meta.item_number}]][; {meta.repository}].`,
			Short: `{meta.creator}, *{meta.short_title|source.title}*[, vol. {meta.volume}][, p. {meta.page}][, no. {meta.entry_number}].`,
			List:  `{meta.creator}[ ({meta.church_location})]. *{source.title}*[, {meta.coverage}].[ {meta.repository}.]`,
		},
	},
	{
		Key: "record_book", Label: "Record book",
		Description: "A deed, will, court, marriage or tax book kept by a public office.",
		IconKey:     "type_book",
		Formats: sourcetypes.Formats{
			Full:  `{meta.jurisdiction}, [{meta.creator}, ]{meta.book|source.title}[: {meta.page}][, entry {meta.entry_number}][, {meta.item}]` + copyLayer + `[; film {meta.film_number}][; {meta.repository}].`,
			Short: `{meta.jurisdiction}, {meta.book|source.title}[: {meta.page}].`,
			List:  `{meta.jurisdiction}.[ {meta.creator}.] {source.title}[, {meta.coverage}].[ {meta.repository}.]`,
		},
	},
	{
		Key: "passenger_list", Label: "Passenger list",
		Description: "A ship's manifest or passenger list.",
		IconKey:     "type_document",
		Formats: sourcetypes.Formats{
			Full:  `{source.title}[, p. {meta.page}][, line {meta.line_number}][, {meta.item}]` + copyLayer + `[; citing {meta.citing}][; {meta.film_publication}[, roll {meta.roll}]].`,
			Short: `{meta.short_title|source.title}[, p. {meta.page}][, line {meta.line_number}].`,
			List:  `[{meta.creator}. ]{meta.collection|source.title}.[ {meta.repository}.]`,
		},
	},
	{
		Key: "voters_list", Label: "Voters list",
		Description: "A voters list, poll book or register of electors made for an election or a registration year.",
		IconKey:     "type_document",
		Formats: sourcetypes.Formats{
			Full:  `{meta.jurisdiction}, {meta.election}[, {meta.electoral_district}][, {meta.polling_division}][, vol. {meta.volume}][, p. {meta.page}][, line {meta.line_number}][, no. {meta.entry_number}][, {meta.item}]; {meta.collection|source.title}[, {meta.call_number}][, Record Group {meta.record_group}], {meta.repository}[; film {meta.film_number}]` + copyLayer + `.`,
			Short: `{meta.jurisdiction}, {meta.election}[, {meta.electoral_district}][, {meta.polling_division}][, vol. {meta.volume}][, p. {meta.page}][, line {meta.line_number}][, no. {meta.entry_number}][, {meta.item}].`,
			List:  `{meta.jurisdiction}. {meta.collection|source.title}[, {meta.coverage}].[ {meta.call_number}.][ Record Group {meta.record_group}.] {meta.repository}.`,
		},
	},
	{
		Key: "case_file", Label: "Case file",
		Description: "The loose papers of one court, probate, naturalization or land case.",
		IconKey:     "type_folder_archive",
		Formats: sourcetypes.Formats{
			Full:  `{meta.jurisdiction}, [{meta.creator}, ]{source.title}[ {meta.case_number}][, {meta.item}]` + copyLayer + `[; {meta.repository}].`,
			Short: `{meta.jurisdiction}, {meta.short_title|source.title}[ {meta.case_number}][, {meta.item}].`,
			List:  `{meta.jurisdiction}.[ {meta.creator}.] {meta.collection|source.title}.[ {meta.repository}.]`,
		},
	},
	{
		Key: "manuscript", Label: "Archived manuscript",
		Description: "Letters, diaries, business or institutional records held by an archive.",
		IconKey:     "type_folder_archive",
		Formats: sourcetypes.Formats{
			Full:  `[{meta.creator}, ]{source.title}[ ({source.date:full})][, {meta.item}][; {meta.collection}][, {meta.call_number}][, box {meta.box}][, folder {meta.folder}]` + copyLayer + `; {meta.repository}.`,
			Short: `[{meta.creator}, ]{meta.short_title|source.title}[, {meta.collection}][, box {meta.box}][, folder {meta.folder}].`,
			List:  `{meta.collection|source.title}[, {meta.coverage}].[ {meta.call_number}.] {meta.repository}.`,
		},
	},
	{
		Key: "government_file", Label: "Government file",
		Description: "A military, pension, passport or agency file held by a national archive.",
		IconKey:     "type_folder_archive",
		Formats: sourcetypes.Formats{
			Full:  `{source.title}[ ({source.date:full})][, {meta.item}][; {meta.collection}][; Record Group {meta.record_group}]` + copyLayer + `[; {meta.film_publication}[, roll {meta.roll}]]; {meta.repository}.`,
			Short: `{meta.short_title|source.title}[, {meta.item}].`,
			List:  `{meta.repository}.[ Record Group {meta.record_group}.] {meta.collection|source.title}.`,
		},
	},
	{
		Key: "cemetery_marker", Label: "Grave marker",
		Description: "A headstone or monument.",
		IconKey:     "type_grave",
		Formats: sourcetypes.Formats{
			Full:  `{meta.creator}[ ({meta.cemetery_location})], {meta.item|source.title}[, section {meta.section}][, lot {meta.lot}][; photographed by {meta.photographer}[, {meta.accessed_date}]].`,
			Short: `{meta.creator}[ ({meta.cemetery_location})], {meta.item|source.title}.`,
			List:  `{meta.cemetery_location}. {meta.creator}. Grave markers.`,
		},
	},
	{
		Key: "family_bible", Label: "Family Bible",
		Description: "The family record pages of a Bible.",
		IconKey:     "type_book",
		Formats: sourcetypes.Formats{
			Full:  `{source.title}[, *{meta.published_in}*][ ([{meta.publication_place}: ]{meta.publisher}[, {source.date:year}])][, {meta.item}][; held by {meta.holder}].`,
			Short: `{meta.short_title|source.title}[, {meta.item}].`,
			List:  `{source.title}[, {meta.coverage}].[ *{meta.published_in}*.][ Held by {meta.holder}.]`,
		},
	},
	{
		Key: "photograph", Label: "Photograph",
		Description: "A photograph or portrait.",
		IconKey:     "type_photograph",
		Formats: sourcetypes.Formats{
			Full:  `{source.title}[, {meta.medium}][, {source.date:full}][, {meta.photographer|meta.studio}][; held by {meta.holder}].`,
			Short: `{meta.short_title|source.title}[, {source.date:year}].`,
			List:  `{source.title}.[ {meta.medium}.][ Held by {meta.holder}.]`,
		},
	},
	{
		Key: "private_papers", Label: "Private papers",
		Description: "Letters, diaries, research notes or a compiled family file in private hands.",
		IconKey:     "type_document",
		Formats: sourcetypes.Formats{
			Full:  `[{meta.creator}, ]{source.title}[, {source.date:full}][, {meta.item}][; held by {meta.holder}].`,
			Short: `[{meta.creator}, ]{meta.short_title|source.title}[, {meta.item}].`,
			List:  `[{meta.creator}. ]{source.title}[, {meta.coverage}].[ Held by {meta.holder}.]`,
		},
	},
	{
		Key: "dna_match_report", Label: "DNA match report",
		Description: "A DNA test result or match list.",
		IconKey:     "type_dna",
		Formats: sourcetypes.Formats{
			Full:  `{meta.testing_company}, {source.title}[, kit {meta.kit_number}][, match {meta.match_identifier}][, {meta.item}][, report dated {source.date:full}][; held by {meta.holder}].`,
			Short: `{meta.testing_company}, {meta.short_title|source.title}[, match {meta.match_identifier}].`,
			List:  `{meta.testing_company}. {source.title}.[ Held by {meta.holder}.]`,
		},
	},
	{
		Key: "gedcom_file", Label: "GEDCOM file",
		Description: "A family file exported from genealogy software.",
		IconKey:     "type_gedcom",
		Formats: sourcetypes.Formats{
			Full:  `[{meta.creator}, ]{source.title}[, GEDCOM file exported from {meta.software}][, {source.date:full}][, {meta.item}][; held by {meta.holder}].`,
			Short: `[{meta.creator}, ]{meta.short_title|source.title}[, {meta.item}].`,
			List:  `[{meta.creator}. ]{source.title}.[ Held by {meta.holder}.]`,
		},
	},
	{
		Key: "interview", Label: "Interview",
		Description: "A recorded or published interview.",
		IconKey:     "type_oral_history",
		Formats: sourcetypes.Formats{
			Full:  `{meta.interviewee}[ ({meta.interview_place})], interview by {meta.interviewer}, {source.date:full}[, {meta.item}][; held by {meta.holder}].`,
			Short: `{meta.interviewee}, interview, {source.date:full}.`,
			List:  `{meta.interviewee}. Interview by {meta.interviewer}.[ {meta.interview_place},] {source.date:full}.[ Held by {meta.holder}.]`,
		},
	},
	{
		Key: "oral_testimony", Label: "Oral testimony",
		Description: "Informal family testimony, told to the researcher or someone else.",
		IconKey:     "type_oral_history",
		Formats: sourcetypes.Formats{
			Full:  `{meta.interviewee}[ ({meta.interview_place})][, interview by {meta.interviewer}], {source.date:full}[, {meta.item}][; held by {meta.holder}].`,
			Short: `{meta.interviewee}, oral testimony, {source.date:full}.`,
			List:  `{meta.interviewee}.[ Interview by {meta.interviewer}.][ {meta.interview_place},] {source.date:full}.[ Held by {meta.holder}.]`,
		},
	},
	{
		Key: "correspondence", Label: "Correspondence",
		Description: "A letter or email written to the researcher.",
		IconKey:     "type_email",
		Formats: sourcetypes.Formats{
			Full:  `{meta.creator}[ ({meta.written_from})] to {meta.recipient}, {source.title}, {source.date:full}[; held by {meta.holder}].`,
			Short: `{meta.creator} to {meta.recipient}, {source.date:full}.`,
			List:  `{meta.creator}. Correspondence to {meta.recipient}[, {meta.coverage}].[ Held by {meta.holder}.]`,
		},
	},
	{
		Key: "book", Label: "Book",
		Description: "A book, chapter, CD or film.",
		IconKey:     "type_book",
		Formats: sourcetypes.Formats{
			Full:  `{meta.author}[, ed. {meta.editor}][, comp. {meta.compiler}][, trans. {meta.translator}], *{source.title}*[, {meta.edition} ed.][, vol. {meta.volume}][, {meta.series}][ ([{meta.publication_place}: ]{meta.publisher}[, {source.date:year}])][, {meta.page}]` + copyLayer + `.`,
			Short: `{meta.author}, *{meta.short_title|source.title}*[, {meta.page}].`,
			List:  `{meta.author_sort|meta.author}. *{source.title}*.[ {meta.edition} ed.][ [{meta.publication_place}: ]{meta.publisher}[, {source.date:year}].]`,
		},
	},
	{
		Key: "map", Label: "Map",
		Description: "A printed or hand-drawn map, plat or atlas.",
		IconKey:     "type_map",
		Formats: sourcetypes.Formats{
			Full:  `[{meta.author}, ]*{source.title}*[ ([[{meta.publication_place}: ]{meta.publisher}, ]{source.date:year})][, p. {meta.page}][, {meta.item}]` + copyLayer + `[; citing {meta.citing}][; {meta.repository}].`,
			Short: `[{meta.author}, ]*{meta.short_title|source.title}*[, {meta.item}].`,
			List:  `[{meta.author_sort|meta.author}. ]*{source.title}*.[ [[{meta.publication_place}: ]{meta.publisher}, ]{source.date:year}.][ {meta.repository}.]`,
		},
	},
	{
		Key: "journal_article", Label: "Journal article",
		Description: "An article in a journal, magazine or newsletter.",
		IconKey:     "type_newspaper",
		Formats:     journalArticleFormats,
	},
	{
		Key: "broadcast", Label: "Broadcast",
		Description: "A radio or television programme, or a podcast.",
		IconKey:     "type_oral_history",
		Formats:     journalArticleFormats,
	},
	{
		Key: "newspaper_item", Label: "Newspaper item",
		Description: "An article, notice or obituary in a newspaper.",
		IconKey:     "type_newspaper",
		Formats: sourcetypes.Formats{
			Full:  `"{source.title}," *{meta.published_in}*[ ({meta.publication_place})], {source.date:full}[, p. {meta.page}][, col. {meta.column}]` + copyLayer + `.`,
			Short: `"{meta.short_title|source.title}," *{meta.published_in}*, {source.date:full}.`,
			List:  `*{meta.published_in}*[ ({meta.publication_place})].`,
		},
	},
	{
		Key: "website", Label: "Website or online database",
		Description: "A web page, online database, online tree or memorial site.",
		IconKey:     "type_website",
		Formats: sourcetypes.Formats{
			Full:  `[{meta.creator}, ]"{source.title}," [{meta.format}, ]*{meta.site_name}*[ ({meta.url}[ : accessed {meta.accessed_date}])][, {meta.item}][; citing {meta.citing}].`,
			Short: `"{meta.short_title|source.title}"[, {meta.item}].`,
			List:  `[{meta.creator}. ]"{source.title}." *{meta.site_name}*.[ {meta.url}.]`,
		},
	},
	{
		Key: "statute", Label: "Statute",
		Description: "A statute, session law or code.",
		IconKey:     "type_document",
		Formats: sourcetypes.Formats{
			Full:  `{meta.jurisdiction}, *{meta.published_in}*[ {source.date:year}][, vol. {meta.volume}][, chap. {meta.chapter}][, sec. {meta.section}][, p. {meta.page}].`,
			Short: `{meta.jurisdiction}, *{meta.published_in}*[ {source.date:year}][, chap. {meta.chapter}].`,
			List:  `{meta.jurisdiction}. *{meta.published_in}*[, {source.date:year}].`,
		},
	},
	{
		Key: "court_report", Label: "Court report",
		Description: "A published report of a court case.",
		IconKey:     "type_book",
		Formats: sourcetypes.Formats{
			Full:  `*{source.title}*, [{meta.volume} ]{meta.published_in} {meta.page|meta.page_range}[ ({source.date:year})].`,
			Short: `*{meta.short_title|source.title}*[, {meta.page}].`,
			List:  `*{source.title}*. [{meta.volume} ]{meta.published_in}[ ({source.date:year})].`,
		},
	},
}
