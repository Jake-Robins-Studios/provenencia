// Package rowchange is one row-level mutation: the entity, the action, and the
// old and new field values. audit.Record stores these. effects reads them.
// Neither package imports the other.
package rowchange

const (
	ActionCreate = "create"
	ActionUpdate = "update"
	ActionDelete = "delete"
)

// FieldDiff is one field's previous and resulting value in changes_json.
type FieldDiff struct {
	Old any `json:"old"`
	New any `json:"new"`
}

// Change is one row-level mutation under a revision.
type Change struct {
	EntityType string
	EntityID   []byte
	Action     string
	Fields     map[string]FieldDiff
}

// fullRow is a create change: every key is present with old = nil and new = value.
// Unset columns should be passed as nil so JSON encodes them as null.
func fullRow(fields map[string]any) map[string]FieldDiff {
	out := make(map[string]FieldDiff, len(fields))
	for k, v := range fields {
		out[k] = FieldDiff{Old: nil, New: v}
	}
	return out
}

// deletedRow is a delete change: every key is present with old = value and new = nil.
// Unset columns should be passed as nil so JSON encodes them as null.
func deletedRow(fields map[string]any) map[string]FieldDiff {
	out := make(map[string]FieldDiff, len(fields))
	for k, v := range fields {
		out[k] = FieldDiff{Old: v, New: nil}
	}
	return out
}

// updatedRow is an update change: a key is present only when its value differs
// between old and now (a key missing from one side reads nil), and the keys
// named in fixed are never compared. It is empty when nothing differs.
func updatedRow(old, now map[string]any, fixed ...string) map[string]FieldDiff {
	skip := make(map[string]bool, len(fixed))
	for _, k := range fixed {
		skip[k] = true
	}
	out := map[string]FieldDiff{}
	for _, m := range []map[string]any{old, now} {
		for k := range m {
			if !skip[k] && old[k] != now[k] {
				out[k] = FieldDiff{Old: old[k], New: now[k]}
			}
		}
	}
	return out
}

// Created is the create change of one row: every column, old nil, new the value.
func Created(entity string, id []byte, fields map[string]any) Change {
	return Change{EntityType: entity, EntityID: append([]byte(nil), id...), Action: ActionCreate, Fields: fullRow(fields)}
}

// Updated is the update change from old to now, naming only the columns that
// differ (a key missing from one side reads nil) and never the fixed ones;
// nil when none does.
func Updated(entity string, id []byte, old, now map[string]any, fixed ...string) *Change {
	fields := updatedRow(old, now, fixed...)
	if len(fields) == 0 {
		return nil
	}
	return &Change{EntityType: entity, EntityID: append([]byte(nil), id...), Action: ActionUpdate, Fields: fields}
}

// Deleted is the delete change of one row: every column, old the value, new nil.
func Deleted(entity string, id []byte, fields map[string]any) Change {
	return Change{EntityType: entity, EntityID: append([]byte(nil), id...), Action: ActionDelete, Fields: deletedRow(fields)}
}
