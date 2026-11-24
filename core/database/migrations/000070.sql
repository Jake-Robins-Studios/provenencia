-- S15-54: a Citation holds metadata values and layout, with the same fields,
-- marks and layout as a Source, an Artifact and an Evidence graph.

CREATE TABLE citation_metadata (
	id          BLOB PRIMARY KEY,
	citation_id BLOB NOT NULL REFERENCES citations(id) ON DELETE CASCADE,
	field_id    BLOB NOT NULL REFERENCES source_metadata_fields(id),
	value_text  TEXT,
	is_unknown  INTEGER NOT NULL DEFAULT 0
		CHECK (is_unknown IN (0, 1) AND (is_unknown = 0 OR value_text IS NULL)),
	is_supplied INTEGER NOT NULL DEFAULT 0
		CHECK (is_supplied IN (0, 1) AND NOT (is_unknown = 1 AND is_supplied = 1)
			AND (is_supplied = 0 OR value_text IS NOT NULL)),
	UNIQUE (citation_id, field_id)
) STRICT;

CREATE TABLE citation_metadata_layout (
	citation_id BLOB NOT NULL REFERENCES citations(id) ON DELETE CASCADE,
	field_id    BLOB NOT NULL REFERENCES source_metadata_fields(id) ON DELETE CASCADE,
	sort_order  INTEGER NOT NULL,
	dismissed   INTEGER NOT NULL DEFAULT 0 CHECK (dismissed IN (0, 1)),
	PRIMARY KEY (citation_id, field_id)
) STRICT;

CREATE INDEX citation_metadata_field_id_idx ON citation_metadata(field_id);
CREATE INDEX citation_metadata_layout_field_id_idx ON citation_metadata_layout(field_id);
