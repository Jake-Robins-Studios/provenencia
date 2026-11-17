-- S15-15: a Source type's three citation formats (map § 6.3 "Storage"),
-- fields named by id (docs/citation-formats.md).
ALTER TABLE source_types ADD COLUMN citation_full TEXT;
ALTER TABLE source_types ADD COLUMN citation_short TEXT;
ALTER TABLE source_types ADD COLUMN citation_list TEXT;
