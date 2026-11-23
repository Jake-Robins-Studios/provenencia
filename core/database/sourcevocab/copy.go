package sourcevocab

import (
	"database/sql"
	"errors"

	"github.com/Jake-Robins-Studios/provenencia/core/database"
	"github.com/Jake-Robins-Studios/provenencia/core/database/rowchange"
	"github.com/Jake-Robins-Studios/provenencia/core/database/sourcetypes"
)

// sqlCopySuggestions copies one type's join rows to another type, keeping each
// row's sort_order; the new type id and the original id follow it as bind
// arguments.
const sqlCopySuggestions = `INSERT INTO source_type_metadata_fields (source_type_id, field_id, sort_order)
	SELECT ?, field_id, sort_order FROM source_type_metadata_fields
	WHERE source_type_id = ?`

// CopyTypeInput names the type to copy and the parts the copy starts with.
type CopyTypeInput struct {
	TypeID      []byte
	Label       string
	Icon        bool
	Description bool
	Formats     bool
	// Suggestions copies every suggested field, in the original's order.
	Suggestions bool
}

// CopyType creates a user-origin type named in.Label that starts with the
// ticked parts of the type in.TypeID, on tx. A missing original is
// sourcetypes.ErrInvalid; the label's errors are Create's. Formats are copied
// as stored. The suggestion join is not audited, so the one change returned is
// the new type's. The caller records the changes; CopyType never calls
// writes.Run.
func CopyType(tx *database.Tx, in CopyTypeInput) (sourcetypes.Type, []rowchange.Change, error) {
	if tx == nil {
		return sourcetypes.Type{}, nil, ErrInvalid
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
	if in.Suggestions {
		if _, err := tx.Exec(sqlCopySuggestions, created.ID, original.ID); err != nil {
			return sourcetypes.Type{}, nil, err
		}
	}
	return created, changes, nil
}
