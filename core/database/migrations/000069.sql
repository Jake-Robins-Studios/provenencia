-- S15-63: a Source type suggests each field once, at no level. The rows are
-- not carried over: a field suggested at two levels would collide on the new
-- key, and merging them is a rule this step does not make. A project made
-- before this step opens with no type suggestions.
-- migrate: foreign_keys off

CREATE TABLE source_type_metadata_fields__new (
	source_type_id BLOB NOT NULL REFERENCES source_types(id) ON DELETE CASCADE,
	field_id       BLOB NOT NULL REFERENCES source_metadata_fields(id) ON DELETE CASCADE,
	sort_order     INTEGER,
	PRIMARY KEY (source_type_id, field_id)
) STRICT;

DROP TABLE source_type_metadata_fields;
ALTER TABLE source_type_metadata_fields__new RENAME TO source_type_metadata_fields;
CREATE INDEX source_type_metadata_fields_field_id_idx ON source_type_metadata_fields(field_id);
