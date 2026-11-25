-- S16-71: the create read (audit.Created) seeks a row's one create, so a list of Sources does not
-- walk each Source's whole audit history.

CREATE INDEX audit_changes_created_idx ON audit_changes(entity_id) WHERE action = 'create';
