package sourcevocab

import (
	"database/sql"
	"errors"
	"slices"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
	"github.com/Jake-Robins-Studios/provenencia/core/vocabkey"
)

// sqlCopySuggestions copies one type's join rows at some levels to another
// type, keeping each row's sort_order; the new type id, the original id and
// the levels follow it as bind arguments. The `)` is appended after the
// level markers.
const sqlCopySuggestions = `INSERT INTO source_type_metadata_fields (source_type_id, field_id, level, sort_order)
	SELECT ?, field_id, level, sort_order FROM source_type_metadata_fields
	WHERE source_type_id = ? AND level IN (`

// CopyTypeInput names the type to copy and the parts the copy starts with.
type CopyTypeInput struct {
	TypeID      []byte
	Label       string
	Icon        bool
	Description bool
	Formats     bool
	// Levels are the metadata levels whose suggested fields are copied.
	Levels []vocabkey.Level
}

// CopyType creates a user-origin type named in.Label that starts with the
// ticked parts of the type in.TypeID, on tx. Every level must hold metadata
// and appear once (ErrInvalid, before any write); a missing original is
// sourcetypes.ErrInvalid; the label's errors are Create's. Formats are copied
// as stored. The suggestion join is not audited, so the one change returned is
// the new type's. The caller records the changes; CopyType never calls
// writes.Run.
//
// The suggestion copy's IN list is bounded: it is the fixed record levels.
func CopyType(tx *database.Tx, in CopyTypeInput) (sourcetypes.Type, []rowchange.Change, error) {
	if tx == nil {
		return sourcetypes.Type{}, nil, ErrInvalid
	}
	for i, level := range in.Levels {
		if !level.HoldsMetadata() || slices.Contains(in.Levels[:i], level) {
			return sourcetypes.Type{}, nil, ErrInvalid
		}
	}
	original, err := sourcetypes.GetByIDTx(tx.Tx, in.TypeID)
	if errors.Is(err, sql.ErrNoRows) {
		return sourcetypes.Type{}, nil, sourcetypes.ErrInvalid
	}
	if err != nil {
		return sourcetypes.Type{}, nil, err
	}
	create := sourcetypes.CreateInput{Label: in.Label}
	if in.Icon {
		create.IconKey = original.IconKey
	}
	if in.Description {
		create.Description = original.Description
	}
	if in.Formats {
		stored, err := sourcetypes.StoredFormatsTx(tx.Tx, [][]byte{original.ID})
		if err != nil {
			return sourcetypes.Type{}, nil, err
		}
		create.Formats = stored[string(original.ID)]
	}
	created, changes, err := sourcetypes.Create(tx, create)
	if err != nil {
		return sourcetypes.Type{}, nil, err
	}
	if len(in.Levels) > 0 {
		args := []any{created.ID, original.ID}
		for _, level := range in.Levels {
			args = append(args, string(level))
		}
		if _, err := tx.Exec(sqlCopySuggestions+database.SQLInPlaceholders(len(in.Levels))+`)`, args...); err != nil {
			return sourcetypes.Type{}, nil, err
		}
	}
	return created, changes, nil
}
