-- S15-37: a metadata value can be marked unknown or supplied
-- (core/valuemark), and a field holds what an unknown value prints (map § 6.10).
ALTER TABLE source_metadata ADD COLUMN is_unknown INTEGER NOT NULL DEFAULT 0
	CHECK (is_unknown IN (0, 1) AND (is_unknown = 0 OR value_text IS NULL));
ALTER TABLE source_metadata ADD COLUMN is_supplied INTEGER NOT NULL DEFAULT 0
	CHECK (is_supplied IN (0, 1) AND NOT (is_unknown = 1 AND is_supplied = 1)
		AND (is_supplied = 0 OR value_text IS NOT NULL));
ALTER TABLE artifact_metadata ADD COLUMN is_unknown INTEGER NOT NULL DEFAULT 0
	CHECK (is_unknown IN (0, 1) AND (is_unknown = 0 OR value_text IS NULL));
ALTER TABLE artifact_metadata ADD COLUMN is_supplied INTEGER NOT NULL DEFAULT 0
	CHECK (is_supplied IN (0, 1) AND NOT (is_unknown = 1 AND is_supplied = 1)
		AND (is_supplied = 0 OR value_text IS NOT NULL));
ALTER TABLE evidence_graph_metadata ADD COLUMN is_unknown INTEGER NOT NULL DEFAULT 0
	CHECK (is_unknown IN (0, 1) AND (is_unknown = 0 OR value_text IS NULL));
ALTER TABLE evidence_graph_metadata ADD COLUMN is_supplied INTEGER NOT NULL DEFAULT 0
	CHECK (is_supplied IN (0, 1) AND NOT (is_unknown = 1 AND is_supplied = 1)
		AND (is_supplied = 0 OR value_text IS NOT NULL));
ALTER TABLE source_metadata_fields ADD COLUMN unknown_text TEXT;
