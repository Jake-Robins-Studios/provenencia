-- S15-43: the Source date can be marked unknown or supplied (core/valuemark;
-- map § 6.10). Unknown means no date_value_id.
ALTER TABLE sources ADD COLUMN date_unknown INTEGER NOT NULL DEFAULT 0
	CHECK (date_unknown IN (0, 1) AND (date_unknown = 0 OR date_value_id IS NULL));
ALTER TABLE sources ADD COLUMN date_supplied INTEGER NOT NULL DEFAULT 0
	CHECK (date_supplied IN (0, 1) AND NOT (date_unknown = 1 AND date_supplied = 1)
		AND (date_supplied = 0 OR date_value_id IS NOT NULL));
